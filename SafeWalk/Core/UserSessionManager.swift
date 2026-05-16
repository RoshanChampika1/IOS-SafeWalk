import Combine
import FirebaseAuth
import Foundation
import LocalAuthentication

class UserSessionManager: ObservableObject {

    @Published var isWalking: Bool = false
    @Published var isSafe: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUserID: String = ""
    @Published var userName: String = ""
    @Published var userPhoneNumber: String = ""   // ← the bridge for guardian lookup
    @Published var userEmail: String = ""
    @Published var profileImageData: Data?
    @Published var userPhone: String = ""
    @Published var phoneVerified: Bool = false
    /// Becomes true after login if the user has not yet verified a phone number
    /// and has not explicitly skipped. Drives the PhoneVerificationView gate.
    @Published var needsPhoneVerification: Bool = false

    @Published var sosTriggered: Bool = false
    @Published var guardianAccepted: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private func userScopedKey(_ base: String, userID: String) -> String {
        "\(base)_\(userID)"
    }

    init() {
        // Detect fresh install to clear lingering Keychain auth data
        if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
            try? Auth.auth().signOut()
            UserDefaults.standard.set(true, forKey: "hasRunBefore")
        }

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingDone")
        self.userName        = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.userEmail       = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        self.userPhoneNumber = UserDefaults.standard.string(forKey: "userPhone") ?? ""
        self.profileImageData = UserDefaults.standard.data(forKey: "profileImageData")
        setupFirebaseAuthListener()
    }

    // MARK: - Firebase Auth Listener

    private func setupFirebaseAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                guard let self else { return }
                if let user = user {
                    self.applyUser(user)
                } else {
                    self.currentUserID          = ""
                    self.hasCompletedOnboarding = false
                }
            }
        }
    }

    // MARK: - Explicit auth refresh
    // Call this directly from sign-in completions for immediate navigation.
    // The async listener can be slow; this fires instantly.
    func manuallyRefreshAuthState() {
        guard let user = Auth.auth().currentUser else { return }
        DispatchQueue.main.async { self.applyUser(user) }
    }

    private func applyUser(_ user: FirebaseAuth.User) {
        currentUserID = user.uid
        let scopedNameKey = userScopedKey("userName", userID: user.uid)
        let scopedPhoneKey = userScopedKey("userPhone", userID: user.uid)

        let persistedName = UserDefaults.standard.string(forKey: scopedNameKey) ?? ""
        let persistedPhone = UserDefaults.standard.string(forKey: scopedPhoneKey) ?? ""

        let authName = (user.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = !authName.isEmpty ? authName : persistedName
        // user.phoneNumber is nil for email/Google fallback accounts.
        // Prefer the Firebase auth phone; otherwise keep what we persisted (e.g. set by debug login).
        let authPhone = (user.phoneNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPhone = !authPhone.isEmpty ? authPhone : persistedPhone
        let resolvedEmail = user.email ?? userEmail

        userName = resolvedName
        userPhoneNumber = resolvedPhone
        userEmail = resolvedEmail

        if let photoURL = user.photoURL, profileImageData == nil {
            URLSession.shared.dataTask(with: photoURL) { [weak self] data, _, _ in
                guard let data = data, let self = self else { return }
                DispatchQueue.main.async {
                    self.profileImageData = data
                    UserDefaults.standard.set(data, forKey: "profileImageData")
                }
            }.resume()
        }

        UserDefaults.standard.set(resolvedName, forKey: scopedNameKey)
        if !resolvedPhone.isEmpty {
            UserDefaults.standard.set(resolvedPhone, forKey: scopedPhoneKey)
            UserDefaults.standard.set(resolvedPhone, forKey: "userPhone")
        }
        UserDefaults.standard.set(resolvedName, forKey: "userName")
        UserDefaults.standard.set(resolvedEmail, forKey: "userEmail")

        hasCompletedOnboarding = !resolvedName.isEmpty && isValidPhone(resolvedPhone)
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: userScopedKey("onboardingDone", userID: user.uid))

        // Only sync phone to Firestore when we actually have a real number
        // (avoids writing bare country codes like "+94" into Firestore)
        if isValidPhone(resolvedPhone) {
            print("[Auth] ✅ Syncing profile uid=\(user.uid) phone=\(resolvedPhone)")
            FirebaseManager.shared.syncUserProfile(
                userID: user.uid,
                name: resolvedName,
                phone: resolvedPhone,
                email: resolvedEmail
            )
        } else {
            print("[Auth] ⚠️ Phone not yet known for uid=\(user.uid), skipping Firestore sync")
        }

        FirebaseManager.shared.fetchUserProfile(userID: user.uid) { [weak self] profile in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let profile else { return }
                let cloudName = (profile["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let cloudPhone = profile["phone"] as? String ?? ""
                if !cloudName.isEmpty {
                    self.userName = cloudName
                    UserDefaults.standard.set(cloudName, forKey: scopedNameKey)
                    UserDefaults.standard.set(cloudName, forKey: "userName")
                }
                if !cloudPhone.isEmpty {
                    self.userPhoneNumber = cloudPhone
                    UserDefaults.standard.set(cloudPhone, forKey: scopedPhoneKey)
                    UserDefaults.standard.set(cloudPhone, forKey: "userPhone")
                }
                self.hasCompletedOnboarding = !self.userName.isEmpty && self.isValidPhone(self.userPhoneNumber)
                UserDefaults.standard.set(self.hasCompletedOnboarding, forKey: self.userScopedKey("onboardingDone", userID: user.uid))
            }
        }
    }

    /// A phone is considered valid only when it has a "+" prefix and at least
    /// 7 digits (local number portion), so bare country codes like "+94" are
    /// rejected and the user is sent to onboarding to enter a real number.
    private func isValidPhone(_ phone: String) -> Bool {
        guard phone.hasPrefix("+") else { return false }
        let digits = phone.filter(\.isNumber)
        return digits.count >= 7   // e.g. +94771234567 has 11 digits
    }

    // MARK: - Profile

    func completeOnboarding(name: String, phone: String) {
        self.userName = name
        self.userPhoneNumber = phone
        self.hasCompletedOnboarding = true
        if !currentUserID.isEmpty {
            UserDefaults.standard.set(name, forKey: userScopedKey("userName", userID: currentUserID))
            UserDefaults.standard.set(phone, forKey: userScopedKey("userPhone", userID: currentUserID))
            UserDefaults.standard.set(true, forKey: userScopedKey("onboardingDone", userID: currentUserID))
            UserDefaults.standard.removeObject(forKey: "forcePhoneSetup_\(currentUserID)")
        }
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(phone, forKey: "userPhone")
        UserDefaults.standard.set(true, forKey: "onboardingDone")

        if !currentUserID.isEmpty {
            FirebaseManager.shared.syncUserProfile(
                userID: currentUserID,
                name:   name,
                phone:  phone,
                email:  userEmail
            )
        }
    }

    // MARK: - Phone verification

    /// Called by PhoneVerificationView after OTP is confirmed.
    /// Saves the number both locally (UserDefaults) and to Firestore.
    func saveVerifiedPhone(_ phone: String) {
        userPhone = phone
        phoneVerified = true
        needsPhoneVerification = false
        UserDefaults.standard.set(phone, forKey: "userPhone")
        UserDefaults.standard.set(true, forKey: "phoneVerified")
        FirebaseManager.shared.saveVerifiedPhone(userID: currentUserID, phone: phone)
    }

    /// Called when user taps "Skip for now" — hides the gate for this session.
    /// phoneVerified stays false so the gate re-appears on next login.
    func skipPhoneVerification() {
        needsPhoneVerification = false
    }

    func updateProfile(name: String, email: String, imageData: Data?) {
        userName  = name
        userEmail = email
        profileImageData = imageData
        UserDefaults.standard.set(name,  forKey: "userName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        if let imageData {
            UserDefaults.standard.set(imageData, forKey: "profileImageData")
        } else {
            UserDefaults.standard.removeObject(forKey: "profileImageData")
        }

        if !currentUserID.isEmpty {
            FirebaseManager.shared.syncUserProfile(
                userID: currentUserID,
                name:   name,
                phone:  userPhoneNumber,
                email:  email
            )
        }
    }

    // MARK: - Walk

    func startWalk() {
        isWalking   = true
        isSafe      = false
        sosTriggered = false
    }

    func endWalk() {
        isWalking        = false
        isSafe           = true
        sosTriggered     = false
        guardianAccepted = false
    }

    func triggerSOS() {
        sosTriggered = true
    }

    // MARK: - Biometric / Passcode Auth

    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        let reason = "Confirm it's you to disarm your safety timer."
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()

        // Clear ALL persisted user data
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userPhone")
        UserDefaults.standard.removeObject(forKey: "profileImageData")
        UserDefaults.standard.removeObject(forKey: "onboardingDone")  // ← clear so next user starts fresh

        currentUserID          = ""
        userName               = ""
        userEmail              = ""
        userPhoneNumber        = ""
        profileImageData       = nil
        hasCompletedOnboarding = false
        isWalking              = false
        isSafe                 = true
        sosTriggered           = false
        guardianAccepted       = false
    }

    func changeUser() { signOut() }
}

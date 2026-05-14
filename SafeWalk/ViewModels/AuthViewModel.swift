import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Foundation
import UIKit

class AuthViewModel: ObservableObject {
    // Email auth
    @Published var email = ""
    @Published var password = ""

    // Phone auth
    @Published var phoneNumber = ""
    @Published var verificationCode = ""

    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isPhoneVerificationPending = false

    // Called after ANY successful sign-in so LoginView can immediately navigate
    var onSignInSuccess: (() -> Void)?

    private var verificationID: String?
    private var pendingPhoneE164: String = ""

    #if DEBUG
    private let devOTPCode = "123456"
    private let devFallbackVerificationID = "DEV_FALLBACK_OTP"
    #endif

    // MARK: - Phone Auth

    func sendOTP() {
        var normalised = phoneNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet(charactersIn: " -()"))
            .joined()

        // App UI and test data are currently based on Sri Lanka numbers.
        // If user enters local format (e.g. 0771234567 or 771234567), convert to E.164.
        if !normalised.hasPrefix("+"), normalised.allSatisfy(\.isNumber) {
            if normalised.hasPrefix("0") {
                normalised.removeFirst()
            }
            normalised = "+94" + normalised
        }

        guard !normalised.isEmpty, normalised.hasPrefix("+") else {
            errorMessage = "Please enter a valid phone number in international format (e.g. +94771234567)."
            return
        }
        pendingPhoneE164 = normalised
        isLoading = true
        errorMessage = nil

        #if DEBUG
        // Allows Firebase test phone numbers to work without APNs during development.
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        #endif

        // Get the top-most view controller to present reCAPTCHA if APNs isn't available.
        // Passing nil here causes Firebase to fail on devices without APNs configured.
        let presenter = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController

        PhoneAuthProvider.provider().verifyPhoneNumber(normalised, uiDelegate: presenter as? AuthUIDelegate) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    #if DEBUG
                    // Dev fallback path: continue with hardcoded OTP when phone auth infra is unavailable.
                    self?.verificationID = self?.devFallbackVerificationID
                    self?.isPhoneVerificationPending = true
                    self?.errorMessage = "Phone verification service unavailable. Dev OTP enabled. Use 123456."
                    print("SafeWalk: Firebase phone verification failed. Falling back to DEBUG OTP. Error: \(error.localizedDescription)")
                    #else
                    self?.errorMessage = error.localizedDescription
                    #endif
                    return
                }
                self?.verificationID = verificationID
                self?.isPhoneVerificationPending = true
            }
        }
    }

    func verifyOTP(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let verificationID = verificationID, !verificationCode.isEmpty else {
            errorMessage = "Please enter the 6-digit code sent to your phone."
            return
        }

        #if DEBUG
        if verificationID == devFallbackVerificationID {
            guard verificationCode == devOTPCode else {
                errorMessage = "Invalid code. Use 123456 in DEBUG fallback mode."
                completion(false)
                return
            }
            isLoading = true
            errorMessage = nil
            signInWithDebugFallbackAccount(completion: completion)
            return
        }
        #endif

        isLoading = true
        errorMessage = nil

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                self?.onSignInSuccess?()
                completion(true)
            }
        }
    }

    #if DEBUG
    private func signInWithDebugFallbackAccount(completion: @escaping (Bool) -> Void) {
        let digits = pendingPhoneE164.filter(\.isNumber)
        let fallbackEmail = "dev+\(digits)@safewalk.local"
        let fallbackPassword = "SafeWalkDev!123"

        func finishSuccess() {
            // Save phone to the scoped key immediately so applyUser can pick it up
            if let user = Auth.auth().currentUser {
                let scopedPhoneKey = "userPhone_\(user.uid)"
                UserDefaults.standard.set(pendingPhoneE164, forKey: scopedPhoneKey)
                UserDefaults.standard.set(pendingPhoneE164, forKey: "userPhone")
                // Get the already-persisted name for this uid
                let scopedNameKey = "userName_\(user.uid)"
                let name = UserDefaults.standard.string(forKey: scopedNameKey)
                    ?? UserDefaults.standard.string(forKey: "userName")
                    ?? ""
                print("[Auth] 📱 DEBUG fallback — syncing phone \(pendingPhoneE164) for uid \(user.uid)")
                FirebaseManager.shared.syncUserProfile(
                    userID: user.uid,
                    name: name,
                    phone: pendingPhoneE164,
                    email: user.email ?? ""
                )
            }
            isPhoneVerificationPending = false
            verificationCode = ""
            verificationID = nil
            isLoading = false
            onSignInSuccess?()
            completion(true)
        }

        Auth.auth().signIn(withEmail: fallbackEmail, password: fallbackPassword) { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else {
                    completion(false)
                    return
                }
                if error == nil {
                    finishSuccess()
                    return
                }
                Auth.auth().createUser(withEmail: fallbackEmail, password: fallbackPassword) { _, createError in
                    DispatchQueue.main.async {
                        if let createError {
                            self.isLoading = false
                            self.errorMessage = createError.localizedDescription
                            completion(false)
                            return
                        }
                        finishSuccess()
                    }
                }
            }
        }
    }
    #endif

    // MARK: - Email / Password Auth

    func signInWithEmail() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: trimmedEmail, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                // Explicit navigation trigger
                self?.onSignInSuccess?()
            }
        }
    }

    func signUpWithEmail() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, password.count >= 6 else {
            errorMessage = "Enter a valid email and a password of at least 6 characters."
            return
        }
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: trimmedEmail, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                if let uid = result?.user.uid {
                    UserDefaults.standard.set(true, forKey: "forcePhoneSetup_\(uid)")
                }
                // Explicit navigation trigger
                self?.onSignInSuccess?()
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Phone helpers

    func resendOTP() {
        isPhoneVerificationPending = false
        verificationCode = ""
        verificationID = nil
        sendOTP()
    }

    // MARK: - Google Sign-In

    @MainActor
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }

        // Try to get clientID from Firebase options; if not present,
        // GIDSignIn will use the REVERSED_CLIENT_ID URL scheme registered in Xcode.
        let clientID = FirebaseApp.app()?.options.clientID

        isLoading = true
        errorMessage = nil

        if let clientID = clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    // Ignore "user cancelled" silently
                    let code = (error as NSError).code
                    if code != GIDSignInError.canceled.rawValue {
                        self?.errorMessage = error.localizedDescription
                    }
                }
                return
            }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            Auth.auth().signIn(with: credential) { _, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        self?.errorMessage = authError.localizedDescription
                        return
                    }
                    // Explicit navigation trigger
                    self?.onSignInSuccess?()
                }
            }
        }
    }
}

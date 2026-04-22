import Combine
import Foundation
import LocalAuthentication
// import FirebaseAuth

class UserSessionManager: ObservableObject {

    @Published var isWalking: Bool = false
    @Published var isSafe: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUserID: String = UUID().uuidString
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var profileImageData: Data?

    @Published var sosTriggered: Bool = false
    @Published var guardianAccepted: Bool = false

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingDone")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        self.profileImageData = UserDefaults.standard.data(forKey: "profileImageData")
        self.currentUserID = UserDefaults.standard.string(forKey: "userID") ?? {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "userID")
            return id
        }()
        
        setupFirebaseAuthListener()
    }
    
    private func setupFirebaseAuthListener() {
        /* Uncomment when FirebaseAuth is added
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let user = user {
                    self.currentUserID = user.uid
                    self.userEmail = user.email ?? self.userEmail
                    self.userName = user.displayName ?? self.userName
                    self.hasCompletedOnboarding = true
                    FirebaseManager.shared.syncUserProfile(userID: user.uid, name: self.userName, email: self.userEmail)
                }
            }
        }
        */
    }

    func completeOnboarding(name: String) {
        self.userName = name
        self.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboardingDone")
        UserDefaults.standard.set(name, forKey: "userName")
    }

    func updateProfile(name: String, email: String, imageData: Data?) {
        userName = name
        userEmail = email
        profileImageData = imageData
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        if let imageData {
            UserDefaults.standard.set(imageData, forKey: "profileImageData")
        } else {
            UserDefaults.standard.removeObject(forKey: "profileImageData")
        }
        
        // Push user details to Firebase
        FirebaseManager.shared.syncUserProfile(userID: currentUserID, name: name, email: email)
    }

    func startWalk() {
        isWalking = true
        isSafe = false
        sosTriggered = false
    }

    func endWalk() {
        isWalking = false
        isSafe = true
        sosTriggered = false
        guardianAccepted = false
    }

    /// Face ID / Touch ID when available, otherwise device passcode — same system sheet as iOS Settings.
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        let reason = "Confirm it’s you to disarm your safety timer."
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func triggerSOS() {
        sosTriggered = true
    }

    func changeUser() {
        UserDefaults.standard.removeObject(forKey: "onboardingDone")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "profileImageData")
        UserDefaults.standard.removeObject(forKey: "userID")
        
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "userID")
        
        self.userName = ""
        self.userEmail = ""
        self.profileImageData = nil
        self.currentUserID = newID
        self.hasCompletedOnboarding = false
        self.isWalking = false
        self.isSafe = true
        self.sosTriggered = false
        self.guardianAccepted = false
    }
}

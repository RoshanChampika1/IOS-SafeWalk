import Foundation
import Combine
import LocalAuthentication

class UserSessionManager: ObservableObject {
    
    // MARK: - Walk State
    @Published var isWalking: Bool = false
    @Published var isSafe: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUserID: String = UUID().uuidString
    @Published var userName: String = ""
    
    // MARK: - SOS State
    @Published var sosTriggered: Bool = false
    @Published var guardianAccepted: Bool = false
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingDone")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.currentUserID = UserDefaults.standard.string(forKey: "userID") ?? {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "userID")
            return id
        }()
    }
    
    func completeOnboarding(name: String) {
        self.userName = name
        self.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboardingDone")
        UserDefaults.standard.set(name, forKey: "userName")
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
    
    // MARK: - Biometric Disarm
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: "Confirm you are safe") { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: "Use Face ID / Touch ID to confirm you are safe") { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func triggerSOS() {
        sosTriggered = true
    }
}

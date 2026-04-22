import Combine
// Note: You MUST add FirebaseAuth and GoogleSignIn via Xcode Swift Package Manager for this to compile.
// Uncomment these imports when you have added the packages.
// import FirebaseAuth
// import GoogleSignIn

import Foundation
import UIKit

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isPhoneVerificationPending = false
    
    private var verificationID: String?
    
    // MARK: - Email / Password Auth
    func signInWithEmail() {
        /* Uncomment when FirebaseAuth is added
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
        */
    }
    
    func signUpWithEmail() {
        /* Uncomment when FirebaseAuth is added
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
        */
    }
    
    // MARK: - Phone Auth
    func sendOTP() {
        /* Uncomment when FirebaseAuth is added
        guard !phoneNumber.isEmpty else {
            self.errorMessage = "Please enter a valid phone number with country code (e.g., +1...)"
            return
        }
        isLoading = true
        errorMessage = nil
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.verificationID = verificationID
                self?.isPhoneVerificationPending = true
            }
        }
        */
        // STUB logic until packages are added
        self.isPhoneVerificationPending = true
    }
    
    func verifyOTP() {
        /* Uncomment when FirebaseAuth is added
        guard let verificationID = verificationID, !verificationCode.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
        */
    }
    
    // MARK: - Google Sign-In
    @MainActor
    func signInWithGoogle() {
        /* Uncomment when GoogleSignIn & FirebaseAuth are added
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
              
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            self?.isLoading = true
            Auth.auth().signIn(with: credential) { _, authError in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let authError = authError {
                        self?.errorMessage = authError.localizedDescription
                    }
                }
            }
        }
        */
    }
}

import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Foundation
import UIKit

class AuthViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var didSignUpSuccessfully = false

    // MARK: - Email / Password Sign In
    func signInWithEmail() {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
                // On success, UserSessionManager's auth listener will set hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - Email / Password Sign Up
    func signUpWithEmail() {
        guard !name.isEmpty else {
            self.errorMessage = "Please enter your full name."
            return
        }
        guard !email.isEmpty else {
            self.errorMessage = "Please enter your email address."
            return
        }
        guard password.count >= 6 else {
            self.errorMessage = "Password must be at least 6 characters."
            return
        }
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "An unknown error occurred. Please try again."
                }
                return
            }

            // Set the display name on the Firebase Auth profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = self.name
            changeRequest.commitChanges { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        // Non-fatal: user was created but display name failed
                        print("SafeWalk: Could not set display name: \(error.localizedDescription)")
                    }
                    // Save user profile to Firestore
                    FirebaseManager.shared.syncUserProfile(
                        userID: user.uid,
                        name: self.name,
                        email: user.email ?? ""
                    )
                    // Signal success — SignUpView will dismiss
                    self.didSignUpSuccessfully = true
                }
            }
        }
    }

    // MARK: - Google Sign-In
    @MainActor
    func signInWithGoogle() {
        // Make sure Firebase is configured and CLIENT_ID exists
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google Sign-In is not configured. Please download a fresh GoogleService-Info.plist from Firebase Console with Google Sign-In enabled."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            errorMessage = "Could not find a window to present Google Sign-In."
            return
        }

        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Google Sign-In failed: could not retrieve ID token."
                }
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { [weak self] authResult, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        self?.errorMessage = authError.localizedDescription
                    } else if let authResult = authResult {
                        // Save Google profile info to Firestore
                        let googleUser = result?.user
                        FirebaseManager.shared.syncUserProfile(
                            userID: authResult.user.uid,
                            name: googleUser?.profile?.name ?? authResult.user.displayName ?? "",
                            email: authResult.user.email ?? ""
                        )
                    }
                    // UserSessionManager auth listener will flip hasCompletedOnboarding
                }
            }
        }
    }
}

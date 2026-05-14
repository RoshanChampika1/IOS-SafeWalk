import SwiftUI

struct SignUpView: View {
    @StateObject private var authVM = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(SafeWalkTheme.primaryBlue)
                    Text("Create an Account")
                        .font(.title.bold())
                    Text("Sign up to start using SafeWalk.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                if let errorMessage = authVM.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(errorMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(SafeWalkTheme.emergencyRed)
                    .padding()
                    .background(SafeWalkTheme.emergencyRed.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    TextField("Full Name", text: $authVM.name)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(SafeWalkTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Email address", text: $authVM.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(SafeWalkTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password (min 6 characters)", text: $authVM.password)
                        .padding()
                        .background(SafeWalkTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        authVM.signUpWithEmail()
                    } label: {
                        Group {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SafeWalkTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authVM.isLoading)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(SafeWalkTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Sign Up")
        // Auto-dismiss back to login when signup succeeds.
        // The Firebase auth listener in UserSessionManager will then flip
        // hasCompletedOnboarding → true, sending the user to the main app.
        .onChange(of: authVM.didSignUpSuccessfully) { _, success in
            if success { dismiss() }
        }
    }
}

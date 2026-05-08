import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()
    @EnvironmentObject var session: UserSessionManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // SafeWalk Logo / Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
                        Text("Welcome to SafeWalk")
                            .font(.title.bold())
                        Text("Log in to cloud-sync your data.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    if let errorMessage = authVM.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(SafeWalkTheme.emergencyRed)
                            .padding(.horizontal)
                    }
                    
                    emailAuthSection
                    
                    HStack {
                        Rectangle().frame(height: 1).opacity(0.1)
                        Text("OR").font(.caption2.bold()).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).opacity(0.1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                    
                    // Google Login Icon Button
                    Button {
                        authVM.signInWithGoogle()
                    } label: {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    Button("Simulate Local Demo Login") {
                        // REMOVE THIS once native Firebase Auth is configured. 
                        // This allows bypassing the login wall for pure UI testing.
                        session.hasCompletedOnboarding = true
                    }
                    .padding(.top, 20)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
            }
            .background(SafeWalkTheme.background.ignoresSafeArea())
        }
    }
    
    private var emailAuthSection: some View {
        VStack(spacing: 16) {
            TextField("Email address", text: $authVM.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding()
                .background(SafeWalkTheme.cardElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            SecureField("Password", text: $authVM.password)
                .padding()
                .background(SafeWalkTheme.cardElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 16) {
                Button {
                    authVM.signInWithEmail()
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("Log In")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                NavigationLink {
                    SignUpView()
                } label: {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundStyle(SafeWalkTheme.primaryBlue)
                }
            }
            .disabled(authVM.isLoading)
        }
    }
}

import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()
    @EnvironmentObject var session: UserSessionManager
    
    @State private var usePhoneAuth = false
    
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
                        Text("Log in or sign up to cloud-sync your data.")
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
                    
                    if usePhoneAuth {
                        phoneAuthSection
                    } else {
                        emailAuthSection
                    }
                    
                    HStack {
                        Rectangle().frame(height: 1).opacity(0.1)
                        Text("OR").font(.caption2.bold()).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).opacity(0.1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                    
                    VStack(spacing: 16) {
                        Button {
                            usePhoneAuth.toggle()
                        } label: {
                            HStack {
                                Image(systemName: usePhoneAuth ? "envelope.fill" : "phone.fill")
                                Text(usePhoneAuth ? "Continue with Email" : "Continue with Phone")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.cardElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                            .foregroundStyle(SafeWalkTheme.textPrimary)
                        }
                        
                        Button {
                            authVM.signInWithGoogle()
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                        }
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
            
            HStack(spacing: 16) {
                Button {
                    authVM.signInWithEmail()
                } label: {
                    Text("Log In")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SafeWalkTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    authVM.signUpWithEmail()
                } label: {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundStyle(SafeWalkTheme.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SafeWalkTheme.primaryBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .disabled(authVM.isLoading)
        }
    }
    
    private var phoneAuthSection: some View {
        VStack(spacing: 16) {
            if !authVM.isPhoneVerificationPending {
                TextField("Phone (+1234567890)", text: $authVM.phoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(SafeWalkTheme.cardElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    authVM.sendOTP()
                } label: {
                    Text("Send Code")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SafeWalkTheme.callGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                SecureField("Verification Code", text: $authVM.verificationCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(SafeWalkTheme.cardElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    authVM.verifyOTP()
                } label: {
                    Text("Verify & SignIn")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SafeWalkTheme.callGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

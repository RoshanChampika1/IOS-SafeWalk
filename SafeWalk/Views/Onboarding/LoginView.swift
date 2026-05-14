import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()
    @EnvironmentObject var session: UserSessionManager

    @State private var showSignUp: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // MARK: Header
                    VStack(spacing: 10) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
                            .padding(.top, 48)

                        Text("Welcome to SafeWalk")
                            .font(.title.bold())

                        Text("Sign in to connect with your guardians.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // MARK: Error banner
                    if let errorMessage = authVM.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.caption)
                        .foregroundStyle(SafeWalkTheme.emergencyRed)
                        .padding(.horizontal)
                    }

                    // MARK: Email login section
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email address")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField("you@example.com", text: $authVM.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(SafeWalkTheme.cardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            SecureField("Your password", text: $authVM.password)
                                .padding()
                                .background(SafeWalkTheme.cardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            authVM.signInWithEmail()
                        } label: {
                            ZStack {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Log In")
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

                    // MARK: Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                        Text("OR").font(.caption.bold()).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal, 4)

                    // MARK: Google Sign-In button (round icon only)
                    HStack {
                        Spacer()
                        GoogleSignInButton(
                            action: { authVM.signInWithGoogle() },
                            isLoading: authVM.isLoading
                        )
                        Spacer()
                    }

                    HStack(spacing: 6) {
                        Text("If you don't have an account,")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SafeWalkTheme.primaryBlue)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
            .background(SafeWalkTheme.background.ignoresSafeArea())
            .onAppear {
                authVM.onSignInSuccess = {
                    session.manuallyRefreshAuthState()
                }
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView {
                    session.manuallyRefreshAuthState()
                }
            }
        }
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authVM = AuthViewModel()

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var localError: String?

    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let message = localError ?? authVM.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(SafeWalkTheme.emergencyRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Password (min 6)", text: $password)
                        SecureField("Confirm password", text: $confirmPassword)
                    }
                    .padding()
                    .background(SafeWalkTheme.cardElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        localError = nil
                        guard password == confirmPassword else {
                            localError = "Passwords do not match."
                            return
                        }
                        authVM.email = email
                        authVM.password = password
                        authVM.signUpWithEmail()
                    } label: {
                        ZStack {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign Up")
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
                .padding(24)
            }
            .background(SafeWalkTheme.background.ignoresSafeArea())
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                authVM.onSignInSuccess = {
                    onSuccess()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Google Sign-In Button (round, icon only)

struct GoogleSignInButton: View {
    var action: () -> Void
    var isLoading: Bool = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: .black.opacity(isPressed ? 0.06 : 0.15),
                        radius: isPressed ? 2 : 6,
                        y: isPressed ? 1 : 3
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.10), lineWidth: 1)
                    )

                if isLoading {
                    ProgressView()
                        .tint(Color(red: 0.235, green: 0.251, blue: 0.263))
                } else {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }
            }
            .scaleEffect(isPressed ? 0.90 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}


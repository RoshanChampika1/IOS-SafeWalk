import SwiftUI
import FirebaseAuth

struct PhoneVerificationView: View {

    @EnvironmentObject var session: UserSessionManager

    // Step tracking
    @State private var step: Step = .enterPhone

    // Input fields
    @State private var phoneNumber: String = ""
    @State private var otpCode: String = ""

    // Firebase
    @State private var verificationID: String = ""

    // UI state
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Country code prefix (Sri Lanka default; user can edit the full number)
    private let countryCode = "+94"

    enum Step {
        case enterPhone
        case enterOTP
    }

    var body: some View {
        ZStack {
            SafeWalkTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {

                    // MARK: Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SafeWalkTheme.primaryBlue.opacity(0.12))
                                .frame(width: 90, height: 90)
                            Image(systemName: step == .enterPhone ? "phone.badge.checkmark.fill" : "lock.shield.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(SafeWalkTheme.primaryBlue)
                        }
                        .animation(.spring(duration: 0.4), value: step)

                        Text(step == .enterPhone ? "Verify Your Number" : "Enter the Code")
                            .font(.title2.bold())
                            .foregroundStyle(SafeWalkTheme.textPrimary)

                        Text(step == .enterPhone
                             ? "We need your phone number so guardians can find you by number."
                             : "Enter the 6-digit code sent to \(phoneNumber).")
                            .font(.subheadline)
                            .foregroundStyle(SafeWalkTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 48)

                    // MARK: Error banner
                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMessage)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(SafeWalkTheme.emergencyRed)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SafeWalkTheme.emergencyRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }

                    // MARK: Input card
                    VStack(spacing: 20) {
                        if step == .enterPhone {
                            phoneInputSection
                        } else {
                            otpInputSection
                        }
                    }
                    .padding(20)
                    .safeWalkCardStyle()

                    // MARK: Skip link
                    Button("Skip for now") {
                        session.skipPhoneVerification()
                    }
                    .font(.footnote)
                    .foregroundStyle(SafeWalkTheme.textSecondary)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.3), value: step)
                .animation(.easeInOut(duration: 0.2), value: errorMessage)
            }
        }
    }

    // MARK: - Phone input

    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mobile number")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SafeWalkTheme.textSecondary)

            HStack(spacing: 0) {
                // Country code pill
                Text(countryCode)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SafeWalkTheme.primaryBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(SafeWalkTheme.primaryBlue.opacity(0.10))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 10,
                            bottomLeadingRadius: 10,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )

                TextField("771234567", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(SafeWalkTheme.background)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 10,
                            topTrailingRadius: 10
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(SafeWalkTheme.primaryBlue.opacity(0.25), lineWidth: 1)
            )

            Text("Enter your number without the leading 0. Example: 771234567")
                .font(.caption2)
                .foregroundStyle(SafeWalkTheme.textSecondary)

            primaryButton(
                title: "Send OTP",
                systemImage: "arrow.right.circle.fill"
            ) {
                sendOTP()
            }
        }
    }

    // MARK: - OTP input

    private var otpInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Verification code")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SafeWalkTheme.textSecondary)

            TextField("6-digit code", text: $otpCode)
                .keyboardType(.numberPad)
                .font(.title3.monospacedDigit())
                .multilineTextAlignment(.center)
                .padding()
                .background(SafeWalkTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(SafeWalkTheme.primaryBlue.opacity(0.25), lineWidth: 1)
                )

            primaryButton(
                title: "Verify",
                systemImage: "checkmark.shield.fill"
            ) {
                verifyOTP()
            }

            Button("Resend code") {
                step = .enterPhone
                otpCode = ""
                errorMessage = nil
            }
            .font(.footnote)
            .foregroundStyle(SafeWalkTheme.primaryBlue)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Shared button

    @ViewBuilder
    private func primaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isLoading ? SafeWalkTheme.primaryBlue.opacity(0.6) : SafeWalkTheme.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Actions

    private func sendOTP() {
        let digits = phoneNumber.filter(\.isNumber)
        guard digits.count >= 7 else {
            errorMessage = "Please enter a valid phone number."
            return
        }
        let fullNumber = "\(countryCode)\(digits)"
        isLoading = true
        errorMessage = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(fullNumber, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let verificationID = verificationID else {
                    errorMessage = "Could not reach Firebase. Try again."
                    return
                }
                self.verificationID = verificationID
                self.phoneNumber = fullNumber   // store the full E.164 number
                step = .enterOTP
            }
        }
    }

    private func verifyOTP() {
        guard otpCode.count == 6 else {
            errorMessage = "Please enter the 6-digit code."
            return
        }
        isLoading = true
        errorMessage = nil

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: otpCode
        )

        // Link the phone credential to the existing Google/Email account
        // so the user keeps ONE Firebase account with phone added.
        Auth.auth().currentUser?.link(with: credential) { result, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error as NSError? {
                    // If already linked with a different provider, just sign in to get the token
                    // then save the number.
                    if error.code == AuthErrorCode.providerAlreadyLinked.rawValue ||
                       error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                        self.savePhoneDirectly()
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    return
                }

                // Linked successfully – save phone to Firestore
                session.saveVerifiedPhone(phoneNumber)
            }
        }
    }

    /// Fallback: phone already linked, just persist the number in Firestore.
    private func savePhoneDirectly() {
        session.saveVerifiedPhone(phoneNumber)
    }
}

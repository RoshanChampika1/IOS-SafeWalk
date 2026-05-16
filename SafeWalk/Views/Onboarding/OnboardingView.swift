import Combine
import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var step: SetupStep = .phone

    private enum SetupStep {
        case phone
        case name
    }

    var body: some View {
        ZStack {
            SafeWalkTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // ── STEP 1: Phone ────────────────────────────────────────────
                if step == .phone {
                    Image(systemName: "phone.badge.checkmark")
                        .font(.system(size: 64))
                        .foregroundStyle(SafeWalkTheme.primaryBlue)

                    Text("Add your phone number")
                        .font(.title.bold())
                        .foregroundStyle(SafeWalkTheme.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone number")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SafeWalkTheme.textSecondary)
                        TextField("+94 771 234 567", text: $phone)
                            .keyboardType(.phonePad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(SafeWalkTheme.cardElevated)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                    }
                    .padding(.horizontal, 32)

                    Button {
                        let normalisedPhone = normalisePhone(phone)
                        guard isValidPhone(normalisedPhone) else { return }
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Google sign-in provides a name already — skip the name step.
                        if !trimmedName.isEmpty {
                            locationManager.requestPermission()
                            notificationManager.requestPermission()
                            session.completeOnboarding(name: trimmedName, phone: normalisedPhone)
                        } else {
                            step = .name
                        }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                    }
                    .padding(.horizontal, 32)
                    .disabled(!isValidPhone(normalisePhone(phone)))

                // ── STEP 2: Name (only for email/non-Google users) ───────────
                } else {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(SafeWalkTheme.warningOrange)

                    Text("What's your name?")
                        .font(.title.bold())
                        .foregroundStyle(SafeWalkTheme.textPrimary)

                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(SafeWalkTheme.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                        .padding(.horizontal, 32)

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let normalisedPhone = normalisePhone(phone)
                        guard !trimmed.isEmpty, isValidPhone(normalisedPhone) else { return }
                        locationManager.requestPermission()
                        notificationManager.requestPermission()
                        session.completeOnboarding(name: trimmed, phone: normalisedPhone)
                    } label: {
                        Text("Complete Setup")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                    }
                    .padding(.horizontal, 32)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Back") {
                        step = .phone
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SafeWalkTheme.primaryBlue)
                }

                Spacer()
            }
        }
        .onAppear {
            let uid = session.currentUserID
            let scopedName  = uid.isEmpty ? "" : (UserDefaults.standard.string(forKey: "userName_\(uid)") ?? "")
            let scopedPhone = uid.isEmpty ? "" : (UserDefaults.standard.string(forKey: "userPhone_\(uid)") ?? "")
            let forcePhoneSetup = !uid.isEmpty && UserDefaults.standard.bool(forKey: "forcePhoneSetup_\(uid)")

            // Pre-fill name from Google/persisted data, but NEVER auto-fill a phone
            // that is just a bare country code like "+94" — treat that as no phone.
            if name.isEmpty {
                name = scopedName.isEmpty ? session.userName : scopedName
            }

            if forcePhoneSetup {
                // Fresh email sign-up: always start at phone entry.
                phone = ""
                step  = .phone
            } else {
                let normalisedStored = normalisePhone(scopedPhone)
                if isValidPhone(normalisedStored) {
                    // Only accept a stored phone that has a real number (not just "+94").
                    phone = normalisedStored
                    // Both name and phone are valid → this shouldn't reach OnboardingView,
                    // but if it does, send the user through phone entry again.
                    step = .phone
                } else {
                    // No valid phone yet — always start at phone entry.
                    phone = ""
                    step  = .phone
                }
            }
        }
    }

    // MARK: - Helpers

    /// Normalises a raw phone input to E.164 format ("+94XXXXXXXXX").
    private func normalisePhone(_ raw: String) -> String {
        var value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet(charactersIn: " -()"))
            .joined()
        if value.hasPrefix("00") {
            value = "+" + value.dropFirst(2)
        }
        if !value.hasPrefix("+"), value.allSatisfy(\.isNumber) {
            if value.hasPrefix("0") { value.removeFirst() }
            value = "+94" + value
        }
        return value.hasPrefix("+") ? value : ""
    }

    /// A phone is valid only if it has a "+" prefix AND at least 7 digits —
    /// bare country codes like "+94" (2 digits) are rejected.
    private func isValidPhone(_ phone: String) -> Bool {
        guard phone.hasPrefix("+") else { return false }
        return phone.filter(\.isNumber).count >= 7
    }
}

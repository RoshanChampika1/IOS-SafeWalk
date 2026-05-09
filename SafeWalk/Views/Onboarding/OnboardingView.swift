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
                        guard !normalisedPhone.isEmpty else { return }
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Google sign-in usually provides a name already.
                        // If we have it, complete setup right after phone step.
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
                    .disabled(normalisePhone(phone).isEmpty)
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
                        guard !trimmed.isEmpty, !normalisedPhone.isEmpty else { return }
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
            let scopedName = uid.isEmpty ? "" : (UserDefaults.standard.string(forKey: "userName_\(uid)") ?? "")
            let scopedPhone = uid.isEmpty ? "" : (UserDefaults.standard.string(forKey: "userPhone_\(uid)") ?? "")
            let forcePhoneSetup = !uid.isEmpty && UserDefaults.standard.bool(forKey: "forcePhoneSetup_\(uid)")

            if name.isEmpty {
                name = scopedName.isEmpty ? session.userName : scopedName
            }
            if phone.isEmpty {
                // Important: prefer current-user scoped phone so stale old-user values
                // cannot skip the phone step.
                phone = scopedPhone
            }
            if forcePhoneSetup {
                phone = ""
                step = .phone
            } else {
                step = normalisePhone(phone).isEmpty ? .phone : .name
            }
        }
    }

    private func normalisePhone(_ raw: String) -> String {
        var value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet(charactersIn: " -()"))
            .joined()
        if value.hasPrefix("00") {
            value = "+" + value.dropFirst(2)
        }
        if !value.hasPrefix("+"), value.allSatisfy(\.isNumber) {
            if value.hasPrefix("0") {
                value.removeFirst()
            }
            value = "+94" + value
        }
        return value.hasPrefix("+") ? value : ""
    }
}

import SwiftUI

struct DisarmAuthSheet: View {

    @Environment(\.dismiss) private var dismiss

    /// Async device authentication (Face ID / Touch ID / device passcode).
    var disarmDevice: (@escaping (Bool) -> Void) -> Void
    /// Returns true when app passcode matched and timer was disarmed.
    var verifyPasscode: (String) -> Bool

    @State private var passcodeEntry = ""
    @State private var errorText: String?
    @AppStorage("biometricEnabledSetting") private var biometricEnabled: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Disarm timer")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Use Face ID, Touch ID, or your device passcode — or enter the app passcode you set in Profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if biometricEnabled {
                    Button {
                        disarmDevice { success in
                            if success { dismiss() }
                        }
                    } label: {
                        Label("Use Face ID / device passcode", systemImage: "faceid")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                if AppPasscodeStore.hasPasscode {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("App passcode", text: $passcodeEntry)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        if let errorText {
                            Text(errorText)
                                .font(.caption)
                                .foregroundStyle(SafeWalkTheme.emergencyRed)
                        }
                        Button("Unlock with app passcode") {
                            if verifyPasscode(passcodeEntry) {
                                dismiss()
                            } else {
                                errorText = "Passcode doesn’t match."
                                passcodeEntry = ""
                            }
                        }
                        .font(.headline)
                        .disabled(passcodeEntry.count < 4)
                    }
                } else {
                    Text("Optional: set a 4–6 digit app passcode under Profile for a second way to disarm here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {

    @EnvironmentObject var session: UserSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var newPasscode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var passcodeMessage: String?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isCopied: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            profileImageView
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(SafeWalkTheme.primaryBlue.opacity(0.35), lineWidth: 2))

                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Text("Change photo")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SafeWalkTheme.primaryBlue)
                            }
                            .onChange(of: pickerItem) { _, item in
                                Task {
                                    guard let item,
                                          let data = try? await item.loadTransferable(type: Data.self)
                                    else { return }
                                    await MainActor.run {
                                        session.updateProfile(name: name, email: email, imageData: data)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Profile") {
                    TextField("Display name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("App passcode") {
                    SecureField("New 4–6 digit passcode", text: $newPasscode)
                        .keyboardType(.numberPad)
                    SecureField("Confirm passcode", text: $confirmPasscode)
                        .keyboardType(.numberPad)
                    Button("Save app passcode") {
                        savePasscode()
                    }
                    .disabled(newPasscode.count < 4 || newPasscode != confirmPasscode)
                    if let passcodeMessage {
                        Text(passcodeMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Optional extra lock inside SafeWalk (separate from your device passcode).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Account") {
                    LabeledContent("User ID") {
                        HStack(spacing: 8) {
                            Text(session.currentUserID.prefix(12) + "…")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            
                            Button {
                                UIPasteboard.general.string = session.currentUserID
                                withAnimation { isCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { isCopied = false }
                                }
                            } label: {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .foregroundStyle(isCopied ? SafeWalkTheme.callGreen : SafeWalkTheme.primaryBlue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SafeWalkTheme.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        session.updateProfile(name: name, email: email, imageData: session.profileImageData)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = session.userName
                email = session.userEmail
            }
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let data = session.profileImageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                SafeWalkTheme.primaryBlue.opacity(0.15)
                Text(String(name.isEmpty ? session.userName.prefix(1) : name.prefix(1)).uppercased())
                    .font(.largeTitle.bold())
                    .foregroundStyle(SafeWalkTheme.primaryBlue)
            }
        }
    }

    private func savePasscode() {
        guard newPasscode.count >= 4, newPasscode == confirmPasscode else { return }
        UserDefaults.standard.set(newPasscode, forKey: "appPasscode")
        passcodeMessage = "Saved. You can extend the app later to require this before sensitive actions."
        newPasscode = ""
        confirmPasscode = ""
    }
}

import Combine
import PhotosUI
import SwiftUI
import UIKit

struct AddContactView: View {

    @EnvironmentObject var contactsVM: ContactsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var isGuardian: Bool = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImageData: Data?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            contactPhotoPreview
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(SafeWalkTheme.primaryBlue.opacity(0.3), lineWidth: 2))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Contact info") {
                    TextField("Full name", text: $name)
                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Toggle(isOn: $isGuardian) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set as guardian")
                                .font(.headline)
                            Text("Guardians can be called first and used for fake-call previews.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(SafeWalkTheme.primaryBlue)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SafeWalkTheme.background)
            .navigationTitle("Add contact")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: pickerItem) { _, item in
                guard let item else {
                    pickedImageData = nil
                    return
                }
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    await MainActor.run { pickedImageData = data }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        contactsVM.addContact(
                            name: name,
                            phone: phone,
                            email: email,
                            isGuardian: isGuardian,
                            imageData: pickedImageData
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    @ViewBuilder
    private var contactPhotoPreview: some View {
        if let data = pickedImageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle().fill(SafeWalkTheme.primaryBlue.opacity(0.12))
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.largeTitle)
                    .foregroundStyle(SafeWalkTheme.primaryBlue)
            }
        }
    }
}

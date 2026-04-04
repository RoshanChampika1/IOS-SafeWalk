import SwiftUI

struct AddContactView: View {
    
    @EnvironmentObject var contactsVM: ContactsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var isGuardian: Bool = false
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Info") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section {
                    Toggle(isOn: $isGuardian) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set as Guardian")
                                .font(.headline)
                            Text("Guardians can track your live location and receive SOS alerts.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.indigo)
                }
                
                if isGuardian {
                    Section {
                        Label("This person will receive a Guardian Request when you start a walk.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        contactsVM.addContact(name: name, phone: phone, email: email, isGuardian: isGuardian)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

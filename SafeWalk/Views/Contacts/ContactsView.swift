import SwiftUI

struct ContactsView: View {
    
    @EnvironmentObject var contactsVM: ContactsViewModel
    @EnvironmentObject var guardianVM: GuardianViewModel
    @EnvironmentObject var session: UserSessionManager
    
    var body: some View {
        NavigationStack {
            List {
                // Guardians Section
                if !contactsVM.guardians.isEmpty {
                    Section {
                        ForEach(contactsVM.guardians) { contact in
                            ContactRowView(contact: contact)
                                .environmentObject(guardianVM)
                                .environmentObject(session)
                        }
                    } header: {
                        Label("Guardians", systemImage: "shield.lefthalf.filled")
                    }
                }
                
                // Other Contacts
                if !contactsVM.regularContacts.isEmpty {
                    Section {
                        ForEach(contactsVM.regularContacts) { contact in
                            ContactRowView(contact: contact)
                                .environmentObject(guardianVM)
                                .environmentObject(session)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                contactsVM.deleteContact(id: contactsVM.regularContacts[i].id)
                            }
                        }
                    } header: {
                        Label("Emergency Contacts", systemImage: "person.2")
                    }
                }
                
                if contactsVM.contacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts Yet",
                        systemImage: "person.badge.plus",
                        description: Text("Add emergency contacts and guardians to notify when you need help.")
                    )
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        contactsVM.showAddContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $contactsVM.showAddContact) {
                AddContactView()
                    .environmentObject(contactsVM)
            }
        }
    }
}

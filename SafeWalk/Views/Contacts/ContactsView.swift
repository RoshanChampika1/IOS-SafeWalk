import Combine
import SwiftUI

struct ContactsView: View {

    @EnvironmentObject var contactsVM: ContactsViewModel
    @EnvironmentObject var guardianVM: GuardianViewModel
    @EnvironmentObject var session: UserSessionManager

    var body: some View {
        NavigationStack {
            Group {
                if contactsVM.contacts.isEmpty {
                    ContentUnavailableView(
                        "My emergency list",
                        systemImage: "person.badge.plus",
                        description: Text("Add people you trust. You can call or message them quickly from here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SafeWalkTheme.background)
                } else {
                    List {
                        if !contactsVM.guardians.isEmpty {
                            Section {
                                ForEach(contactsVM.guardians) { contact in
                                    ContactRowView(contact: contact)
                                        .environmentObject(guardianVM)
                                        .environmentObject(session)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: SafeWalkTheme.cardCornerRadius)
                                                .fill(SafeWalkTheme.cardElevated)
                                                .padding(.vertical, 2)
                                        )
                                }
                            } header: {
                                Text("Guardians")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SafeWalkTheme.textSecondary)
                            }
                        }

                        if !contactsVM.regularContacts.isEmpty {
                            Section {
                                ForEach(contactsVM.regularContacts) { contact in
                                    ContactRowView(contact: contact)
                                        .environmentObject(guardianVM)
                                        .environmentObject(session)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: SafeWalkTheme.cardCornerRadius)
                                                .fill(SafeWalkTheme.cardElevated)
                                                .padding(.vertical, 2)
                                        )
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { i in
                                        contactsVM.deleteContact(id: contactsVM.regularContacts[i].id)
                                    }
                                }
                            } header: {
                                Text("Emergency contacts")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SafeWalkTheme.textSecondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(SafeWalkTheme.background)
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        contactsVM.showAddContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
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

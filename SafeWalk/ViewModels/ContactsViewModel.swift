import Foundation
import Combine

class ContactsViewModel: ObservableObject {
    
    @Published var contacts: [Contact] = []
    @Published var showAddContact: Bool = false
    @Published var selectedContact: Contact?
    
    private let coreData = CoreDataManager.shared
    
    init() {
        loadContacts()
    }
    
    func loadContacts() {
        contacts = coreData.fetchContacts()
    }
    
    func addContact(name: String, phone: String, email: String, isGuardian: Bool) {
        let contact = Contact(name: name, phone: phone, email: email, isGuardian: isGuardian)
        coreData.saveContact(contact)
        loadContacts()
    }
    
    func deleteContact(id: UUID) {
        coreData.deleteContact(id: id)
        loadContacts()
    }
    
    var guardians: [Contact] {
        contacts.filter { $0.isGuardian }
    }
    
    var regularContacts: [Contact] {
        contacts.filter { !$0.isGuardian }
    }
}

import Combine
import Foundation

class ContactsViewModel: ObservableObject {

    @Published var contacts: [Contact] = []
    @Published var showAddContact: Bool = false
    @Published var selectedContact: Contact?

    private let coreData = CoreDataManager.shared
    private var session: UserSessionManager?

    init() {}
    
    func bind(session: UserSessionManager) {
        self.session = session
        loadContacts()
    }

    func loadContacts() {
        guard let userID = session?.currentUserID, !userID.isEmpty else { return }
        contacts = coreData.fetchContacts(for: userID)
    }

    func addContact(name: String, phone: String, email: String, isGuardian: Bool, imageData: Data? = nil) {
        guard let userID = session?.currentUserID else { return }
        let contact = Contact(name: name, phone: phone, email: email, isGuardian: isGuardian, imageData: imageData)
        coreData.saveContact(contact, for: userID)
        loadContacts()
    }

    func deleteContact(id: UUID) {
        guard let userID = session?.currentUserID else { return }
        coreData.deleteContact(id: id, for: userID)
        loadContacts()
    }

    var guardians: [Contact] {
        contacts.filter { $0.isGuardian }
    }

    var regularContacts: [Contact] {
        contacts.filter { !$0.isGuardian }
    }
}

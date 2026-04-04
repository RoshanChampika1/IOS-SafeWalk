import Foundation
import CoreData

// MARK: - Core Data Entity (define in .xcdatamodeld as well)
// Entity Name: ContactEntity
// Attributes: id (UUID), name (String), phone (String), isGuardian (Boolean), email (String)

struct Contact: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var email: String
    var isGuardian: Bool
    
    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - CoreData Extension
extension ContactEntity {
    func toContact() -> Contact {
        Contact(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            phone: self.phone ?? "",
            email: self.email ?? "",
            isGuardian: self.isGuardian
        )
    }
    
    func update(from contact: Contact) {
        self.id = contact.id
        self.name = contact.name
        self.phone = contact.phone
        self.email = contact.email
        self.isGuardian = contact.isGuardian
    }
}

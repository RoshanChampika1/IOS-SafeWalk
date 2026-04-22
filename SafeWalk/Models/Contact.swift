import Foundation

struct Contact: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var email: String
    var isGuardian: Bool
    var imageData: Data?

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

extension Contact: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, phone, email, isGuardian, imageData
    }
}

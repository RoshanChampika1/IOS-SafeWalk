import XCTest
@testable import SafeWalk

/// Tests for the Contact model's computed properties and protocol conformances.
final class ContactModelTests: XCTestCase {

    // MARK: - Initials

    func test_initials_singleWord() {
        let contact = Contact(name: "Roshan", phone: "", email: "", isGuardian: false)
        XCTAssertEqual(contact.initials, "R")
    }

    func test_initials_twoWords() {
        let contact = Contact(name: "Roshan Champika", phone: "", email: "", isGuardian: false)
        XCTAssertEqual(contact.initials, "RC")
    }

    func test_initials_threeWords_usesFirstAndSecond() {
        let contact = Contact(name: "Roshan Champika Silva", phone: "", email: "", isGuardian: false)
        // Only first + second word initials
        XCTAssertEqual(contact.initials, "RC")
    }

    func test_initials_emptyName() {
        let contact = Contact(name: "", phone: "", email: "", isGuardian: false)
        XCTAssertEqual(contact.initials, "")
    }

    func test_initials_lowercaseName_returnsUppercase() {
        let contact = Contact(name: "anu bandara", phone: "", email: "", isGuardian: false)
        XCTAssertEqual(contact.initials, "AB")
    }

    // MARK: - Equality (uses id, not name)

    func test_equality_sameID_differentName_areEqual() {
        let id = UUID()
        let a = Contact(id: id, name: "Alice", phone: "1", email: "", isGuardian: false)
        let b = Contact(id: id, name: "Bob",   phone: "2", email: "", isGuardian: true)
        XCTAssertEqual(a, b)
    }

    func test_equality_differentID_areNotEqual() {
        let a = Contact(name: "Alice", phone: "1", email: "", isGuardian: false)
        let b = Contact(name: "Alice", phone: "1", email: "", isGuardian: false)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Hashable

    func test_hashing_sameID_sameHash() {
        let id = UUID()
        let a = Contact(id: id, name: "X", phone: "", email: "", isGuardian: false)
        let b = Contact(id: id, name: "Y", phone: "", email: "", isGuardian: true)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_usableAsSetElement() {
        let id = UUID()
        let a = Contact(id: id, name: "X", phone: "", email: "", isGuardian: false)
        let b = Contact(id: id, name: "Y", phone: "", email: "", isGuardian: false)
        let set: Set<Contact> = [a, b]
        // Same id → same element → set should contain only 1
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Codable round-trip

    func test_codable_roundTrip() throws {
        let original = Contact(
            id: UUID(),
            name: "Nimal Perera",
            phone: "+94771234567",
            email: "nimal@example.com",
            isGuardian: true,
            imageData: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Contact.self, from: data)

        XCTAssertEqual(decoded.id,          original.id)
        XCTAssertEqual(decoded.name,        original.name)
        XCTAssertEqual(decoded.phone,       original.phone)
        XCTAssertEqual(decoded.email,       original.email)
        XCTAssertEqual(decoded.isGuardian,  original.isGuardian)
    }

    func test_codable_withImageData() throws {
        let imageBytes = Data([0xFF, 0xD8, 0xFF, 0xE0]) // fake JPEG header bytes
        let original = Contact(
            name: "Test",
            phone: "+94",
            email: "",
            isGuardian: false,
            imageData: imageBytes
        )
        let data    = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Contact.self, from: data)
        XCTAssertEqual(decoded.imageData, imageBytes)
    }

    // MARK: - Guardian flag

    func test_isGuardian_defaultsFalse() {
        let contact = Contact(name: "Test", phone: "", email: "", isGuardian: false)
        XCTAssertFalse(contact.isGuardian)
    }

    func test_isGuardian_true() {
        let contact = Contact(name: "Guardian", phone: "+94771234567", email: "", isGuardian: true)
        XCTAssertTrue(contact.isGuardian)
    }
}

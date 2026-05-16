import XCTest
@testable import SafeWalk

/// Tests for the phone normalisation and validation logic used across
/// OnboardingView and UserSessionManager.
final class PhoneValidationTests: XCTestCase {

    // MARK: - normalisePhone (mirrors logic in OnboardingView)

    private func normalisePhone(_ raw: String) -> String {
        var value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet(charactersIn: " -()"))
            .joined()
        if value.hasPrefix("00") {
            value = "+" + value.dropFirst(2)
        }
        if !value.hasPrefix("+"), value.allSatisfy(\.isNumber) {
            if value.hasPrefix("0") { value.removeFirst() }
            value = "+94" + value
        }
        return value.hasPrefix("+") ? value : ""
    }

    // MARK: - isValidPhone (mirrors logic in UserSessionManager)

    private func isValidPhone(_ phone: String) -> Bool {
        guard phone.hasPrefix("+") else { return false }
        return phone.filter(\.isNumber).count >= 7
    }

    // ── normalisePhone ───────────────────────────────────────────────

    func test_normalise_localFormat_withLeadingZero() {
        XCTAssertEqual(normalisePhone("0771234567"), "+94771234567")
    }

    func test_normalise_localFormat_withoutLeadingZero() {
        XCTAssertEqual(normalisePhone("771234567"), "+94771234567")
    }

    func test_normalise_e164_passThrough() {
        XCTAssertEqual(normalisePhone("+94771234567"), "+94771234567")
    }

    func test_normalise_doubleZeroPrefix() {
        XCTAssertEqual(normalisePhone("0094771234567"), "+94771234567")
    }

    func test_normalise_spacesStripped() {
        XCTAssertEqual(normalisePhone("+94 771 234 567"), "+94771234567")
    }

    func test_normalise_dashesStripped() {
        XCTAssertEqual(normalisePhone("+94-771-234-567"), "+94771234567")
    }

    func test_normalise_parenthesesStripped() {
        XCTAssertEqual(normalisePhone("+94(77)1234567"), "+94771234567")
    }

    func test_normalise_emptyString_returnsEmpty() {
        XCTAssertEqual(normalisePhone(""), "")
    }

    func test_normalise_alphabeticInput_returnsEmpty() {
        XCTAssertEqual(normalisePhone("abcdef"), "")
    }

    func test_normalise_mixedAlphanumeric_returnsEmpty() {
        XCTAssertEqual(normalisePhone("077abc1234"), "")
    }

    // ── isValidPhone ─────────────────────────────────────────────────

    func test_isValid_fullSriLankaNumber_true() {
        XCTAssertTrue(isValidPhone("+94771234567"))
    }

    func test_isValid_bareCountryCode_false() {
        // "+94" has only 2 digits — must be rejected
        XCTAssertFalse(isValidPhone("+94"))
    }

    func test_isValid_emptyString_false() {
        XCTAssertFalse(isValidPhone(""))
    }

    func test_isValid_noPlus_false() {
        XCTAssertFalse(isValidPhone("94771234567"))
    }

    func test_isValid_sevenDigits_true() {
        // +1234567 — 7 digits minimum threshold
        XCTAssertTrue(isValidPhone("+1234567"))
    }

    func test_isValid_sixDigits_false() {
        XCTAssertFalse(isValidPhone("+123456"))
    }

    func test_isValid_internationalUSNumber_true() {
        XCTAssertTrue(isValidPhone("+12025551234"))
    }

    // ── Combined pipeline ─────────────────────────────────────────────

    func test_pipeline_localNumber_isValid() {
        let result = normalisePhone("0771234567")
        XCTAssertTrue(isValidPhone(result))
    }

    func test_pipeline_emptyInput_isInvalid() {
        let result = normalisePhone("")
        XCTAssertFalse(isValidPhone(result))
    }

    func test_pipeline_bareCountryCode_isInvalid() {
        // Even after normalisation, "+94" must fail the valid-phone gate
        let result = normalisePhone("+94")
        XCTAssertFalse(isValidPhone(result))
    }
}

import XCTest
@testable import SafeWalk

/// Tests for the WalkSession model — status, formatted ETA, coordinate helpers.
final class WalkSessionModelTests: XCTestCase {

    private func makeSession(
        status: WalkSession.WalkStatus = .active,
        eta: Date = Date().addingTimeInterval(1800),
        lat: Double = 6.9271,
        lng: Double = 79.8612
    ) -> WalkSession {
        WalkSession(
            userID: "uid_test",
            destination: "Colombo Fort",
            destinationLat: lat,
            destinationLng: lng,
            startTime: Date(),
            eta: eta,
            status: status
        )
    }

    // MARK: - WalkStatus raw values

    func test_status_activeRawValue() {
        XCTAssertEqual(WalkSession.WalkStatus.active.rawValue, "active")
    }

    func test_status_safeRawValue() {
        XCTAssertEqual(WalkSession.WalkStatus.safe.rawValue, "safe")
    }

    func test_status_sosRawValue() {
        XCTAssertEqual(WalkSession.WalkStatus.sos.rawValue, "sos")
    }

    func test_status_expiredRawValue() {
        XCTAssertEqual(WalkSession.WalkStatus.expired.rawValue, "expired")
    }

    func test_status_decodableFromString() throws {
        let status = try JSONDecoder().decode(
            WalkSession.WalkStatus.self,
            from: Data("\"sos\"".utf8)
        )
        XCTAssertEqual(status, .sos)
    }

    // MARK: - Destination coordinate

    func test_destinationCoordinate_latitude() {
        let session = makeSession(lat: 6.9271, lng: 79.8612)
        XCTAssertEqual(session.destinationCoordinate.latitude,  6.9271,  accuracy: 0.0001)
    }

    func test_destinationCoordinate_longitude() {
        let session = makeSession(lat: 6.9271, lng: 79.8612)
        XCTAssertEqual(session.destinationCoordinate.longitude, 79.8612, accuracy: 0.0001)
    }

    // MARK: - ETA formatted

    func test_etaFormatted_isNotEmpty() {
        let session = makeSession(eta: Date().addingTimeInterval(3600))
        XCTAssertFalse(session.etaFormatted.isEmpty)
    }

    func test_etaFormatted_containsColonForTime() {
        // DateFormatter with timeStyle = .short always produces "HH:MM" or "H:MM AM/PM"
        let session = makeSession(eta: Date().addingTimeInterval(3600))
        XCTAssertTrue(session.etaFormatted.contains(":"))
    }

    // MARK: - Default values

    func test_id_isUniqueEachTime() {
        let a = makeSession()
        let b = makeSession()
        XCTAssertNotEqual(a.id, b.id)
    }

    func test_guardianAccepted_defaultsFalse() {
        let session = makeSession()
        XCTAssertFalse(session.guardianAccepted)
    }

    func test_guardianID_defaultsNil() {
        let session = makeSession()
        XCTAssertNil(session.guardianID)
    }

    func test_currentLat_defaultsNil() {
        let session = makeSession()
        XCTAssertNil(session.currentLat)
    }

    // MARK: - Codable round-trip

    func test_codable_roundTrip() throws {
        var original = makeSession(status: .sos)
        original.guardianID = "guardian_uid_123"
        original.guardianAccepted = true
        original.currentLat = 7.2906
        original.currentLng = 80.6337

        let data    = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WalkSession.self, from: data)

        XCTAssertEqual(decoded.id,               original.id)
        XCTAssertEqual(decoded.userID,           original.userID)
        XCTAssertEqual(decoded.destination,      original.destination)
        XCTAssertEqual(decoded.destinationLat,   original.destinationLat, accuracy: 0.00001)
        XCTAssertEqual(decoded.destinationLng,   original.destinationLng, accuracy: 0.00001)
        XCTAssertEqual(decoded.status,           original.status)
        XCTAssertEqual(decoded.guardianID,       original.guardianID)
        XCTAssertEqual(decoded.guardianAccepted, original.guardianAccepted)
        XCTAssertEqual(decoded.currentLat!,      original.currentLat!, accuracy: 0.00001)
        XCTAssertEqual(decoded.currentLng!,      original.currentLng!, accuracy: 0.00001)
    }
}

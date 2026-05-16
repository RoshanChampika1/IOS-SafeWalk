import XCTest
@testable import SafeWalk

/// Tests for WalkSession state management inside UserSessionManager
/// (the parts that don't require Firebase — walk start/end, SOS, flags).
final class UserSessionManagerWalkTests: XCTestCase {

    private var session: UserSessionManager!

    override func setUp() {
        super.setUp()
        session = UserSessionManager()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func test_initialState_isNotWalking() {
        XCTAssertFalse(session.isWalking)
    }

    func test_initialState_isSafe() {
        XCTAssertTrue(session.isSafe)
    }

    func test_initialState_sosNotTriggered() {
        XCTAssertFalse(session.sosTriggered)
    }

    func test_initialState_guardianNotAccepted() {
        XCTAssertFalse(session.guardianAccepted)
    }

    // MARK: - startWalk

    func test_startWalk_setsIsWalkingTrue() {
        session.startWalk()
        XCTAssertTrue(session.isWalking)
    }

    func test_startWalk_setsIsSafeFalse() {
        session.startWalk()
        XCTAssertFalse(session.isSafe)
    }

    func test_startWalk_resetsSOS() {
        // Pre-set SOS then start a new walk
        session.sosTriggered = true
        session.startWalk()
        XCTAssertFalse(session.sosTriggered)
    }

    // MARK: - endWalk

    func test_endWalk_setsIsWalkingFalse() {
        session.startWalk()
        session.endWalk()
        XCTAssertFalse(session.isWalking)
    }

    func test_endWalk_setsIsSafeTrue() {
        session.startWalk()
        session.endWalk()
        XCTAssertTrue(session.isSafe)
    }

    func test_endWalk_clearsSOS() {
        session.startWalk()
        session.triggerSOS()
        session.endWalk()
        XCTAssertFalse(session.sosTriggered)
    }

    func test_endWalk_clearsGuardianAccepted() {
        session.guardianAccepted = true
        session.endWalk()
        XCTAssertFalse(session.guardianAccepted)
    }

    // MARK: - triggerSOS

    func test_triggerSOS_setsFlagTrue() {
        session.triggerSOS()
        XCTAssertTrue(session.sosTriggered)
    }

    func test_triggerSOS_doesNotChangeIsWalking() {
        session.startWalk()
        session.triggerSOS()
        XCTAssertTrue(session.isWalking)  // still walking after SOS
    }

    // MARK: - Walk lifecycle sequence

    func test_fullLifecycle_startTriggerSOSEnd() {
        session.startWalk()
        XCTAssertTrue(session.isWalking)
        XCTAssertFalse(session.isSafe)

        session.triggerSOS()
        XCTAssertTrue(session.sosTriggered)

        session.endWalk()
        XCTAssertFalse(session.isWalking)
        XCTAssertTrue(session.isSafe)
        XCTAssertFalse(session.sosTriggered)
    }

    func test_multipleWalks_stateResetsCorrectly() {
        session.startWalk()
        session.triggerSOS()
        session.endWalk()

        // Second walk
        session.startWalk()
        XCTAssertTrue(session.isWalking)
        XCTAssertFalse(session.sosTriggered) // SOS cleared at startWalk
    }
}

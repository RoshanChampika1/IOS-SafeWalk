import Foundation
import FirebaseFirestore
import Combine

class GuardianViewModel: ObservableObject {

    @Published var activeSession: WalkSession?
    @Published var incomingRequests: [WalkSession] = []
    @Published var sessionListener: ListenerRegistration?
    @Published var requestListener: ListenerRegistration?

    private let firebase = FirebaseManager.shared

    // MARK: - Walker side

    func startWalkSession(session: WalkSession) {
        firebase.createWalkSession(session) { _ in }
        listenToSession(sessionID: session.id)
    }

    func sendGuardianRequest(sessionID: String, guardianID: String) {
        firebase.sendGuardianRequest(sessionID: sessionID, guardianID: guardianID) { _ in }
    }

    // MARK: - Guardian side

    func acceptRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: true)
        // Start listening to that session so SharedMapView updates
        listenToSession(sessionID: sessionID)
    }

    func declineRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: false)
    }

    func listenToSession(sessionID: String) {
        sessionListener = firebase.listenToSession(sessionID: sessionID) { [weak self] session in
            self?.activeSession = session
        }
    }

    /// Call this once after login with the signed-in user's Firebase UID.
    /// Uses the real UID so guardian requests addressed to this user are found.
    func startListening(forUserID uid: String) {
        // Avoid duplicate listeners
        requestListener?.remove()
        requestListener = firebase.listenForIncomingRequests(guardianID: uid) { [weak self] sessions in
            self?.incomingRequests = sessions
        }
    }

    func stopListening() {
        sessionListener?.remove()
        requestListener?.remove()
    }
}


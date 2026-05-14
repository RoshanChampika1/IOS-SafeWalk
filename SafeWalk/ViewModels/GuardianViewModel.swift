import Foundation
import FirebaseFirestore
import Combine

class GuardianViewModel: ObservableObject {

    @Published var activeSession: WalkSession?
    @Published var incomingRequests: [WalkSession] = []
    @Published var isResolvingGuardian: Bool = false
    @Published var guardianError: String?
    @Published var requestSentToName: String?
    /// Stored separately so it is NEVER wiped by the Firestore listener.
    /// Only set by startWalkSession() and cleared by stopWalkSession().
    @Published var activeSessionID: String?

    private var sessionListener: ListenerRegistration?
    private var requestListener: ListenerRegistration?
    private let firebase = FirebaseManager.shared

    // MARK: - Walk Session

    func startWalkSession(session: WalkSession) {
        activeSession = session
        activeSessionID = session.id   // stored independently — never touched by listener
        print("[Guardian] 🚶 Walk session started: \(session.id)")
        firebase.createWalkSession(session) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[Guardian] ❌ createWalkSession failed: \(error.localizedDescription)")
                } else {
                    print("[Guardian] ✅ Walk session written to Firestore")
                    self?.listenToSession(sessionID: session.id)
                }
            }
        }
    }

    /// Call when the walker's walk ends or SOS triggers so Firestore
    /// status updates to non-active and the guardian's incoming request list clears.
    func stopWalkSession(status: WalkSession.WalkStatus = .safe) {
        let id = activeSessionID ?? activeSession?.id
        if let id = id {
            firebase.updateWalkStatus(sessionID: id, status: status)
        }
        sessionListener?.remove()
        sessionListener = nil
        activeSession = nil
        activeSessionID = nil
    }

    // MARK: - Send Guardian Request
    /// Resolves the guardian's phone number → Firebase UID, then writes the
    /// guardianID into the walk session so the guardian's app can see it.
    func sendGuardianRequest(sessionID: String, guardianPhone: String, guardianName: String = "") {
        guard !guardianPhone.isEmpty else {
            guardianError = "Guardian has no phone number saved."
            return
        }
        isResolvingGuardian = true
        guardianError = nil
        requestSentToName = nil

        firebase.findGuardianUID(byPhone: guardianPhone) { [weak self] uid in
            DispatchQueue.main.async {
                self?.isResolvingGuardian = false
                guard let uid = uid else {
                    self?.guardianError = "Guardian is not registered on SafeWalk yet. Ask them to sign up first."
                    return
                }
                self?.firebase.sendGuardianRequest(sessionID: sessionID, guardianID: uid) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.guardianError = error.localizedDescription
                        } else {
                            self?.requestSentToName = guardianName.isEmpty ? "Guardian" : guardianName
                        }
                    }
                }
            }
        }
    }

    // MARK: - Accept / Decline

    func acceptRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: true)
        listenToSession(sessionID: sessionID)
    }

    func declineRequest(sessionID: String) {
        // Remove guardianID field so this session no longer appears in our query
        firebase.declineGuardianRequest(sessionID: sessionID)
    }

    // MARK: - Listeners

    func listenToSession(sessionID: String) {
        sessionListener?.remove()
        sessionListener = firebase.listenToSession(sessionID: sessionID) { [weak self] session in
            self?.activeSession = session
        }
    }

    func listenForRequests(guardianID: String) {
        requestListener?.remove()
        requestListener = firebase.listenForIncomingRequests(guardianID: guardianID) { [weak self] sessions in
            self?.incomingRequests = sessions
        }
    }

    func stopListening() {
        sessionListener?.remove()
        requestListener?.remove()
        sessionListener = nil
        requestListener = nil
    }
}

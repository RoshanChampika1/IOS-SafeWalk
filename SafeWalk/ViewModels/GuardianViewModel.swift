import Foundation
import FirebaseFirestore
import Combine

class GuardianViewModel: ObservableObject {

    @Published var activeSession: WalkSession?
    @Published var incomingRequests: [WalkSession] = []
    @Published var isResolvingGuardian: Bool = false
    @Published var guardianError: String?

    private var sessionListener: ListenerRegistration?
    private var requestListener: ListenerRegistration?
    private let firebase = FirebaseManager.shared

    // MARK: - Walk Session

    func startWalkSession(session: WalkSession) {
        activeSession = session
        firebase.createWalkSession(session) { _ in }
        listenToSession(sessionID: session.id)
    }

    // MARK: - Send Guardian Request
    /// Resolves the guardian's phone number → Firebase UID, then writes the
    /// guardianID into the walk session so the guardian's app can see it.
    func sendGuardianRequest(sessionID: String, guardianPhone: String) {
        guard !guardianPhone.isEmpty else {
            guardianError = "Guardian has no phone number saved."
            return
        }
        isResolvingGuardian = true
        guardianError = nil

        firebase.findGuardianUID(byPhone: guardianPhone) { [weak self] uid in
            DispatchQueue.main.async {
                self?.isResolvingGuardian = false
                guard let uid = uid else {
                    self?.guardianError = "Guardian is not registered on SafeWalk yet. Ask them to sign up."
                    return
                }
                self?.firebase.sendGuardianRequest(sessionID: sessionID, guardianID: uid) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.guardianError = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    // MARK: - Accept / Decline

    func acceptRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: true)
    }

    func declineRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: false)
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

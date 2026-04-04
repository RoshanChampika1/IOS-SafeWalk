import Foundation
import FirebaseFirestore
import Combine

class GuardianViewModel: ObservableObject {
    
    @Published var activeSession: WalkSession?
    @Published var incomingRequests: [WalkSession] = []
    @Published var sessionListener: ListenerRegistration?
    @Published var requestListener: ListenerRegistration?
    
    private let firebase = FirebaseManager.shared
    
    func startWalkSession(session: WalkSession) {
        firebase.createWalkSession(session) { _ in }
        listenToSession(sessionID: session.id)
    }
    
    func sendGuardianRequest(sessionID: String, guardianID: String) {
        firebase.sendGuardianRequest(sessionID: sessionID, guardianID: guardianID) { _ in }
    }
    
    func acceptRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: true)
    }
    
    func declineRequest(sessionID: String) {
        firebase.respondToGuardianRequest(sessionID: sessionID, accepted: false)
    }
    
    func listenToSession(sessionID: String) {
        sessionListener = firebase.listenToSession(sessionID: sessionID) { [weak self] session in
            self?.activeSession = session
        }
    }
    
    func listenForRequests(guardianID: String) {
        requestListener = firebase.listenForIncomingRequests(guardianID: guardianID) { [weak self] sessions in
            self?.incomingRequests = sessions
        }
    }
    
    func stopListening() {
        sessionListener?.remove()
        requestListener?.remove()
    }
}

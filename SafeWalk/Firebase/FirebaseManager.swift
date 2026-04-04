import Foundation
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // MARK: - Walk Session
    func createWalkSession(_ session: WalkSession, completion: @escaping (Error?) -> Void) {
        guard let data = try? Firestore.Encoder().encode(session) else { return }
        db.collection("walkSessions").document(session.id).setData(data) { error in
            completion(error)
        }
    }
    
    func updateWalkStatus(sessionID: String, status: WalkSession.WalkStatus) {
        db.collection("walkSessions").document(sessionID).updateData([
            "status": status.rawValue
        ])
    }
    
    func updateUserLocation(sessionID: String, lat: Double, lng: Double) {
        db.collection("walkSessions").document(sessionID).updateData([
            "currentLat": lat,
            "currentLng": lng
        ])
    }
    
    // MARK: - Guardian Request
    func sendGuardianRequest(sessionID: String, guardianID: String, completion: @escaping (Error?) -> Void) {
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianID": guardianID,
            "guardianAccepted": false
        ]) { error in
            completion(error)
        }
    }
    
    func respondToGuardianRequest(sessionID: String, accepted: Bool) {
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianAccepted": accepted
        ])
    }
    
    // MARK: - Listen for Guardian Updates
    func listenToSession(sessionID: String, onChange: @escaping (WalkSession?) -> Void) -> ListenerRegistration {
        return db.collection("walkSessions").document(sessionID).addSnapshotListener { snapshot, _ in
            guard let snapshot = snapshot, snapshot.exists else {
                onChange(nil)
                return
            }
            let session = try? Firestore.Decoder().decode(WalkSession.self, from: snapshot.data() ?? [:])
            onChange(session)
        }
    }
    
    // MARK: - Guardian: Listen for incoming requests
    func listenForIncomingRequests(guardianID: String, onChange: @escaping ([WalkSession]) -> Void) -> ListenerRegistration {
        return db.collection("walkSessions")
            .whereField("guardianID", isEqualTo: guardianID)
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, _ in
                let sessions = snapshot?.documents.compactMap {
                    try? Firestore.Decoder().decode(WalkSession.self, from: $0.data())
                } ?? []
                onChange(sessions)
            }
    }
}

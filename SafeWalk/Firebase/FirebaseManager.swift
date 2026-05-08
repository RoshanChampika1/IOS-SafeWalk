import Combine
import FirebaseCore
import FirebaseFirestore
import Foundation

class FirebaseManager: ObservableObject {

    static let shared = FirebaseManager()

    private var firestore: Firestore? {
        guard FirebaseBootstrap.isConfigured else { return nil }
        return Firestore.firestore()
    }

    // MARK: - User Profile Sync
    func syncUserProfile(userID: String, name: String, email: String) {
        guard let db = firestore else { return }
        db.collection("users").document(userID).setData([
            "name": name,
            "email": email,
            "lastSync": Timestamp(date: Date())
        ], merge: true)
    }

    // MARK: - Phone Verification
    /// Saves the verified E.164 phone number on the user document and writes
    /// a reverse-lookup entry so other users can resolve phone → Firebase UID.
    func saveVerifiedPhone(userID: String, phone: String) {
        guard let db = firestore else { return }
        // 1. Store on the user's own document
        db.collection("users").document(userID).setData([
            "phone": phone,
            "phoneVerified": true
        ], merge: true)
        // 2. Write reverse-lookup index  phoneIndex/{e164} -> { uid }
        let key = phone.replacingOccurrences(of: "+", with: "")
        db.collection("phoneIndex").document(key).setData(["uid": userID], merge: true)
    }

    /// Looks up the Firebase UID for a given E.164 phone number.
    /// Calls `completion` with the UID string, or `nil` if not found.
    func lookupUID(byPhone phone: String, completion: @escaping (String?) -> Void) {
        guard let db = firestore else {
            completion(nil)
            return
        }
        let key = phone.replacingOccurrences(of: "+", with: "")
        db.collection("phoneIndex").document(key).getDocument { snapshot, _ in
            let uid = snapshot?.data()?["uid"] as? String
            completion(uid)
        }
    }

    // MARK: - Walk Session
    func createWalkSession(_ session: WalkSession, completion: @escaping (Error?) -> Void) {
        guard let db = firestore else {
            completion(nil)
            return
        }
        guard let data = try? Firestore.Encoder().encode(session) else { return }
        db.collection("walkSessions").document(session.id).setData(data) { error in
            completion(error)
        }
    }

    func updateWalkStatus(sessionID: String, status: WalkSession.WalkStatus) {
        guard let db = firestore else { return }
        db.collection("walkSessions").document(sessionID).updateData([
            "status": status.rawValue
        ])
    }

    func updateUserLocation(sessionID: String, lat: Double, lng: Double) {
        guard let db = firestore else { return }
        db.collection("walkSessions").document(sessionID).updateData([
            "currentLat": lat,
            "currentLng": lng
        ])
    }

    // MARK: - Guardian Request
    func sendGuardianRequest(sessionID: String, guardianID: String, completion: @escaping (Error?) -> Void) {
        guard let db = firestore else {
            completion(nil)
            return
        }
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianID": guardianID,
            "guardianAccepted": false
        ]) { error in
            completion(error)
        }
    }

    func respondToGuardianRequest(sessionID: String, accepted: Bool) {
        guard let db = firestore else { return }
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianAccepted": accepted
        ])
    }

    // MARK: - Listen for Guardian Updates
    func listenToSession(sessionID: String, onChange: @escaping (WalkSession?) -> Void) -> ListenerRegistration? {
        guard let db = firestore else {
            DispatchQueue.main.async { onChange(nil) }
            return nil
        }
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
    func listenForIncomingRequests(guardianID: String, onChange: @escaping ([WalkSession]) -> Void) -> ListenerRegistration? {
        guard let db = firestore else {
            DispatchQueue.main.async { onChange([]) }
            return nil
        }
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

import Combine
import FirebaseFirestore
import Foundation

class FirebaseManager: ObservableObject {

    static let shared = FirebaseManager()

    private var firestore: Firestore? {
        guard FirebaseBootstrap.isConfigured else { return nil }
        return Firestore.firestore()
    }

    // MARK: - User Profile Sync
    // Stores name, phone, and email under users/{uid} so other users can look up
    // a guardian's UID from their phone number or email address.
    func syncUserProfile(userID: String, name: String, phone: String, email: String = "") {
        guard let db = firestore, !userID.isEmpty else { return }
        var data: [String: Any] = [
            "name":     name,
            "lastSync": Timestamp(date: Date())
        ]
        // Only write non-empty identifiers so we don't overwrite with blanks
        let normalisedPhone = normalisePhone(phone)
        if !normalisedPhone.isEmpty { data["phone"] = normalisedPhone }
        if !email.isEmpty { data["email"] = email }
        db.collection("users").document(userID).setData(data, merge: true)
    }

    func fetchUserProfile(userID: String, completion: @escaping ([String: Any]?) -> Void) {
        guard let db = firestore, !userID.isEmpty else {
            completion(nil)
            return
        }
        db.collection("users").document(userID).getDocument { snapshot, _ in
            completion(snapshot?.data())
        }
    }

    // MARK: - Guardian UID Lookup
    /// Resolves a contact's phone number to their Firebase UID so we can
    /// populate walkSession.guardianID correctly.
    func findGuardianUID(byPhone phone: String, completion: @escaping (String?) -> Void) {
        guard let db = firestore else {
            completion(nil)
            return
        }
        let normalised = normalisePhone(phone)
        guard !normalised.isEmpty else {
            completion(nil)
            return
        }
        print("[Guardian] 🔍 Looking up guardian phone: \(normalised)")
        db.collection("users")
            .whereField("phone", isEqualTo: normalised)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                let uid = snapshot?.documents.first?.documentID
                if let uid = uid {
                    print("[Guardian] ✅ Resolved guardian UID: \(uid)")
                } else {
                    print("[Guardian] ❌ No user found for phone: \(normalised)")
                }
                completion(uid)
            }
    }

    // MARK: - Phone Normalization

    private func normalisePhone(_ phone: String) -> String {
        var value = phone
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet(charactersIn: " -()"))
            .joined()
        if value.hasPrefix("00") {
            value = "+" + value.dropFirst(2)
        }
        if !value.hasPrefix("+"), value.allSatisfy(\.isNumber) {
            if value.hasPrefix("0") {
                value.removeFirst()
            }
            value = "+94" + value
        }
        return value
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
        print("[Guardian] 📍 Location update — session: \(sessionID) → (\(String(format: "%.5f", lat)), \(String(format: "%.5f", lng)))")
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
        print("[Guardian] 📤 Sending request — session: \(sessionID), guardian: \(guardianID)")
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianID":       guardianID,
            "guardianAccepted": false
        ]) { error in
            if let error = error {
                print("[Guardian] ❌ sendGuardianRequest error: \(error.localizedDescription)")
            } else {
                print("[Guardian] ✅ Guardian request written to Firestore")
            }
            completion(error)
        }
    }

    func respondToGuardianRequest(sessionID: String, accepted: Bool) {
        guard let db = firestore else { return }
        print("[Guardian] \(accepted ? "✅ Accepted" : "❌ Declined") guardian request — session: \(sessionID)")
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianAccepted": accepted
        ])
    }
    
    func declineGuardianRequest(sessionID: String) {
        guard let db = firestore else { return }
        print("[Guardian] ❌ Declining and removing guardian from session: \(sessionID)")
        db.collection("walkSessions").document(sessionID).updateData([
            "guardianID": FieldValue.delete(),
            "guardianAccepted": FieldValue.delete()
        ])
    }

    // MARK: - Session Listener

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

    // MARK: - Guardian Incoming Request Listener

    func listenForIncomingRequests(guardianID: String, onChange: @escaping ([WalkSession]) -> Void) -> ListenerRegistration? {
        guard let db = firestore else {
            DispatchQueue.main.async { onChange([]) }
            return nil
        }
        print("[Guardian] 👂 Listening for incoming requests for guardianID: \(guardianID)")
        return db.collection("walkSessions")
            .whereField("guardianID", isEqualTo: guardianID)
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, _ in
                let sessions = snapshot?.documents.compactMap {
                    try? Firestore.Decoder().decode(WalkSession.self, from: $0.data())
                } ?? []
                print("[Guardian] 📥 Incoming requests count: \(sessions.count)")
                onChange(sessions)
            }
    }
}

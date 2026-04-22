import Combine
import FirebaseFirestore
import Foundation

@MainActor
class RouteService: ObservableObject {
    
    @Published var communityRoutes: [SavedRoute] = []
    
    private var db: Firestore? {
        guard FirebaseBootstrap.isConfigured else { return nil }
        return Firestore.firestore()
    }
    
    private var listener: ListenerRegistration?
    
    init() {
        listenToCommunityRoutes()
    }
    
    func saveRoute(_ route: SavedRoute) {
        guard let db = db else {
            // Local fallback logic could go here if needed, but for now we require Firestore
            return
        }
        
        do {
            let data = try Firestore.Encoder().encode(route)
            db.collection("savedRoutes").document(route.id).setData(data)
        } catch {
            print("Failed to encode SavedRoute: \(error.localizedDescription)")
        }
    }
    
    func listenToCommunityRoutes() {
        guard let db = db else { return }
        
        // Listen to routes within the last 7 days to keep map relevant
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        listener = db.collection("savedRoutes")
            .whereField("timestamp", isGreaterThan: Timestamp(date: weekAgo))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents, error == nil else {
                    print("Error fetching community routes: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let routes: [SavedRoute] = documents.compactMap { doc in
                    try? Firestore.Decoder().decode(SavedRoute.self, from: doc.data())
                }
                
                // Sort newest first
                self.communityRoutes = routes.sorted { $0.timestamp > $1.timestamp }
            }
    }
    
    deinit {
        listener?.remove()
    }
}

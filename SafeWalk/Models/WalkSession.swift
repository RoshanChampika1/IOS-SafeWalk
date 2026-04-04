import Foundation
import CoreLocation

struct WalkSession: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userID: String
    var destination: String
    var destinationLat: Double
    var destinationLng: Double
    var startTime: Date
    var eta: Date
    var status: WalkStatus
    var guardianID: String?
    var guardianAccepted: Bool = false
    var currentLat: Double?
    var currentLng: Double?
    
    enum WalkStatus: String, Codable {
        case active = "active"
        case safe = "safe"
        case sos = "sos"
        case expired = "expired"
    }
    
    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLat, longitude: destinationLng)
    }
    
    var etaFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
}

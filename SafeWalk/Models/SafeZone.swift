import Foundation
import CoreLocation

struct SafeZone: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double // in meters
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static var examples: [SafeZone] = [
        SafeZone(name: "Home", latitude: 6.9271, longitude: 79.8612, radius: 100),
        SafeZone(name: "University", latitude: 6.9022, longitude: 79.8607, radius: 200)
    ]
}

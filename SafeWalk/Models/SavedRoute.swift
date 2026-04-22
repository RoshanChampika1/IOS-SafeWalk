import CoreLocation
import Foundation

struct RouteCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

struct SavedRoute: Identifiable, Codable {
    let id: String
    let userID: String
    let userName: String
    let timestamp: Date
    let isSafe: Bool
    let reviewMessage: String
    let routePoints: [RouteCoordinate]
    
    init(id: String = UUID().uuidString,
         userID: String,
         userName: String,
         timestamp: Date = Date(),
         isSafe: Bool,
         reviewMessage: String,
         routePoints: [CLLocationCoordinate2D]) {
        self.id = id
        self.userID = userID
        self.userName = userName
        self.timestamp = timestamp
        self.isSafe = isSafe
        self.reviewMessage = reviewMessage
        self.routePoints = routePoints.map { RouteCoordinate(coordinate: $0) }
    }
}

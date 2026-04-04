import Foundation
import MapKit
import CoreLocation
import Combine

class MapViewModel: ObservableObject {
    
    @Published var destination: MKMapItem?
    @Published var destinationName: String = ""
    @Published var route: MKRoute?
    @Published var searchResults: [MKMapItem] = []
    @Published var searchText: String = ""
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Published var distanceRemaining: Double = 0
    @Published var eta: Date = Date()
    
    func searchLocation(query: String, region: MKCoordinateRegion) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        MKLocalSearch(request: request).start { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.searchResults = response?.mapItems ?? []
            }
        }
    }
    
    func calculateRoute(from userLocation: CLLocationCoordinate2D, to destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = destination
        request.transportType = .walking
        
        MKDirections(request: request).calculate { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.route = response?.routes.first
                self?.distanceRemaining = response?.routes.first?.distance ?? 0
                self?.eta = Date().addingTimeInterval(response?.routes.first?.expectedTravelTime ?? 0)
                self?.destination = destination
                self?.destinationName = destination.name ?? "Destination"
            }
        }
    }
    
    var estimatedMinutes: Int {
        Int((eta.timeIntervalSince(Date())) / 60)
    }
    
    var distanceFormatted: String {
        let meters = distanceRemaining
        if meters > 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }
}

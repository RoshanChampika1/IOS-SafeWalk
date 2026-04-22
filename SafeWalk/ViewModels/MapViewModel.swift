import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

class MapViewModel: ObservableObject {

    @Published var destination: MKMapItem?
    @Published var destinationName: String = ""
    @Published var route: MKRoute?
    @Published var searchResults: [MKMapItem] = []
    @Published var searchText: String = ""
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
        )
    )
    @Published var distanceRemaining: Double = 0
    @Published var eta: Date = Date()

    /// Search hint region: prefer user location; otherwise a wide world hint so overseas queries still resolve.
    static func searchRegion(userCoordinate: CLLocationCoordinate2D?, fallbackCenter: CLLocationCoordinate2D) -> MKCoordinateRegion {
        if let c = userCoordinate {
            return MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        }
        return MKCoordinateRegion(center: fallbackCenter, span: MKCoordinateSpan(latitudeDelta: 80, longitudeDelta: 80))
    }

    func searchLocation(query: String, region: MKCoordinateRegion) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region
        if #available(iOS 13.0, *) {
            request.resultTypes = [.address, .pointOfInterest]
        }

        MKLocalSearch(request: request).start { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("MKLocalSearch error: \(error.localizedDescription)")
                }
                self?.searchResults = response?.mapItems ?? []
            }
        }
    }

    func calculateRoute(from userLocation: CLLocationCoordinate2D, to destination: MKMapItem) {
        let request = MKDirections.Request()
        let placemark = MKPlacemark(coordinate: userLocation)
        request.source = MKMapItem(placemark: placemark)
        request.destination = destination
        request.transportType = .walking

        MKDirections(request: request).calculate { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.route = response?.routes.first
                self?.distanceRemaining = response?.routes.first?.distance ?? 0
                self?.eta = Date().addingTimeInterval(response?.routes.first?.expectedTravelTime ?? 0)
                self?.destination = destination
                self?.destinationName = destination.name ?? destination.placemark.title ?? "Destination"
            }
        }
    }

    func centerCamera(on coordinate: CLLocationCoordinate2D, animated: Bool = true) {
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))
        cameraPosition = .region(region)
    }

    var estimatedMinutes: Int {
        max(0, Int((eta.timeIntervalSince(Date())) / 60))
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

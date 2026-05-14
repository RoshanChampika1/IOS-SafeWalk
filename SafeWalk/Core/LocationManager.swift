import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var enteredSafeZone: Bool = false
    @Published var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // Set this to the active walk session ID so location updates push to Firestore
    var activeSessionID: String?
    
    // Route Recording
    @Published var recordedCoordinates: [CLLocationCoordinate2D] = []
    private var isRecordingRoute: Bool = false
    
    private var safeZones: [CLCircularRegion] = []
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }
    
    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }

    /// Keeps GPS warm on the Map tab (When In Use is enough for the map).
    func requestWhenInUseForMap() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func startTracking() {
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Route Recording
    func startRecordingRoute() {
        DispatchQueue.main.async {
            self.recordedCoordinates.removeAll()
            self.isRecordingRoute = true
        }
    }
    
    func stopRecordingRoute() {
        DispatchQueue.main.async {
            self.isRecordingRoute = false
        }
    }
    
    // MARK: - SafeZones
    func addSafeZone(center: CLLocationCoordinate2D, radius: Double, identifier: String) {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        manager.startMonitoring(for: region)
        safeZones.append(region)
    }
    
    func removeAllSafeZones() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        safeZones.removeAll()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.currentRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )

            if self.isRecordingRoute {
                self.recordedCoordinates.append(location.coordinate)
            }

            // Push live location to Firestore if a walk session is active
            if let sessionID = self.activeSessionID {
                FirebaseManager.shared.updateUserLocation(
                    sessionID: sessionID,
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude
                )
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedAlways ||
               manager.authorizationStatus == .authorizedWhenInUse {
                self.startTracking()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DispatchQueue.main.async {
            self.enteredSafeZone = true
        }
    }
}

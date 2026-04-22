import Combine
import SwiftUI

@main
struct SafeWalkApp: App {
    
    @StateObject private var session = UserSessionManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var routeService = RouteService()
    
    init() {
        FirebaseBootstrap.configureIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            if session.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
                    .environmentObject(routeService)
            } else {
                LoginView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
                    .environmentObject(routeService)
            }
        }
    }
}

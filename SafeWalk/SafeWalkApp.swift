import SwiftUI
import FirebaseCore

@main
struct SafeWalkApp: App {
    
    @StateObject private var session = UserSessionManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if session.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
            } else {
                OnboardingView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
            }
        }
    }
}

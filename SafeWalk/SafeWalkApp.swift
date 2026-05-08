import SwiftUI
import UIKit
import GoogleSignIn

// MARK: - App Delegate (needed for Google Sign-In URL handling)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct SafeWalkApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
                    // Show phone verification as a full-screen sheet the first
                    // time a user logs in without a verified phone number.
                    .fullScreenCover(isPresented: $session.needsPhoneVerification) {
                        PhoneVerificationView()
                            .environmentObject(session)
                    }
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

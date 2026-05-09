import FirebaseAuth
import SwiftUI

@main
struct SafeWalkApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var session: UserSessionManager
    @StateObject private var locationManager    = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var routeService       = RouteService()
    @StateObject private var guardianVM: GuardianViewModel

    /// Persisted flag — true after the user has seen the welcome slides once.
    @AppStorage("hasSeenWelcomeV2") private var hasSeenWelcome: Bool = false

    init() {
        // MUST run before any StateObjects that access Firebase
        FirebaseBootstrap.configureIfNeeded()

        _session    = StateObject(wrappedValue: UserSessionManager())
        _guardianVM = StateObject(wrappedValue: GuardianViewModel())
    }

    var body: some Scene {
        WindowGroup {
            if session.hasCompletedOnboarding {
                // ── Logged in + onboarding done ──────────────────────────
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
                    .environmentObject(routeService)
                    .environmentObject(guardianVM)
                    .onAppear {
                        if !session.currentUserID.isEmpty {
                            guardianVM.listenForRequests(guardianID: session.currentUserID)
                        }
                    }
                    .onChange(of: session.currentUserID) { _, uid in
                        guardianVM.stopListening()
                        if !uid.isEmpty {
                            guardianVM.listenForRequests(guardianID: uid)
                        }
                    }

            } else if !session.currentUserID.isEmpty {
                // ── Logged in, still needs name ──────────────────────────
                OnboardingView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
                    .environmentObject(routeService)

            } else if !hasSeenWelcome {
                // ── First install: show slides + request permissions ──────
                WelcomeView {
                    hasSeenWelcome = true   // user tapped "Get Started"
                }
                .environmentObject(locationManager)
                .environmentObject(notificationManager)

            } else {
                // ── Returning visitor: go straight to login ───────────────
                LoginView()
                    .environmentObject(session)
                    .environmentObject(locationManager)
                    .environmentObject(notificationManager)
                    .environmentObject(routeService)
            }
        }
    }
}

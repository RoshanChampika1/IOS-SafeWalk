import FirebaseAuth
import SwiftUI
import UIKit
import GoogleSignIn

// AppDelegate is defined in AppDelegate.swift

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
    /// 0 = system, 1 = light, 2 = dark
    @AppStorage("appearanceSetting") private var appearanceSetting: Int = 0

    private var preferredColorScheme: ColorScheme? {
        switch appearanceSetting {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    init() {
        // MUST run before any StateObjects that access Firebase
        FirebaseBootstrap.configureIfNeeded()

        _session    = StateObject(wrappedValue: UserSessionManager())
        _guardianVM = StateObject(wrappedValue: GuardianViewModel())
    }

    var body: some Scene {
        WindowGroup {
            Group {
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
                        hasSeenWelcome = true
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
            .preferredColorScheme(preferredColorScheme)
        }
    }
}

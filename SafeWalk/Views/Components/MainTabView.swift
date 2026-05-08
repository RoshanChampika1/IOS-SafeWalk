import Combine
import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var mapVM = MapViewModel()
    @StateObject private var contactsVM = ContactsViewModel()
    @StateObject private var guardianVM = GuardianViewModel()

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(dashboardVM)
                .environmentObject(contactsVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SafeWalkMapView()
                .environmentObject(mapVM)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)

            ContactsView()
                .environmentObject(contactsVM)
                .environmentObject(guardianVM)
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .tag(2)

            // Guardian tab — shows incoming requests and the shared live map
            NavigationStack {
                List {
                    Section("Incoming requests") {
                        GuardianRequestView()
                            .environmentObject(guardianVM)
                    }
                    Section("Live map") {
                        NavigationLink("Open shared map") {
                            SharedMapView()
                                .environmentObject(guardianVM)
                        }
                    }
                }
                .navigationTitle("Guardian")
            }
            .tabItem {
                Label("Guardian", systemImage: "shield.fill")
            }
            .badge(guardianVM.incomingRequests.isEmpty ? 0 : guardianVM.incomingRequests.count)
            .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(SafeWalkTheme.primaryBlue)
        .environmentObject(guardianVM)
        .onAppear {
            contactsVM.bind(session: session)
            // Start guardian request listener using the real Firebase UID
            guardianVM.startListening(forUserID: session.currentUserID)
        }
        .onDisappear {
            guardianVM.stopListening()
        }
        // Re-attach listener if the user UID changes (e.g. re-login)
        .onChange(of: session.currentUserID) { _, newUID in
            guard !newUID.isEmpty else { return }
            guardianVM.startListening(forUserID: newUID)
        }
    }
}


import Combine
import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    // Use the guardianVM injected from SafeWalkApp so the listener
    // is on the same instance that was set up there.
    @EnvironmentObject var guardianVM: GuardianViewModel

    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var mapVM = MapViewModel()
    @StateObject private var contactsVM = ContactsViewModel()

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(dashboardVM)
                .environmentObject(contactsVM)
                .environmentObject(guardianVM)
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
                    }
                    Section("Live map") {
                        NavigationLink("Open shared map") {
                            SharedMapView()
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
                .environmentObject(session)
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(SafeWalkTheme.primaryBlue)
        .onAppear {
            contactsVM.bind(session: session)
        }
    }
}

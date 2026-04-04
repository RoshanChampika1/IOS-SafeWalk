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
                .tabItem {
                    Label("Home", systemImage: "shield.fill")
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
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.indigo)
    }
}

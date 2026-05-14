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

            // Guardian tab
            NavigationStack {
                List {
                    // ── Incoming requests ──────────────────────────────
                    Section {
                        if guardianVM.incomingRequests.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "shield.slash")
                                        .font(.largeTitle)
                                        .foregroundStyle(SafeWalkTheme.textSecondary)
                                    Text("No incoming requests")
                                        .font(.subheadline)
                                        .foregroundStyle(SafeWalkTheme.textSecondary)
                                    Text("You'll see requests here when a walker adds you as their guardian.")
                                        .font(.caption)
                                        .foregroundStyle(SafeWalkTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 20)
                            .listRowBackground(Color.clear)
                        } else {
                            GuardianRequestView()
                                .environmentObject(guardianVM)
                        }
                    } header: {
                        Text("Incoming requests")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SafeWalkTheme.textSecondary)
                    }

                    // ── Live map (visible only after accepting) ─────────
                    if guardianVM.activeSession != nil {
                        Section {
                            NavigationLink("Open shared map") {
                                SharedMapView()
                                    .environmentObject(guardianVM)
                            }
                        } header: {
                            Text("Live map")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SafeWalkTheme.textSecondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
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


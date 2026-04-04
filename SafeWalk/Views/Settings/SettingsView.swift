import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var defaultTimer: Int = 300
    @State private var enableVibration: Bool = true
    @State private var autoSOSEnabled: Bool = true
    @State private var guardianID: String = ""
    @State private var showResetAlert: Bool = false
    
    let timerOptions = [("3 min", 180), ("5 min", 300), ("10 min", 600), ("15 min", 900), ("30 min", 1800)]
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile
                Section("Profile") {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Text(String(session.userName.prefix(1)).uppercased())
                                .font(.title2.bold())
                                .foregroundColor(.indigo)
                        }
                        VStack(alignment: .leading) {
                            Text(session.userName)
                                .font(.headline)
                            Text("User ID: \(session.currentUserID.prefix(8))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextField("Your Guardian ID (share with others)", text: $guardianID)
                        .font(.caption)
                }
                
                // Timer defaults
                Section("Default Timer") {
                    Picker("Duration", selection: $defaultTimer) {
                        ForEach(timerOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Safety preferences
                Section("Safety") {
                    Toggle("Vibration Alerts", isOn: $enableVibration)
                    Toggle("Auto-SOS on Expiry", isOn: $autoSOSEnabled)
                }
                
                // Permissions
                Section("Permissions") {
                    HStack {
                        Label("Location", systemImage: "location.fill")
                        Spacer()
                        Text(locationManager.authorizationStatus == .authorizedAlways ? "Always" :
                             locationManager.authorizationStatus == .authorizedWhenInUse ? "In Use" : "Denied")
                            .foregroundColor(locationManager.authorizationStatus == .authorizedAlways ? .green : .orange)
                            .font(.caption)
                    }
                    
                    HStack {
                        Label("Notifications", systemImage: "bell.fill")
                        Spacer()
                        Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                            .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
                            .font(.caption)
                    }
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                // Guardian section
                Section("Guardian Mode") {
                    NavigationLink("Guardian Requests") {
                        GuardianRequestView()
                    }
                    NavigationLink("Shared Live Map") {
                        SharedMapView()
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Built With")
                        Spacer()
                        Text("SwiftUI · Firebase · MapKit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Reset
                Section {
                    Button("Reset App", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset App?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "onboardingDone")
                    UserDefaults.standard.removeObject(forKey: "userName")
                    session.hasCompletedOnboarding = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear all data and restart onboarding.")
            }
        }
    }
}

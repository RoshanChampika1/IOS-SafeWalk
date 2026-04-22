import Combine
import CoreLocation
import SwiftUI
import UIKit

struct SettingsView: View {

    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @AppStorage("defaultTimerSetting") private var defaultTimer: Int = 300
    @AppStorage("enableVibrationSetting") private var enableVibration: Bool = true
    @AppStorage("autoSOSEnabledSetting") private var autoSOSEnabled: Bool = true
    @AppStorage("guardianIDSetting") private var guardianID: String = ""
    @State private var showResetAlert: Bool = false
    @AppStorage("biometricEnabledSetting") private var biometricEnabled: Bool = true
    @AppStorage("fakeCallEnabledSetting") private var fakeCallEnabled: Bool = true
    @AppStorage("sirenEnabledSetting") private var sirenEnabled: Bool = true

    let timerOptions = [("3 min", 180), ("5 min", 300), ("10 min", 600), ("15 min", 900), ("30 min", 1800)]

    var body: some View {
        NavigationStack {
            Form {
                if !FirebaseBootstrap.isConfigured {
                    Section {
                        Label {
                            Text("Cloud sync is off. Add GoogleService-Info.plist from Firebase to enable guardian live features.")
                        } icon: {
                            Image(systemName: "icloud.slash")
                                .foregroundStyle(SafeWalkTheme.warningOrange)
                        }
                        .font(.subheadline)
                    }
                    .listRowBackground(SafeWalkTheme.warningOrange.opacity(0.12))
                }

                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeWalkTheme.primaryBlue.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Text(String(session.userName.prefix(1)).uppercased())
                                .font(.title2.bold())
                                .foregroundStyle(SafeWalkTheme.primaryBlue)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.userName.isEmpty ? "User" : session.userName)
                                .font(.headline)
                            Text("ID: \(session.currentUserID.prefix(8))…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Profile")
                }

                Section {
                    TextField("Guardian ID (share with trusted people)", text: $guardianID)
                        .font(.subheadline)
                } header: {
                    Text("Guardian")
                }

                Section {
                    Picker("Default timer", selection: $defaultTimer) {
                        ForEach(timerOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Safety timer")
                }

                Section {
                    Toggle("Biometric lock", isOn: $biometricEnabled)
                    Toggle("Fake call shortcut", isOn: $fakeCallEnabled)
                    Toggle("Siren shortcut", isOn: $sirenEnabled)
                } header: {
                    Text("Safety protocols")
                }

                Section {
                    Toggle("Vibration alerts", isOn: $enableVibration)
                    Toggle("Auto-SOS on timer expiry", isOn: $autoSOSEnabled)
                } header: {
                    Text("Alerts")
                }

                Section {
                    HStack {
                        Label("Location", systemImage: "location.fill")
                        Spacer()
                        Text(locationStatusLabel)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(locationStatusColor)
                    }

                    HStack {
                        Label("Notifications", systemImage: "bell.fill")
                        Spacer()
                        Text(notificationManager.isAuthorized ? "On" : "Off")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(notificationManager.isAuthorized ? SafeWalkTheme.callGreen : SafeWalkTheme.warningOrange)
                    }

                    Button("Open system settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(SafeWalkTheme.primaryBlue)
                } header: {
                    Text("Permissions")
                }

                Section {
                    NavigationLink {
                        GuardianRequestView()
                    } label: {
                        Label("Guardian requests", systemImage: "person.badge.shield.checkmark.fill")
                    }
                    NavigationLink {
                        SharedMapView()
                    } label: {
                        Label("Shared live map", systemImage: "map.fill")
                    }
                } header: {
                    Text("Guardian mode")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }

                Section {
                    Button("Switch User / Log Out", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SafeWalkTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Switch User?", isPresented: $showResetAlert) {
                Button("Switch", role: .destructive) {
                    session.changeUser()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will securely log you out and return you to the welcome screen.")
            }
        }
    }

    private var locationStatusLabel: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While using"
        case .denied, .restricted: return "Denied"
        default: return "Not set"
        }
    }

    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return SafeWalkTheme.callGreen
        default: return SafeWalkTheme.warningOrange
        }
    }
}

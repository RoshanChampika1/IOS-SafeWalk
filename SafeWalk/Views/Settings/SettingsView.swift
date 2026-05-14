import Combine
import CoreLocation
import FirebaseAuth
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
    @AppStorage("biometricEnabledSetting") private var biometricEnabled: Bool = true
    @AppStorage("sirenEnabledSetting") private var sirenEnabled: Bool = true
    /// 0 = system, 1 = light, 2 = dark
    @AppStorage("appearanceSetting") private var appearanceSetting: Int = 0
    @State private var showResetAlert: Bool = false

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
                    Toggle("Siren shortcut", isOn: $sirenEnabled)
                } header: {
                    Text("Safety protocols")
                }

                Section {
                    HStack(spacing: 0) {
                        appearanceButton(label: "System", icon: "circle.lefthalf.filled", value: 0)
                        Divider().frame(height: 36)
                        appearanceButton(label: "Light", icon: "sun.max.fill", value: 1)
                        Divider().frame(height: 36)
                        appearanceButton(label: "Dark", icon: "moon.fill", value: 2)
                    }
                    .background(SafeWalkTheme.cardElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Appearance")
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
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text("Log Out")
                    }

                    Button(role: .destructive) {
                        deleteAccount()
                    } label: {
                        Text("Delete Account Permanently")
                            .foregroundStyle(SafeWalkTheme.emergencyRed)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SafeWalkTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Log Out?", isPresented: $showResetAlert) {
                Button("Log Out", role: .destructive) {
                    session.changeUser()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will securely log you out and return you to the login screen.")
            }
        }
    }

    private func deleteAccount() {
        // Delete from Firebase Backend completely
        let user = FirebaseAuth.Auth.auth().currentUser
        user?.delete { error in
            if error == nil {
                session.changeUser() // logs out and clears local data
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

    private func appearanceButton(label: String, icon: String, value: Int) -> some View {
        Button {
            appearanceSetting = value
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(appearanceSetting == value ? SafeWalkTheme.primaryBlue : SafeWalkTheme.textSecondary)
                Text(label)
                    .font(.caption.weight(appearanceSetting == value ? .semibold : .regular))
                    .foregroundStyle(appearanceSetting == value ? SafeWalkTheme.primaryBlue : SafeWalkTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(appearanceSetting == value ? SafeWalkTheme.primaryBlue.opacity(0.12) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceSetting {
        case 1: return .light
        case 2: return .dark
        default: return nil   // follows system
        }
    }
}

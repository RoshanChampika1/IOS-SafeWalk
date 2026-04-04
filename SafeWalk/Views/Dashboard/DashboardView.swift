import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var dashboardVM: DashboardViewModel
    
    @State private var showDurationPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: session.isWalking ? [Color.indigo.opacity(0.9), Color.black] : [Color(hex: "0f0f1a"), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hello, \(session.userName) 👋")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text(session.isWalking ? "Stay safe out there" : "Ready when you are")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Status badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(session.isWalking ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(session.isWalking ? "Active" : "Idle")
                                .font(.caption.bold())
                                .foregroundColor(session.isWalking ? .green : .gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    
                    // Timer Ring
                    TimerRingView(
                        progress: dashboardVM.timerManager.progress,
                        timeString: dashboardVM.timerManager.formattedTime,
                        isRunning: dashboardVM.timerManager.isRunning
                    )
                    .frame(width: 240, height: 240)
                    
                    // Duration Picker (when not walking)
                    if !session.isWalking {
                        VStack(spacing: 12) {
                            Text("Set Duration")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 10) {
                                ForEach(dashboardVM.presets, id: \.seconds) { preset in
                                    Button {
                                        dashboardVM.timerDuration = preset.seconds
                                    } label: {
                                        Text(preset.label)
                                            .font(.callout.bold())
                                            .foregroundColor(dashboardVM.timerDuration == preset.seconds ? .black : .white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                dashboardVM.timerDuration == preset.seconds ? Color.white : Color.white.opacity(0.1)
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 14) {
                        if !session.isWalking {
                            Button {
                                dashboardVM.startWalk(session: session, location: locationManager, notifications: notificationManager)
                            } label: {
                                Label("Start Safe Walk", systemImage: "figure.walk")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        } else {
                            // Disarm Button
                            Button {
                                dashboardVM.disarmWithBiometrics(session: session)
                            } label: {
                                Label("I'm Safe — Disarm", systemImage: "faceid")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            
                            // SOS Button
                            SOSButtonView {
                                dashboardVM.triggerSOS(session: session)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("⚠️ Timer Expired!", isPresented: $dashboardVM.showTimerExpiredAlert) {
                Button("I'm Safe") {
                    dashboardVM.disarmWithBiometrics(session: session)
                }
                Button("SOS!", role: .destructive) {
                    dashboardVM.triggerSOS(session: session)
                }
            } message: {
                Text("Your safety timer has run out. Are you okay?")
            }
        }
    }
}

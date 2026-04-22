import Combine
import SwiftUI
import UIKit

struct DashboardView: View {

    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel

    @Environment(\.openURL) private var openURL

    @State private var showIncomingBanner: Bool = false
    @State private var showFullFakeCall: Bool = false
    @State private var showProfile: Bool = false
    @State private var showDisarmSheet: Bool = false
    @State private var fakeCallTask: Task<Void, Never>?
    @State private var fakeCallPendingLabel: Bool = false

    @AppStorage("fakeCallEnabledSetting") private var fakeCallEnabled: Bool = true
    @AppStorage("sirenEnabledSetting") private var sirenEnabled: Bool = true

    private var fakeCaller: (name: String, image: Data?) {
        if let g = contactsVM.guardians.first { return (g.name, g.imageData) }
        if let c = contactsVM.contacts.first { return (c.name, c.imageData) }
        return ("Trusted contact", nil)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        if session.sosTriggered {
                            sosBanner
                        }

                        timerCard

                        statusRowIfWalking

                        quickActions

                        durationSection

                        primaryWalkButton

                        if session.isWalking {
                            emergencyDialSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .padding(.top, showIncomingBanner ? 100 : 0)
                }
                .animation(nil, value: session.isWalking)
                .animation(nil, value: dashboardVM.timerManager.secondsRemaining)

                if showIncomingBanner {
                    IncomingCallBannerView(
                        callerName: fakeCaller.name,
                        imageData: fakeCaller.image,
                        onDecline: { endFakeCallSession() },
                        onAnswer: { endFakeCallSession() },
                        onTapExpand: {
                            showFullFakeCall = true
                        }
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(SafeWalkTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SafeWalk")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SafeWalkTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        profileAvatar
                    }
                    .accessibilityLabel("Open profile")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(session)
            }
            .sheet(isPresented: $showDisarmSheet) {
                DisarmAuthSheet(
                    disarmDevice: { completion in
                        dashboardVM.disarmWithDeviceAuth(
                            session: session,
                            notifications: notificationManager,
                            location: locationManager,
                            contacts: contactsVM.contacts,
                            completion: completion
                        )
                    },
                    verifyPasscode: { code in
                        dashboardVM.verifyAppPasscodeAndDisarm(
                            code,
                            session: session,
                            notifications: notificationManager,
                            location: locationManager,
                            contacts: contactsVM.contacts
                        )
                    }
                )
            }
            .sheet(item: $dashboardVM.emergencyMessage) { payload in
                MessageComposeView(recipients: payload.recipients, body: payload.body) {
                    dashboardVM.emergencyMessage = nil
                }
            }
            .sheet(isPresented: $dashboardVM.showRouteReview) {
                RouteReviewSheet(routePoints: locationManager.recordedCoordinates)
                    .environmentObject(contactsVM)
            }
            .fullScreenCover(isPresented: $showFullFakeCall) {
                FakeIncomingCallView(
                    callerName: fakeCaller.name,
                    imageData: fakeCaller.image
                ) {
                    endFakeCallSession()
                }
            }
            .alert("Are you safe?", isPresented: $dashboardVM.showTimerExpiredAlert) {
                Button("I'm Safe") {
                    showDisarmSheet = true
                }
                Button("SOS", role: .destructive) {
                    dashboardVM.triggerSOS(session: session, notifications: notificationManager)
                }
            } message: {
                Text("Your safety timer has run out. Tap I'm Safe after verifying, or SOS if you need help.")
            }
            .onChange(of: session.isWalking) { _, walking in
                if !walking {
                    dashboardVM.stopSiren()
                    cancelFakeCallSchedule()
                }
            }
            .onDisappear {
                cancelFakeCallSchedule()
            }
        }
    }

    private func scheduleFakeCall() {
        cancelFakeCallSchedule()
        fakeCallPendingLabel = true
        fakeCallTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                fakeCallPendingLabel = false
                FakeCallRingtone.shared.start()
                showIncomingBanner = true
            }
        }
    }

    private func cancelFakeCallSchedule() {
        fakeCallTask?.cancel()
        fakeCallTask = nil
        fakeCallPendingLabel = false
        FakeCallRingtone.shared.stop()
        showIncomingBanner = false
        showFullFakeCall = false
    }

    private func endFakeCallSession() {
        cancelFakeCallSchedule()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(session.userName.isEmpty ? "there" : session.userName)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SafeWalkTheme.textPrimary)
                Text(session.isWalking ? "Timer is active — stay aware." : "Start your safety timer before you walk.")
                    .font(.subheadline)
                    .foregroundStyle(SafeWalkTheme.textSecondary)
                if fakeCallPendingLabel {
                    Text("Fake call in ~30s…")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SafeWalkTheme.warningOrange)
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let data = session.profileImageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(SafeWalkTheme.primaryBlue.opacity(0.25), lineWidth: 1))
        } else {
            ZStack {
                Circle()
                    .fill(SafeWalkTheme.primaryBlue.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(String(session.userName.prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(SafeWalkTheme.primaryBlue)
            }
        }
    }

    private var sosBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text("SOS active — get to safety and use emergency call if needed.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeWalkTheme.emergencyRed)
        .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
    }

    private var timerCard: some View {
        VStack(spacing: 20) {
            Text(session.isWalking ? "Safety timer" : "Start safety timer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SafeWalkTheme.textSecondary)

            TimerRingView(
                progress: dashboardVM.timerManager.progress,
                timeString: dashboardVM.timerManager.formattedTimeHMS,
                isRunning: dashboardVM.timerManager.isRunning,
                style: .light
            )
            .frame(width: 220, height: 220)
            .frame(maxWidth: .infinity)

            if !session.isWalking {
                Button {
                    dashboardVM.startWalk(
                        session: session,
                        location: locationManager,
                        notifications: notificationManager,
                        contacts: contactsVM.contacts
                    )
                } label: {
                    Text("Start")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SafeWalkTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                }
                .accessibilityLabel("Start safety timer")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .safeWalkCardStyle()
    }

    @ViewBuilder
    private var statusRowIfWalking: some View {
        if session.isWalking {
            HStack {
                Label("Walk in progress", systemImage: "figure.walk")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Circle()
                    .fill(SafeWalkTheme.callGreen)
                    .frame(width: 8, height: 8)
                Text("Active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SafeWalkTheme.callGreen)
            }
            .padding(14)
            .safeWalkCardStyle()
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        if fakeCallEnabled || sirenEnabled {
            HStack(spacing: 12) {
                if fakeCallEnabled {
                    quickActionButton(
                        title: fakeCallPendingLabel ? "Cancel fake call" : "Fake call",
                        systemImage: "phone.arrow.down.left",
                        tint: SafeWalkTheme.primaryBlue
                    ) {
                        if fakeCallPendingLabel || showIncomingBanner || showFullFakeCall {
                            cancelFakeCallSchedule()
                        } else {
                            scheduleFakeCall()
                        }
                    }
                }
                
                if sirenEnabled {
                    quickActionButton(
                        title: "Siren",
                        systemImage: dashboardVM.isSirenPlaying ? "speaker.slash.fill" : "speaker.wave.3.fill",
                        tint: dashboardVM.isSirenPlaying ? SafeWalkTheme.warningOrange : SafeWalkTheme.primaryBlue
                    ) {
                        dashboardVM.toggleSiren()
                    }
                }
            }
        }
    }

    private func quickActionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SafeWalkTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .safeWalkCardStyle()
        }
        .buttonStyle(.plain)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SafeWalkTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(dashboardVM.presets, id: \.seconds) { preset in
                    Button {
                        dashboardVM.timerDuration = preset.seconds
                    } label: {
                        Text(preset.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(dashboardVM.timerDuration == preset.seconds ? .white : SafeWalkTheme.primaryBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                dashboardVM.timerDuration == preset.seconds
                                    ? SafeWalkTheme.primaryBlue
                                    : SafeWalkTheme.primaryBlue.opacity(0.12)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Custom (stopwatch-style)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SafeWalkTheme.textSecondary)
                HStack(spacing: 16) {
                    Stepper("Min \(dashboardVM.customMinutes)", value: $dashboardVM.customMinutes, in: 0...120)
                    Stepper("Sec \(dashboardVM.customSeconds)", value: $dashboardVM.customSeconds, in: 0...59, step: 1)
                }
                .font(.caption)
                Button("Use custom duration") {
                    dashboardVM.applyCustomDuration()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SafeWalkTheme.primaryBlue)
            }
        }
        .padding(.vertical, 4)
        .opacity(session.isWalking ? 0.4 : 1)
        .disabled(session.isWalking)
        .allowsHitTesting(!session.isWalking)
        .frame(maxWidth: .infinity, minHeight: session.isWalking ? 96 : nil, alignment: .topLeading)
    }

    private var primaryWalkButton: some View {
        Group {
            if session.isWalking {
                VStack(spacing: 14) {
                    Button {
                        showDisarmSheet = true
                    } label: {
                        Label("I'm safe — disarm", systemImage: "lock.open.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SafeWalkTheme.callGreen)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                    }

                    SOSButtonView {
                        dashboardVM.triggerSOS(session: session, notifications: notificationManager)
                    }
                }
            }
        }
    }

    private var emergencyDialSection: some View {
        VStack(spacing: 12) {
            Text("Emergency call")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SafeWalkTheme.textSecondary)
            if let url = emergencyPhoneURL {
                Button {
                    openURL(url)
                } label: {
                    ZStack {
                        Circle()
                            .fill(SafeWalkTheme.callGreen)
                            .frame(width: 72, height: 72)
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Call emergency contact")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var emergencyPhoneURL: URL? {
        let digits = contactsVM.guardians.first?.phone.filter(\.isNumber) ?? ""
        if !digits.isEmpty { return URL(string: "tel:\(digits)") }
        return URL(string: "tel:112")
    }
}

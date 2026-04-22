import AudioToolbox
import Combine
import CoreLocation
import Foundation
import MessageUI
import UIKit

struct EmergencyMessagePayload: Identifiable {
    let id = UUID()
    let recipients: [String]
    let body: String
}

class DashboardViewModel: ObservableObject {

    @Published var timerDuration: Int = 300 {
        didSet {
            customMinutes = timerDuration / 60
            customSeconds = timerDuration % 60
            if !timerManager.isRunning {
                timerManager.setIdleCountdown(seconds: timerDuration)
            }
        }
    }
    @Published var customMinutes: Int = 5
    @Published var customSeconds: Int = 0
    @Published var showTimerExpiredAlert: Bool = false
    @Published var showSOSConfirmation: Bool = false
    @Published var showRouteReview: Bool = false
    @Published var isDisarmed: Bool = false
    @Published var isSirenPlaying: Bool = false
    @Published var emergencyMessage: EmergencyMessagePayload?

    let timerManager = TimerManager()
    private var cancellables = Set<AnyCancellable>()
    private var sirenTimer: Timer?

    var presets: [(label: String, seconds: Int)] = [
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900),
        ("30 min", 1800)
    ]

    init() {
        timerManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        timerManager.setIdleCountdown(seconds: timerDuration)
    }

    func applyCustomDuration() {
        let total = max(30, min(7200, customMinutes * 60 + customSeconds))
        timerDuration = total
    }

    func startWalk(
        session: UserSessionManager,
        location: LocationManager,
        notifications: NotificationManager,
        contacts: [Contact]
    ) {
        notifications.cancelAll()
        notifications.scheduleAutomaticCheckIns(totalSeconds: timerDuration)
        session.startWalk()
        location.startTracking()
        location.startRecordingRoute()

        timerManager.onExpire = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                // Immediately trigger SOS state
                self.triggerSOS(session: session, notifications: notifications)
                
                // Simulate an automatic backend push notification to the emergency contact
                // instead of opening the manual SMS composer.
                notifications.postSimulatedContactNotification(contacts: contacts, coordinate: location.userLocation)
            }
        }
        timerManager.start(seconds: timerDuration)
    }

    private func deliverEmergencySMSIfNeeded(contacts: [Contact], coordinate: CLLocationCoordinate2D?, userName: String) {
        let phones = contacts.map { $0.phone.filter(\.isNumber) }.filter { !$0.isEmpty }
        guard !phones.isEmpty else { return }
        let body = EmergencySMSBuilder.body(coordinate: coordinate, userName: userName)
        if MFMessageComposeViewController.canSendText() {
            emergencyMessage = EmergencyMessagePayload(recipients: phones, body: body)
        } else if let first = phones.first, let url = EmergencySMSBuilder.smsURL(phoneDigits: first, body: body) {
            UIApplication.shared.open(url)
        }
    }

    func completeDisarm(session: UserSessionManager, notifications: NotificationManager, location: LocationManager, contacts: [Contact]) {
        notifications.cancelAll()
        timerManager.invalidate()
        location.stopRecordingRoute()
        
        notifications.postSimulatedSafeArrivalNotification(contacts: contacts)

        if !location.recordedCoordinates.isEmpty {
            showRouteReview = true
        } else {
            isDisarmed = true
            location.stopTracking()
            session.endWalk()
        }
    }

    func disarmWithDeviceAuth(session: UserSessionManager, notifications: NotificationManager, location: LocationManager, contacts: [Contact], completion: @escaping (Bool) -> Void) {
        session.authenticateUser { [weak self] success in
            guard let self else {
                completion(false)
                return
            }
            if success {
                self.completeDisarm(session: session, notifications: notifications, location: location, contacts: contacts)
            }
            completion(success)
        }
    }

    func verifyAppPasscodeAndDisarm(
        _ code: String,
        session: UserSessionManager,
        notifications: NotificationManager,
        location: LocationManager,
        contacts: [Contact]
    ) -> Bool {
        guard AppPasscodeStore.matches(code) else { return false }
        completeDisarm(session: session, notifications: notifications, location: location, contacts: contacts)
        return true
    }

    func triggerSOS(session: UserSessionManager, notifications: NotificationManager) {
        timerManager.invalidate()
        notifications.cancelAll()
        session.triggerSOS()
        notifications.postImmediateSOSNotification()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    }

    func toggleSiren() {
        if isSirenPlaying {
            stopSiren()
        } else {
            startSiren()
        }
    }

    func startSiren() {
        stopSiren()
        isSirenPlaying = true
        let t = Timer(timeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(1005)
        }
        sirenTimer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func stopSiren() {
        sirenTimer?.invalidate()
        sirenTimer = nil
        isSirenPlaying = false
    }

    deinit {
        sirenTimer?.invalidate()
    }

    func endWalkSafely(session: UserSessionManager, location: LocationManager, notifications: NotificationManager) {
        timerManager.invalidate()
        notifications.cancelAll()
        location.stopTracking()
        location.stopRecordingRoute()
        isDisarmed = true
        session.endWalk()
        showRouteReview = false
    }
}

import Foundation
import Combine
import CoreLocation

class DashboardViewModel: ObservableObject {
    
    @Published var timerDuration: Int = 300
    @Published var customMinutes: Int = 5
    @Published var showTimerExpiredAlert: Bool = false
    @Published var showSOSConfirmation: Bool = false
    @Published var isDisarmed: Bool = false
    
    let timerManager = TimerManager()
    private var cancellables = Set<AnyCancellable>()
    
    var presets: [(label: String, seconds: Int)] = [
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900),
        ("30 min", 1800)
    ]
    
    func startWalk(session: UserSessionManager, location: LocationManager, notifications: NotificationManager) {
        session.startWalk()
        location.startTracking()
        timerManager.onExpire = { [weak self] in
            self?.showTimerExpiredAlert = true
            notifications.scheduleSOSAlert(in: 30)
        }
        timerManager.start(seconds: timerDuration)
    }
    
    func disarmWithBiometrics(session: UserSessionManager) {
        session.authenticateUser { [weak self] success in
            if success {
                self?.timerManager.invalidate()
                self?.isDisarmed = true
                session.endWalk()
            }
        }
    }
    
    func triggerSOS(session: UserSessionManager) {
        timerManager.invalidate()
        session.triggerSOS()
    }
    
    func endWalkSafely(session: UserSessionManager, location: LocationManager, notifications: NotificationManager) {
        timerManager.invalidate()
        notifications.cancelAll()
        location.stopTracking()
        session.endWalk()
    }
}

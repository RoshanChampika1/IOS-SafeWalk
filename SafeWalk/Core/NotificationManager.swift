import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    
    @Published var isAuthorized: Bool = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleSOSAlert(in seconds: Double = 30) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ SafeWalk Alert"
        content.body = "Your timer expired. Are you safe? Tap to confirm."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "sos_alert", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleSafeZoneNotification(zoneName: String) {
        let content = UNMutableNotificationContent()
        content.title = "✅ SafeZone Reached"
        content.body = "You've entered \(zoneName). Your timer has been paused."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "safezone_entered", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

import Combine
import Foundation
import UserNotifications
import CoreLocation
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    @Published var isAuthorized: Bool = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    /// Three escalating check-ins: ~3 min left, 1 min left, 30 s left (relative to total duration).
    func scheduleAutomaticCheckIns(totalSeconds: Int) {
        guard totalSeconds > 0 else { return }

        let checkpoints: [(fireAfter: Int, id: String, title: String, body: String, timeSensitive: Bool)] = [
            (
                totalSeconds - 180,
                "safewalk_checkin_three",
                "🟢 Automatic check-in",
                "About 3 minutes left on your timer. Open SafeWalk and authenticate when you’re safe.",
                false
            ),
            (
                totalSeconds - 60,
                "safewalk_checkin_one",
                "🟠 Automatic check-in",
                "1 minute left. Check in now — use Face ID or your app passcode to confirm you’re safe.",
                true
            ),
            (
                totalSeconds - 30,
                "safewalk_checkin_thirty",
                "🔴 Automatic check-in",
                "30 seconds left. Confirm you’re safe or your emergency flow may start.",
                true
            )
        ]

        for c in checkpoints {
            guard c.fireAfter > 0 else { continue }
            let content = UNMutableNotificationContent()
            content.title = c.title
            content.body = c.body
            content.sound = .default
            content.interruptionLevel = c.timeSensitive ? .timeSensitive : .active
            content.threadIdentifier = "safewalk_checkin"
            content.categoryIdentifier = c.id

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(c.fireAfter), repeats: false)
            let request = UNNotificationRequest(identifier: c.id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }

        let endContent = UNMutableNotificationContent()
        endContent.title = "SafeWalk — timer ended"
        endContent.body = "Your safety timer finished. Open the app to confirm you’re okay."
        endContent.sound = .default
        endContent.threadIdentifier = "safewalk_timer"
        let endTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(totalSeconds), repeats: false)
        let endRequest = UNNotificationRequest(identifier: "safewalk_timer_expired", content: endContent, trigger: endTrigger)
        UNUserNotificationCenter.current().add(endRequest)
    }

    func scheduleSOSAlert(in seconds: Double = 30) {
        let content = UNMutableNotificationContent()
        content.title = "SafeWalk alert"
        content.body = "Your timer expired. Are you safe? Open the app."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "safewalk_sos_followup", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func postImmediateSOSNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SOS — SafeWalk"
        content.body = "SOS was activated from your timer screen. Get to safety and contact help if needed."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false)
        let request = UNNotificationRequest(identifier: "safewalk_sos_immediate_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleSafeZoneNotification(zoneName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Safe zone reached"
        content.body = "You’ve entered \(zoneName)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "safezone_entered", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func postSimulatedContactNotification(contacts: [Contact], coordinate: CLLocationCoordinate2D?) {
        guard let firstContact = contacts.first else { return }
        let content = UNMutableNotificationContent()
        content.title = "Push Sent to \(firstContact.name)"
        
        if let _ = coordinate {
            content.body = "Automatic push notification containing your live location was delivered to \(firstContact.name) in the background."
        } else {
            content.body = "Automatic push notification was delivered to \(firstContact.name) in the background."
        }
        
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        // Use a unique ID so it always shows
        let request = UNNotificationRequest(identifier: "simulated_contact_push_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func postSimulatedSafeArrivalNotification(contacts: [Contact]) {
        let guardianName = contacts.first?.name ?? "your guardian"
        let content = UNMutableNotificationContent()
        content.title = "Safely Reached Destination"
        content.body = "A notification has been sent to \(guardianName) letting them know you arrived safely."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "simulated_safe_arrival_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification banner and play sound even if the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
}

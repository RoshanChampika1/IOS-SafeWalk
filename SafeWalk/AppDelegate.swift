import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

/// AppDelegate required so Firebase Phone Auth can forward APNs
/// device tokens and silent push notifications for OTP verification.
/// Also required to forward OAuth redirect URLs to GoogleSignIn.
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Force Firebase phone auth testing mode for local/dev environments where
        // APNs entitlement is unavailable. This works with fictional test numbers
        // configured in Firebase Auth console.
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true

        // Register for remote notifications so Firebase can silently
        // verify the phone number via APNs.
        application.registerForRemoteNotifications()
        return true
    }

    // MARK: - APNs Token → Firebase Auth

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Use .sandbox for dev builds (Xcode → device), .production for App Store
        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .production)
        #endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("SafeWalk: APNs registration failed — \(error.localizedDescription)")
        // Phone Auth will fall back to reCAPTCHA on simulator.
    }

    // MARK: - Silent Push → Firebase Auth

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Let Firebase Auth handle its own silent notifications first.
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // Not a Firebase notification — handle it normally.
        completionHandler(.newData)
    }

    // MARK: - URL Callbacks (Google Sign-In OAuth + Phone reCAPTCHA)

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // ✅ MUST forward to GIDSignIn first — this is how Google Sign-In
        // receives the OAuth result after the browser redirects back to the app.
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        // Firebase Phone Auth reCAPTCHA fallback (simulator / no APNs).
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
}


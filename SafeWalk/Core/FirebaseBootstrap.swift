import Foundation
import FirebaseAuth
import FirebaseCore

enum FirebaseBootstrap {

    static var isConfigured: Bool {
        return FirebaseApp.app() != nil
    }

    /// Configures Firebase using GoogleService-Info.plist.
    static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else { return }

        FirebaseApp.configure()

        #if DEBUG
        // Disable app verification so test phone numbers added in Firebase Console
        // work with a fixed OTP without needing APNs or reCAPTCHA.
        // REMOVE or set to false before releasing to App Store.
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        print("SafeWalk: Firebase configured using standard default configuration.")
        print("SafeWalk: ⚠️  Phone auth app verification DISABLED for testing.")
        #endif
    }
}



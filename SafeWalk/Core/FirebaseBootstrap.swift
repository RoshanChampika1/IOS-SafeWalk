import Foundation
import FirebaseCore

enum FirebaseBootstrap {
    /// Configures Firebase only when `GoogleService-Info.plist` contains a real `GOOGLE_APP_ID`.
    /// Skips configuration otherwise so the app runs without a Firebase project (local-only mode).
    static func configureIfNeeded() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let appId = dict["GOOGLE_APP_ID"] as? String,
              !appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            #if DEBUG
            print("SafeWalk: Firebase not configured — add GoogleService-Info.plist from Firebase Console for cloud features.")
            #endif
            return
        }
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }
}

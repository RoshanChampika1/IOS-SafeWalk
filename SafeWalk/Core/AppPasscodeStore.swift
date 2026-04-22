import Foundation

enum AppPasscodeStore {
    private static let key = "appPasscode"

    static var savedPasscode: String? {
        UserDefaults.standard.string(forKey: key)
    }

    static var hasPasscode: Bool {
        guard let s = savedPasscode else { return false }
        return !s.isEmpty
    }

    static func matches(_ entry: String) -> Bool {
        guard let saved = savedPasscode else { return false }
        return saved == entry
    }
}

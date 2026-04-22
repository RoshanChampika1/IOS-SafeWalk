import SwiftUI

/// Figma-aligned palette: light surfaces, blue primary, red/orange for alerts.
enum SafeWalkTheme {
    static let primaryBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let cardElevated = Color(uiColor: .systemBackground)
    static let emergencyRed = Color(red: 0.92, green: 0.26, blue: 0.21)
    static let warningOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let callGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
}

struct SafeWalkCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SafeWalkTheme.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.cardCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func safeWalkCardStyle() -> some View {
        modifier(SafeWalkCardModifier())
    }
}

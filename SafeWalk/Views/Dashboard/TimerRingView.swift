import SwiftUI

struct TimerRingView: View {

    enum Style {
        case dark
        case light
    }

    let progress: Double
    let timeString: String
    let isRunning: Bool
    var style: Style = .light

    private var ringColor: Color {
        if progress > 0.5 { return SafeWalkTheme.callGreen }
        if progress > 0.25 { return SafeWalkTheme.warningOrange }
        return SafeWalkTheme.emergencyRed
    }

    private var trackColor: Color {
        switch style {
        case .dark: return Color.white.opacity(0.12)
        case .light: return Color.gray.opacity(0.2)
        }
    }

    private var centerTextColor: Color {
        switch style {
        case .dark: return .white
        case .light: return SafeWalkTheme.textPrimary
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .dark: return .gray
        case .light: return SafeWalkTheme.textSecondary
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.55), ringColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text(timeString)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(centerTextColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(isRunning ? "remaining" : "ready")
                    .font(.caption)
                    .foregroundStyle(subtitleColor)

                if isRunning {
                    Image(systemName: "waveform")
                        .foregroundStyle(ringColor)
                        .font(.caption)
                }
            }
        }
        .transaction { txn in
            txn.animation = nil
        }
    }
}

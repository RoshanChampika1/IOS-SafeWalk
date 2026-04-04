import SwiftUI

struct TimerRingView: View {
    
    let progress: Double
    let timeString: String
    let isRunning: Bool
    
    var ringColor: Color {
        if progress > 0.5 { return .green }
        if progress > 0.25 { return .yellow }
        return .red
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 16)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.5), ringColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // Glow effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor.opacity(0.3), lineWidth: 28)
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
                .animation(.linear(duration: 1), value: progress)
            
            // Center content
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(isRunning ? "remaining" : "ready")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if isRunning {
                    Image(systemName: "waveform")
                        .foregroundColor(ringColor)
                        .font(.caption)
                }
            }
        }
    }
}

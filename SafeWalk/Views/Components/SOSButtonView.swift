import SwiftUI

struct SOSButtonView: View {

    let action: () -> Void
    @State private var isPulsing: Bool = false

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(SafeWalkTheme.emergencyRed.opacity(isPulsing ? 0 : 0.35), lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.45 + Double(i) * 0.22 : 1)
                        .animation(
                            .easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(Double(i) * 0.35),
                            value: isPulsing
                        )
                }

                Circle()
                    .fill(SafeWalkTheme.emergencyRed)
                    .frame(width: 76, height: 76)

                Text("SOS")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
            }
            .contentShape(Circle())
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .onAppear { isPulsing = true }
    }
}

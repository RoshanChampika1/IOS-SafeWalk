import SwiftUI

struct SOSButtonView: View {
    
    let action: () -> Void
    @State private var isPressed: Bool = false
    @State private var isPulsing: Bool = false
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                // Pulse rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.red.opacity(isPulsing ? 0 : 0.4), lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.5 + Double(i) * 0.3 : 1)
                        .animation(
                            .easeOut(duration: 1.5).repeatForever().delay(Double(i) * 0.4),
                            value: isPulsing
                        )
                }
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 70, height: 70)
                
                Text("SOS")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { isPulsing = true }
    }
}

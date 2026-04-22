import SwiftUI
import UIKit

/// Full-screen incoming call UI (matching standard iOS incoming call).
struct FakeIncomingCallView: View {
    let callerName: String
    let imageData: Data?
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Background
            if let data = imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.4)) // Dim to ensure text readability
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.42, blue: 0.48),
                        Color(red: 0.25, green: 0.45, blue: 0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Top Header
                VStack(spacing: 6) {
                    Text("mobile")
                        .font(.title3)
                        .foregroundStyle(Color.white.opacity(0.7))
                    
                    Text(callerName)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 60)

                Spacer()

                // Call Controls Grid
                VStack(spacing: 50) {
                    // Small top row (Message & Remind Me)
                    HStack {
                        smallCallAction(title: "Message", systemImage: "message.fill")
                        Spacer()
                        smallCallAction(title: "Remind Me", systemImage: "alarm.fill")
                    }
                    .padding(.horizontal, 60)
                    
                    // Large bottom row (Decline & Accept)
                    HStack {
                        largeCallAction(title: "Decline", systemImage: "phone.down.fill", backgroundColor: .red, action: onDismiss)
                        Spacer()
                        largeCallAction(title: "Accept", systemImage: "phone.fill", backgroundColor: .green, action: onDismiss)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func smallCallAction(title: String, systemImage: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private func largeCallAction(title: String, systemImage: String, backgroundColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 76, height: 76)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.footnote.weight(.regular))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}


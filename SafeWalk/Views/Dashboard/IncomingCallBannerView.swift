import SwiftUI
import UIKit

/// Compact top banner evoking the system incoming-call strip (tap to expand full UI).
struct IncomingCallBannerView: View {
    let callerName: String
    let imageData: Data?
    var onDecline: () -> Void
    var onAnswer: () -> Void
    var onTapExpand: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .blur(radius: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .opacity(0.35)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SafeWalkTheme.primaryBlue.opacity(0.25))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Text(String(callerName.prefix(1)).uppercased())
                                .font(.title3.bold())
                                .foregroundStyle(SafeWalkTheme.primaryBlue)
                        }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Incoming")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(callerName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("Mobile")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Button(action: onDecline) {
                    Image(systemName: "phone.down.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(SafeWalkTheme.emergencyRed)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onAnswer) {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(SafeWalkTheme.callGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .padding(.horizontal, 12)
        .onTapGesture { onTapExpand() }
    }
}

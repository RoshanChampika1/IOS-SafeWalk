import Combine
import SwiftUI
import UIKit

struct ContactRowView: View {

    let contact: Contact
    @EnvironmentObject var guardianVM: GuardianViewModel
    @EnvironmentObject var session: UserSessionManager
    @Environment(\.openURL) private var openURL

    private var phoneDigits: String {
        contact.phone.filter(\.isNumber)
    }

    private var callURL: URL? {
        guard !phoneDigits.isEmpty else { return nil }
        return URL(string: "tel:\(phoneDigits)")
    }

    private var smsURL: URL? {
        guard !phoneDigits.isEmpty else { return nil }
        return URL(string: "sms:\(phoneDigits)")
    }

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let data = contact.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(contact.isGuardian ? SafeWalkTheme.primaryBlue.opacity(0.15) : Color.gray.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Text(contact.initials)
                            .font(.callout.bold())
                            .foregroundStyle(contact.isGuardian ? SafeWalkTheme.primaryBlue : SafeWalkTheme.textSecondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundStyle(SafeWalkTheme.textPrimary)
                    if contact.isGuardian {
                        Image(systemName: "shield.fill")
                            .font(.caption2)
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
                    }
                }
                Text(contact.phone)
                    .font(.subheadline)
                    .foregroundStyle(SafeWalkTheme.textSecondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 16) {
                if let url = callURL {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.body)
                            .foregroundStyle(SafeWalkTheme.callGreen)
                            .frame(width: 40, height: 40)
                            .background(SafeWalkTheme.callGreen.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                if let url = smsURL {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.body)
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
                            .frame(width: 40, height: 40)
                            .background(SafeWalkTheme.primaryBlue.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                if contact.isGuardian, session.isWalking {
                    Button {
                        if let walk = guardianVM.activeSession {
                            guardianVM.sendGuardianRequest(
                                sessionID: walk.id,
                                guardianPhone: contact.phone
                            )
                        }
                    } label: {
                        Image(systemName: "person.wave.2.fill")
                            .font(.body)
                            .foregroundStyle(SafeWalkTheme.primaryBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

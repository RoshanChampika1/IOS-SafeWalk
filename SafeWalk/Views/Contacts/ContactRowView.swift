import Combine
import CoreLocation
import SwiftUI
import UIKit

struct ContactRowView: View {

    let contact: Contact
    @EnvironmentObject var guardianVM: GuardianViewModel
    @EnvironmentObject var session: UserSessionManager
    @Environment(\.openURL) private var openURL

    @State private var isSendingRequest: Bool = false
    @State private var requestSent: Bool = false
    @State private var requestError: String?

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
        VStack(alignment: .leading, spacing: 0) {
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

                    // Guardian request button — only when walking
                    if contact.isGuardian, session.isWalking {
                        Button {
                            sendGuardianRequest()
                        } label: {
                            if isSendingRequest {
                                ProgressView()
                                    .frame(width: 40, height: 40)
                            } else {
                                Image(systemName: requestSent ? "checkmark.shield.fill" : "person.wave.2.fill")
                                    .font(.body)
                                    .foregroundStyle(requestSent ? SafeWalkTheme.callGreen : SafeWalkTheme.primaryBlue)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        (requestSent ? SafeWalkTheme.callGreen : SafeWalkTheme.primaryBlue)
                                            .opacity(0.12)
                                    )
                                    .clipShape(Circle())
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isSendingRequest || requestSent)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)

            // Inline error / status message
            if let requestError {
                Text(requestError)
                    .font(.caption)
                    .foregroundStyle(SafeWalkTheme.emergencyRed)
                    .padding(.leading, 62)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: requestSent)
        .animation(.easeInOut(duration: 0.2), value: requestError)
    }

    // MARK: - Send Guardian Request

    private func sendGuardianRequest() {
        guard !phoneDigits.isEmpty else {
            requestError = "This contact has no phone number."
            return
        }

        isSendingRequest = true
        requestError = nil

        // Normalise to E.164 — assume +94 if no country code present
        let e164: String
        if contact.phone.hasPrefix("+") {
            e164 = "+" + phoneDigits
        } else {
            // Strip leading 0 for Sri Lanka style numbers
            let stripped = phoneDigits.hasPrefix("0") ? String(phoneDigits.dropFirst()) : phoneDigits
            e164 = "+94\(stripped)"
        }

        // Look up the guardian's Firebase UID via their verified phone number
        FirebaseManager.shared.lookupUID(byPhone: e164) { guardianUID in
            DispatchQueue.main.async {
                guard let guardianUID = guardianUID else {
                    isSendingRequest = false
                    requestError = "This contact hasn't verified their number in SafeWalk yet."
                    return
                }

                // Build a WalkSession for this walk if we don't already have one
                let sessionID: String
                if let active = guardianVM.activeSession {
                    sessionID = active.id
                } else {
                    // Create a lightweight session so the guardian can receive it
                    let newSession = WalkSession(
                        userID: session.currentUserID,
                        destination: "Live walk",
                        destinationLat: 0,
                        destinationLng: 0,
                        startTime: Date(),
                        eta: Date().addingTimeInterval(1800),
                        status: .active
                    )
                    guardianVM.startWalkSession(session: newSession)
                    sessionID = newSession.id
                }

                guardianVM.sendGuardianRequest(sessionID: sessionID, guardianID: guardianUID)

                isSendingRequest = false
                requestSent = true
            }
        }
    }
}


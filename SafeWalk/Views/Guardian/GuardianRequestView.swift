import Combine
import SwiftUI

struct GuardianRequestView: View {

    @EnvironmentObject var guardianVM: GuardianViewModel

    var body: some View {
        if guardianVM.incomingRequests.isEmpty {
            Label("No incoming requests", systemImage: "shield.slash")
                .font(.subheadline)
                .foregroundStyle(SafeWalkTheme.textSecondary)
                .padding(.vertical, 8)
        } else {
            ForEach(guardianVM.incomingRequests) { walkSession in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.title)
                            .foregroundStyle(SafeWalkTheme.primaryBlue)

                        VStack(alignment: .leading) {
                            Text("Guardian Request")
                                .font(.headline)
                            Text("Someone needs your help")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        Label(walkSession.destination, systemImage: "mappin.circle")
                            .font(.subheadline)
                        Spacer()
                        Text("ETA: \(walkSession.etaFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button {
                            guardianVM.declineRequest(sessionID: walkSession.id)
                        } label: {
                            Text("Decline")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button {
                            guardianVM.acceptRequest(sessionID: walkSession.id)
                        } label: {
                            Text("Accept")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(SafeWalkTheme.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}


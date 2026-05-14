import Combine
import SwiftUI

struct GuardianRequestView: View {

    @EnvironmentObject var guardianVM: GuardianViewModel

    var body: some View {
        // Use ForEach NOT List — this view is embedded inside a List Section in MainTabView.
        // A List inside a List collapses and shows nothing.
        ForEach(guardianVM.incomingRequests) { walkSession in
            requestCard(for: walkSession)
        }
    }

    private func requestCard(for walkSession: WalkSession) -> some View {
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
                Spacer()
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
            }
        }
        .padding(.vertical, 8)
    }
}


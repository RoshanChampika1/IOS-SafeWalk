import SwiftUI

struct GuardianRequestView: View {
    
    @EnvironmentObject var guardianVM: GuardianViewModel
    @EnvironmentObject var session: UserSessionManager
    
    var body: some View {
        NavigationStack {
            List(guardianVM.incomingRequests) { walkSession in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.title)
                            .foregroundColor(.indigo)
                        
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
                        
                        Button {
                            guardianVM.acceptRequest(sessionID: walkSession.id)
                        } label: {
                            Text("Accept")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.indigo)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Guardian Requests")
            .overlay {
                if guardianVM.incomingRequests.isEmpty {
                    ContentUnavailableView(
                        "No Requests",
                        systemImage: "shield.slash",
                        description: Text("You'll see requests here when someone adds you as a Guardian.")
                    )
                }
            }
        }
    }
}

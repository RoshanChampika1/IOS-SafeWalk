import SwiftUI

struct ContactRowView: View {
    
    let contact: Contact
    @EnvironmentObject var guardianVM: GuardianViewModel
    @EnvironmentObject var session: UserSessionManager
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(contact.isGuardian ? Color.indigo.opacity(0.2) : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(contact.initials)
                    .font(.callout.bold())
                    .foregroundColor(contact.isGuardian ? .indigo : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                    if contact.isGuardian {
                        Image(systemName: "shield.fill")
                            .font(.caption2)
                            .foregroundColor(.indigo)
                    }
                }
                Text(contact.phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                // Call button
                Link(destination: URL(string: "tel:\(contact.phone)")!) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                }
                
                // Guardian request button (only when walking)
                if contact.isGuardian && session.isWalking {
                    Button {
                        // Send guardian request
                        if let session = guardianVM.activeSession {
                            guardianVM.sendGuardianRequest(
                                sessionID: session.id,
                                guardianID: contact.id.uuidString
                            )
                        }
                    } label: {
                        Image(systemName: "person.wave.2.fill")
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

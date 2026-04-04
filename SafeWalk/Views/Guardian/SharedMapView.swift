import SwiftUI
import MapKit

struct SharedMapView: View {
    
    @EnvironmentObject var guardianVM: GuardianViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let session = guardianVM.activeSession,
                   let lat = session.currentLat,
                   let lng = session.currentLng {
                    
                    let walkerCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    
                    Map {
                        Annotation("Walker", coordinate: walkerCoord) {
                            ZStack {
                                Circle()
                                    .fill(Color.indigo.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.indigo)
                                    .font(.title3)
                            }
                        }
                        
                        Marker("Destination",
                               systemImage: "mappin.circle.fill",
                               coordinate: session.destinationCoordinate)
                        .tint(.red)
                    }
                    .ignoresSafeArea()
                    
                    // Status overlay
                    VStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("LIVE")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(6)
                                
                                Text("Destination: \(session.destination)")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                    
                } else {
                    ContentUnavailableView(
                        "No Active Session",
                        systemImage: "map.slash",
                        description: Text("Accept a Guardian Request to see a live map.")
                    )
                }
            }
            .navigationTitle("Shared Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

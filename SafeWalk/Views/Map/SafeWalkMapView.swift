import SwiftUI
import MapKit

struct SafeWalkMapView: View {
    
    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var session: UserSessionManager
    
    @State private var showSearch: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                Map(position: $mapVM.cameraPosition) {
                    // User location
                    UserAnnotation()
                    
                    // Destination pin
                    if let destination = mapVM.destination {
                        Marker(mapVM.destinationName,
                               systemImage: "mappin.circle.fill",
                               coordinate: destination.placemark.coordinate)
                        .tint(.red)
                    }
                    
                    // Route overlay
                    if let route = mapVM.route {
                        MapPolyline(route.polyline)
                            .stroke(.indigo, style: StrokeStyle(lineWidth: 5, dash: [8, 4]))
                    }
                }
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                    MapScaleView()
                }
                .ignoresSafeArea(edges: .top)
                
                // Bottom Card
                VStack(spacing: 0) {
                    // Search bar
                    Button {
                        showSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            Text(mapVM.destinationName.isEmpty ? "Search destination..." : mapVM.destinationName)
                                .foregroundColor(mapVM.destinationName.isEmpty ? .gray : .primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(radius: 4)
                    }
                    .padding()
                    
                    // Route info (if route exists)
                    if mapVM.route != nil {
                        HStack(spacing: 20) {
                            VStack {
                                Text(mapVM.distanceFormatted)
                                    .font(.title3.bold())
                                Text("distance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Divider().frame(height: 40)
                            VStack {
                                Text("\(mapVM.estimatedMinutes) min")
                                    .font(.title3.bold())
                                Text("walking ETA")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Go") {
                                // Trigger walk from map
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSearch) {
                DestinationSearchView()
                    .environmentObject(mapVM)
                    .environmentObject(locationManager)
            }
        }
    }
}

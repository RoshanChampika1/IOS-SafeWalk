import Combine
import MapKit
import SwiftUI

struct SafeWalkMapView: View {

    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var routeService: RouteService

    @State private var showSearch: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $mapVM.cameraPosition) {
                    UserAnnotation()

                    if let destination = mapVM.destination {
                        Marker(
                            mapVM.destinationName,
                            systemImage: "mappin.circle.fill",
                            coordinate: destination.placemark.coordinate
                        )
                        .tint(SafeWalkTheme.emergencyRed)
                    }

                    if let route = mapVM.route {
                        MapPolyline(route.polyline)
                            .stroke(SafeWalkTheme.primaryBlue.opacity(0.8), style: StrokeStyle(lineWidth: 5, dash: [8, 4]))
                    }

                    // Currently Recording Route
                    if session.isWalking, !locationManager.recordedCoordinates.isEmpty {
                        MapPolyline(coordinates: locationManager.recordedCoordinates)
                            .stroke(SafeWalkTheme.callGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }

                    // Community Routes
                    ForEach(routeService.communityRoutes) { savedRoute in
                        MapPolyline(coordinates: savedRoute.routePoints.map(\.coordinate))
                            .stroke(savedRoute.isSafe ? SafeWalkTheme.callGreen.opacity(0.6) : SafeWalkTheme.emergencyRed.opacity(0.6),
                                    style: StrokeStyle(lineWidth: 4, dash: [5, 5]))
                        
                        if let endPoint = savedRoute.routePoints.last {
                            Annotation(savedRoute.isSafe ? "Safe Route" : "Unsafe Route", coordinate: endPoint.coordinate) {
                                VStack {
                                    Image(systemName: savedRoute.isSafe ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                        .foregroundStyle(.white)
                                        .padding(6)
                                        .background(savedRoute.isSafe ? SafeWalkTheme.callGreen : SafeWalkTheme.emergencyRed)
                                        .clipShape(Circle())
                                }
                                .onTapGesture {
                                    // Optional: We could pop a full review here!
                                }
                            }
                        }
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .mapStyle(.standard)
                .safeAreaPadding(.top, 56)

                VStack(spacing: 8) {
                    Button {
                        showSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text(mapVM.destinationName.isEmpty ? "Search destination…" : mapVM.destinationName)
                                .foregroundStyle(mapVM.destinationName.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                    }
                    .padding(.horizontal)

                    if mapVM.route != nil {
                        HStack(spacing: 20) {
                            VStack {
                                Text(mapVM.distanceFormatted)
                                    .font(.title3.bold())
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Divider().frame(height: 40)
                            VStack {
                                Text("\(mapVM.estimatedMinutes) min")
                                    .font(.title3.bold())
                                Text("Walking ETA")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 12)

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            recenterOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(SafeWalkTheme.primaryBlue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 72)
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                locationManager.requestWhenInUseForMap()
                if let c = locationManager.userLocation {
                    mapVM.centerCamera(on: c)
                }
            }
            .sheet(isPresented: $showSearch) {
                DestinationSearchView()
                    .environmentObject(mapVM)
                    .environmentObject(locationManager)
            }
        }
    }

    private func recenterOnUser() {
        locationManager.requestWhenInUseForMap()
        if let c = locationManager.userLocation {
            mapVM.centerCamera(on: c)
        } else {
            locationManager.requestPermission()
        }
    }
}

import Combine
import MapKit
import SwiftUI

struct DestinationSearchView: View {

    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(mapVM.searchResults.enumerated()), id: \.offset) { _, item in
                    Button {
                        select(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? item.placemark.name ?? "Unknown")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(item.placemark.title ?? formattedSubtitle(item))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .searchable(text: $mapVM.searchText, prompt: "Search any city or place")
            .onChange(of: mapVM.searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard !Task.isCancelled else { return }
                    let region = MapViewModel.searchRegion(
                        userCoordinate: locationManager.userLocation,
                        fallbackCenter: locationManager.currentRegion.center
                    )
                    await MainActor.run {
                        mapVM.searchLocation(query: newValue, region: region)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func select(_ item: MKMapItem) {
        if let coord = locationManager.userLocation {
            mapVM.calculateRoute(from: coord, to: item)
            mapVM.centerCamera(on: item.placemark.coordinate)
        } else {
            mapVM.destination = item
            mapVM.destinationName = item.name ?? item.placemark.title ?? "Destination"
            mapVM.route = nil
            mapVM.centerCamera(on: item.placemark.coordinate)
            locationManager.requestPermission()
        }
        dismiss()
    }

    private func formattedSubtitle(_ item: MKMapItem) -> String {
        let p = item.placemark
        let parts = [p.locality, p.administrativeArea, p.country].compactMap { $0 }
        return parts.joined(separator: ", ")
    }
}

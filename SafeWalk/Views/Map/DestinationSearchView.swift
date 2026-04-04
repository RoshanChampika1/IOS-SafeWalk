import SwiftUI
import MapKit

struct DestinationSearchView: View {
    
    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(mapVM.searchResults, id: \.self) { item in
                Button {
                    if let coord = locationManager.userLocation {
                        mapVM.calculateRoute(from: coord, to: item)
                    }
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(item.placemark.title ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $mapVM.searchText, prompt: "Where are you going?")
            .onChange(of: mapVM.searchText) { _, newValue in
                if !newValue.isEmpty, let region = locationManager.userLocation {
                    mapVM.searchLocation(
                        query: newValue,
                        region: MKCoordinateRegion(
                            center: region,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    )
                }
            }
            .navigationTitle("Search Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

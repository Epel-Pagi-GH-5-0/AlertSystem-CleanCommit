import SwiftUI
import CoreLocation
import MapKit

struct TrackView: View {
    @StateObject private var locationManager = LocationViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack {
            if let location = locationManager.lastLocation {
                MapView(region: $region, location: location)
                    .onAppear {
                        updateRegion(location)
                    }
                    .frame(width: .infinity, height: .infinity)
            } else {
                Text("Fetching location...")
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .edgesIgnoringSafeArea(.all) // This line makes the view ignore safe area constraints
    }

    private func updateRegion(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        TrackView()
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var location: CLLocation?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if let location = location {
            let coordinate = location.coordinate
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        view.setRegion(region, animated: true)
    }
}

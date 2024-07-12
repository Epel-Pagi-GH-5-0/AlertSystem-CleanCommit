import SwiftUI
import CoreLocation
import Combine

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var isLoading: Bool = true
    private var timer: Timer?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    @Published var location: Location = Location(longitude: 0.0, latitude: 0.0, city: "", country: "")

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lastLocation = location
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
        
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                self.isLoading = false
                
                if let error = error {
                    print("Error in reverse geocoding: \(error.localizedDescription)")
                } else if let placemark = placemarks?.first {
                    let city = placemark.locality
                    let country = placemark.country
                    
                    DispatchQueue.main.async {
                        self.setLocation(location: Location(longitude: longitude, latitude: latitude, city: city ?? "", country: country ?? ""))
                    }
                }
            }
        }
    }
    
    func startUpdatingLocation() {
        print("Tracking started.")
        locationManager.startUpdatingLocation()
        startTimer()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.locationManager.requestLocation()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocation()
        } else {
            stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle the error
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func getLocation() -> Location {
        return self.location
    }
    
    func setLocation(location: Location){
        self.location = location
    }
}

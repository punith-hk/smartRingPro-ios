import Foundation
import CoreLocation

class LocationManager: NSObject {
    
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var locationCompletion: ((String, String) -> Void)?
    private var isTracking = false
    private var hasGotInitialLocation = false
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Permission Request
    func requestLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        
        print("[LocationManager] Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            // First time - request "When In Use"
            print("[LocationManager] Requesting 'When In Use' permission...")
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse:
            // Already have "When In Use" - upgrade to "Always"
            print("[LocationManager] Upgrading to 'Always' permission...")
            locationManager.requestAlwaysAuthorization()
            
        case .authorizedAlways:
            // Already have "Always" - start tracking
            print("[LocationManager] ✅ Already have 'Always' permission")
            startTracking()
            
        case .denied, .restricted:
            print("[LocationManager] ❌ Permission denied or restricted")
            showSettingsAlert()
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Start Tracking
    func startTracking() {
        guard !isTracking else {
            print("[LocationManager] ⚠️ Already tracking, skipping duplicate start")
            return
        }
        
        isTracking = true
        hasGotInitialLocation = false  // Reset for new tracking session
        print("[LocationManager] Starting location tracking...")
        
        // ✅ Start significant location changes for background tracking
        locationManager.startMonitoringSignificantLocationChanges()
        print("[LocationManager] ✅ Background monitoring enabled (works even when app is closed)")
        
        // Also get immediate location
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Get Current Location
    func getCurrentLocation(completion: @escaping (String, String) -> Void) {
        self.locationCompletion = completion
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("[LocationManager] Fetching current location...")
            locationManager.requestLocation()
        } else {
            print("[LocationManager] No permission to get location")
            completion("0.0", "0.0")
        }
    }
    
    // MARK: - Save Location Locally
    private func saveLocation(latitude: String, longitude: String) {
        UserDefaults.standard.set(latitude, forKey: "lat")
        UserDefaults.standard.set(longitude, forKey: "lng")
        UserDefaults.standard.set("1", forKey: "location") // Permission granted flag
        
        print("[LocationManager] ✅ Saved location - lat: \(latitude), lng: \(longitude)")
        
        // 📤 Send device status to server after location is saved
        DeviceService.sendDeviceStatus { success, message in
            if success {
                print("[LocationManager] ✅ Device status sent with updated location")
            } else if message == "Throttled" {
                // Throttled is expected behavior, not an error
                print("[LocationManager] ⏭️ API call throttled (will send on next significant movement)")
            } else {
                print("[LocationManager] ❌ Failed to send device status: \(message ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Settings Alert
    private func showSettingsAlert() {
        DispatchQueue.main.async {
            guard let topVC = UIApplication.shared.windows.first?.rootViewController else { return }
            
            let alert = UIAlertController(
                title: "Location Permission Required",
                message: "Please enable location access in Settings to use emergency health monitoring features.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            
            topVC.present(alert, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    // Called when authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = CLLocationManager.authorizationStatus()
        print("[LocationManager] Authorization changed to: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse:
            // Got "When In Use" - now request "Always"
            print("[LocationManager] Got 'When In Use', requesting 'Always'...")
            locationManager.requestAlwaysAuthorization()
            
        case .authorizedAlways:
            // Got "Always" - start tracking
            print("[LocationManager] ✅ Got 'Always' permission, starting tracking")
            startTracking()
            
        case .denied, .restricted:
            print("[LocationManager] ❌ Permission denied")
            isTracking = false
            hasGotInitialLocation = false
            UserDefaults.standard.set("0", forKey: "location")
            
        default:
            break
        }
    }
    
    // Called when location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let latitude = String(format: "%.6f", location.coordinate.latitude)
        let longitude = String(format: "%.6f", location.coordinate.longitude)
        
        // Only process first precise GPS update on app launch
        if !hasGotInitialLocation {
            hasGotInitialLocation = true
            print("[LocationManager] 📍 Initial location - lat: \(latitude), lng: \(longitude)")
            
            // Save to UserDefaults
            saveLocation(latitude: latitude, longitude: longitude)
            
            // Stop precise GPS after first update (save battery)
            locationManager.stopUpdatingLocation()
            print("[LocationManager] Stopped precise GPS (background monitoring continues)")
            
            // Call completion handler if exists
            if let completion = locationCompletion {
                completion(latitude, longitude)
                locationCompletion = nil
            }
        } else {
            // Subsequent updates from background monitoring (significant changes)
            print("[LocationManager] 🔄 Background update - lat: \(latitude), lng: \(longitude)")
            saveLocation(latitude: latitude, longitude: longitude)
        }
    }
    
    // Called on error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] ❌ Error: \(error.localizedDescription)")
        
        // Return default values
        locationCompletion?("0.0", "0.0")
        locationCompletion = nil
    }
}

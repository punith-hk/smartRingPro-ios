//
//  DeviceService.swift
//  YCProductSDK
//
//  Created by admin1 on 22/12/25.
//

import Foundation

/// Service for device-related API calls
class DeviceService {
    
    // MARK: - Debouncing
    private static var lastAPICallTime: Date?
    private static let minimumAPICallInterval: TimeInterval = 30 // seconds
    
    /// Send device status to server
    /// POST /api/user-app-details
    static func sendDeviceStatus(completion: @escaping (Bool, String?) -> Void) {
        
        // ⏱️ Debounce: Check if enough time has passed since last call
        if let lastCall = lastAPICallTime {
            let timeSinceLastCall = Date().timeIntervalSince(lastCall)
            if timeSinceLastCall < minimumAPICallInterval {
                print("[DeviceService] ⏭️ Skipping API call (called \(Int(timeSinceLastCall))s ago, min interval: \(Int(minimumAPICallInterval))s)")
                completion(false, "Throttled")
                return
            }
        }
        
        let userId = UserDefaultsManager.shared.userId
        
        guard userId > 0 else {
            print("[DeviceService] ❌ No user ID found")
            completion(false, "User not logged in")
            return
        }
        
        // Collect all device data
        let latitude = UserDefaults.standard.string(forKey: "lat") ?? "0.0"
        let longitude = UserDefaults.standard.string(forKey: "lng") ?? "0.0"
        let location = UserDefaults.standard.string(forKey: "location") ?? "0"
        
        let request = DeviceStatusRequest(
            user_id: String(userId),
            app_version: DeviceInfoManager.shared.getAppVersion(),
            battery: DeviceInfoManager.shared.getBattery(),
            bluetooth: DeviceInfoManager.shared.getBluetooth(),
            firmware_version: DeviceInfoManager.shared.getFirmwareVersion(),
            latitude: latitude,
            location: location,
            longitude: longitude,
            os: 0, // iOS
            ring: DeviceInfoManager.shared.getRing(),
            status: DeviceInfoManager.shared.getStatus(),
            version: DeviceInfoManager.shared.getOSVersion()
        )
        
        print("[DeviceService] 📤 Sending device status:")
        print("  - User ID: \(request.user_id)")
        print("  - App Version: \(request.app_version)")
        print("  - Battery: \(request.battery)%")
        print("  - Bluetooth: \(request.bluetooth)")
        print("  - Firmware: \(request.firmware_version)")
        print("  - Location: \(request.latitude), \(request.longitude)")
        print("  - Ring: \(request.ring)")
        print("  - Status: \(request.status)")
        print("  - iOS Version: \(request.version)")
        
        // Update last call time BEFORE making request (prevents race conditions)
        lastAPICallTime = Date()
        
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.deviceStatus,
            body: request,
            responseType: DeviceStatusResponse.self
        ) { result in
            
            switch result {
            case .success(let response):
                print("[DeviceService] ✅ Device status sent successfully")
                if let message = response.message {
                    print("[DeviceService] Response: \(message)")
                }
                completion(true, response.message)
                
            case .failure(let error):
                print("[DeviceService] ❌ Failed to send device status: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            }
        }
    }
    
    /// Force send device status (bypasses throttling) - Use for critical events like connect/disconnect
    static func forceSendDeviceStatus(completion: @escaping (Bool, String?) -> Void) {
        lastAPICallTime = nil // Reset throttle
        sendDeviceStatus(completion: completion)
    }
}

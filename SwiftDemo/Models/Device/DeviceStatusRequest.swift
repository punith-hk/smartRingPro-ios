import Foundation

/// Request model for sending device status to API
struct DeviceStatusRequest: Codable {
    let user_id: String
    let app_version: String
    let battery: String
    let bluetooth: String        // "1" = on, "0" = off
    let firmware_version: String
    let latitude: String
    let location: String         // "1" = granted, "0" = denied
    let longitude: String
    let os: Int                  // 0 = iOS, 1 = Android
    let ring: String             // "1" = connected, "0" = disconnected
    let status: String           // "Connected" / "Disconnected"
    let version: String          // iOS version
}

/// Response model for device status API
struct DeviceStatusResponse: Codable {
    let success: Bool?
    let message: String?
}

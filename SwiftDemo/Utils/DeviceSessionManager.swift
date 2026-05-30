import Foundation
import YCProductSDK

final class DeviceSessionManager {

    static let shared = DeviceSessionManager()
    private init() {}

    private let macKey = "connectedDeviceMac"
    private let nameKey = "connectedDeviceName"

    func saveConnectedDevice(mac: String, name: String) {
        UserDefaults.standard.set(mac, forKey: macKey)
        UserDefaults.standard.set(name, forKey: nameKey)
    }

    func clearDevice() {
        UserDefaults.standard.removeObject(forKey: macKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
    }

    /// Returns true if a device has been saved (not necessarily connected)
    func isDeviceConnected() -> Bool {
        return connectedDeviceMac() != nil
    }
    
    /// Check if device is actually connected via BLE (not just saved)
    func isDeviceActuallyConnected() -> Bool {
        guard let savedMac = connectedDeviceMac() else { return false }
        guard let currentPeripheral = YCProduct.shared.currentPeripheral else { return false }
        return currentPeripheral.macAddress.uppercased() == savedMac.uppercased()
    }

    func connectedDeviceMac() -> String? {
        UserDefaults.standard.string(forKey: macKey)
    }

    func connectedDeviceName() -> String? {
        UserDefaults.standard.string(forKey: nameKey)
    }
}

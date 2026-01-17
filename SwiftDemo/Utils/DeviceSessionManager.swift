import Foundation

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

    func isDeviceConnected() -> Bool {
        return connectedDeviceMac() != nil
    }

    func connectedDeviceMac() -> String? {
        UserDefaults.standard.string(forKey: macKey)
    }

    func connectedDeviceName() -> String? {
        UserDefaults.standard.string(forKey: nameKey)
    }
}

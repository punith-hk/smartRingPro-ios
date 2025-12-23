import Foundation

final class DeviceSessionManager {

    static let shared = DeviceSessionManager()
    private init() {}

    private let key = "connectedDeviceMac"

    func saveConnectedDevice(mac: String) {
        UserDefaults.standard.set(mac, forKey: key)
    }

    func clearDevice() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func isDeviceConnected() -> Bool {
        return UserDefaults.standard.string(forKey: key) != nil
    }

    func connectedDeviceMac() -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
}

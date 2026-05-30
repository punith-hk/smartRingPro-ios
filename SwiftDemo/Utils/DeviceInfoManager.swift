import Foundation
import UIKit
import CoreBluetooth
import UserNotifications
import YCProductSDK

/// Manages device-related information for API uploads
final class DeviceInfoManager {
    
    static let shared = DeviceInfoManager()
    private init() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let battery = "device_battery"
        static let bluetooth = "device_bluetooth"
        static let firmwareVersion = "device_firmware_version"
        static let ring = "device_ring"
        static let status = "device_status"
        static let appVersion = "device_app_version"
        static let osVersion = "device_os_version"
    }
    
    // MARK: - Save Methods
    
    /// Save battery level (0-100)
    func saveBattery(_ level: Int) {
        UserDefaults.standard.set(String(level), forKey: Keys.battery)
        print("[DeviceInfoManager] 🔋 Saved battery: \(level)%")
        
        // Check for low battery and show notification
        checkLowBatteryAndNotify(level: level)
    }
    
    /// Save Bluetooth status ("1" = on, "0" = off)
    func saveBluetoothStatus(_ isOn: Bool) {
        UserDefaults.standard.set(isOn ? "1" : "0", forKey: Keys.bluetooth)
        print("[DeviceInfoManager] 📶 Saved bluetooth: \(isOn ? "ON" : "OFF")")
    }
    
    /// Save firmware version
    func saveFirmwareVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: Keys.firmwareVersion)
        print("[DeviceInfoManager] 💾 Saved firmware: \(version)")
    }
    
    /// Save ring connection status ("1" = connected, "0" = disconnected)
    func saveRingStatus(_ isConnected: Bool) {
        UserDefaults.standard.set(isConnected ? "1" : "0", forKey: Keys.ring)
        print("[DeviceInfoManager] 💍 Saved ring status: \(isConnected ? "Connected" : "Disconnected")")
    }
    
    /// Save device connection status text
    func saveConnectionStatus(_ status: String) {
        UserDefaults.standard.set(status, forKey: Keys.status)
        print("[DeviceInfoManager] ✅ Saved status: \(status)")
    }
    
    /// Save app version (called once at app launch)
    func saveAppVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        UserDefaults.standard.set(version, forKey: Keys.appVersion)
        print("[DeviceInfoManager] 📱 Saved app version: \(version)")
    }
    
    /// Save iOS version (called once at app launch)
    func saveOSVersion() {
        let version = UIDevice.current.systemVersion
        UserDefaults.standard.set(version, forKey: Keys.osVersion)
        print("[DeviceInfoManager] 🍎 Saved iOS version: \(version)")
    }
    
    // MARK: - Low Battery Notification
    
    /// Check battery level and show notification if below 20%
    private func checkLowBatteryAndNotify(level: Int) {
        // Only notify if battery is below 20%
        guard level <= 20 else { return }
        
        // Check if we already notified recently (prevent spam)
        let lastNotificationKey = "lastLowBatteryNotification"
        if let lastNotification = UserDefaults.standard.object(forKey: lastNotificationKey) as? Date {
            let hoursSinceLastNotification = Date().timeIntervalSince(lastNotification) / 3600
            // Only notify once every 6 hours
            if hoursSinceLastNotification < 6 {
                print("[DeviceInfoManager] ⏭️ Low battery notification already sent recently")
                return
            }
        }
        
        // Show notification
        showLowBatteryNotification(level: level)
        
        // Save notification time
        UserDefaults.standard.set(Date(), forKey: lastNotificationKey)
    }
    
    /// Show local notification for low battery
    private func showLowBatteryNotification(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Ring Battery Low"
        content.body = "Your smart ring battery is at \(level)%. Please charge soon."
        content.sound = .default
        content.badge = 1
        
        // Add action buttons
        let chargeAction = UNNotificationAction(
            identifier: "CHARGE_ACTION",
            title: "OK",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "LOW_BATTERY",
            actions: [chargeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "LOW_BATTERY"
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "ring_low_battery_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[DeviceInfoManager] ❌ Failed to show notification: \(error.localizedDescription)")
            } else {
                print("[DeviceInfoManager] 🔔 Low battery notification sent (\(level)%)")
            }
        }
    }
    
    // MARK: - Get Methods
    
    /// Get current battery level from device
    func getCurrentBatteryLevel() -> String {
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            return "100" // Unknown state, default to 100
        }
        return String(Int(level * 100))
    }
    
    /// Get battery from UserDefaults
    func getBattery() -> String {
        return UserDefaults.standard.string(forKey: Keys.battery) ?? getCurrentBatteryLevel()
    }
    
    /// Get Bluetooth status
    func getBluetooth() -> String {
        return UserDefaults.standard.string(forKey: Keys.bluetooth) ?? "0"
    }
    
    /// Get firmware version
    func getFirmwareVersion() -> String {
        return UserDefaults.standard.string(forKey: Keys.firmwareVersion) ?? "0.0"
    }
    
    /// Get ring connection status
    func getRing() -> String {
        return UserDefaults.standard.string(forKey: Keys.ring) ?? "0"
    }
    
    /// Get connection status text
    func getStatus() -> String {
        return UserDefaults.standard.string(forKey: Keys.status) ?? "Disconnected"
    }
    
    /// Get app version
    func getAppVersion() -> String {
        return UserDefaults.standard.string(forKey: Keys.appVersion) ?? "1.0.0"
    }
    
    /// Get OS version
    func getOSVersion() -> String {
        return UserDefaults.standard.string(forKey: Keys.osVersion) ?? UIDevice.current.systemVersion
    }
    
    // MARK: - Update All Device Info
    
    /// Update all device info at once (call when device connects)
    func updateAllDeviceInfo(batteryLevel: Int?, firmwareVersion: String?, isRingConnected: Bool, bluetoothOn: Bool) {
        
        // Battery
        if let battery = batteryLevel {
            saveBattery(battery)
        } else {
            // Get from device
            let currentBattery = getCurrentBatteryLevel()
            UserDefaults.standard.set(currentBattery, forKey: Keys.battery)
        }
        
        // Firmware
        if let firmware = firmwareVersion {
            saveFirmwareVersion(firmware)
        }
        
        // Ring & Status
        saveRingStatus(isRingConnected)
        saveConnectionStatus(isRingConnected ? "Connected" : "Disconnected")
        
        // Bluetooth
        saveBluetoothStatus(bluetoothOn)
        
        print("[DeviceInfoManager] ✅ Updated all device info")
    }
    
    /// Update when device disconnects
    func handleDeviceDisconnect() {
        saveRingStatus(false)
        saveConnectionStatus("Disconnected")
        print("[DeviceInfoManager] ❌ Device disconnected")
    }
    
    // MARK: - Initialize Static Data (call at app launch)
    func initializeStaticInfo() {
        saveAppVersion()
        saveOSVersion()
    }
}

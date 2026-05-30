import UIKit
import YCProductSDK
import CoreBluetooth

/// Centralized BLE connection state manager for the entire app
/// This manager maintains the current BLE connection state and notifies observers
class BLEStateManager: NSObject {
    
    static let shared = BLEStateManager()
    
    // MARK: - Public State
    private(set) var currentState: YCProductState = .poweredOff
    private(set) var isConnected: Bool = false
    
    // MARK: - Bluetooth State Monitoring
    private var centralManager: CBCentralManager!
    private(set) var isBluetoothOn: Bool = false
    
    // MARK: - Observers
    var onStateChanged: ((YCProductState) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setupBLENotificationListener()
        checkInitialState()
        print("✅ BLEStateManager initialized with state: \(currentState), isConnected: \(isConnected)")
    }
    
    // MARK: - Setup
    private func checkInitialState() {
        // Check if there's already a connected device at init time
        if YCProduct.shared.currentPeripheral != nil {
            currentState = .connected
            isConnected = true
            print("🟢 BLEStateManager: Found connected device at init")
        } else {
            print("⚪ BLEStateManager: No connected device at init")
        }
    }
    
    private func setupBLENotificationListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBLEStateChanged(_:)),
            name: YCProduct.deviceStateNotification,
            object: nil
        )
        print("🔔 BLEStateManager: Notification listener registered")
    }
    
    // MARK: - Notification Handler
    @objc private func onBLEStateChanged(_ notification: Notification) {
        guard
            let info = notification.userInfo as? [String: Any],
            let state = info[YCProduct.connecteStateKey] as? YCProductState
        else {
            print("❌ BLEStateManager: Failed to extract state from notification")
            return
        }
        
        print("🔵 BLEStateManager - State changed to: \(state)")
        
        currentState = state
        isConnected = (state == .connected)
        
        // Call callbacks
        onStateChanged?(state)
        
        switch state {
        case .connected:
            print("✅ BLEStateManager: Device CONNECTED")
            
            // 💾 Save ring connection status
            DeviceInfoManager.shared.saveRingStatus(true)
            DeviceInfoManager.shared.saveConnectionStatus("Connected")
            
            // 📤 FORCE send device status (critical event - bypass throttle)
            DeviceService.forceSendDeviceStatus { success, message in
                if success {
                    print("✅ BLEStateManager: Device status sent on connect")
                } else {
                    print("❌ BLEStateManager: Failed to send device status: \(message ?? "Unknown error")")
                }
            }
            
            onConnected?()
            
        case .disconnected, .connectedFailed:
            print("❌ BLEStateManager: Device DISCONNECTED/FAILED")
            
            // 💾 Save disconnected status
            DeviceInfoManager.shared.handleDeviceDisconnect()
            
            // 📤 FORCE send device status (critical event - bypass throttle)
            DeviceService.forceSendDeviceStatus { success, message in
                if success {
                    print("✅ BLEStateManager: Device status sent on disconnect")
                }
            }
            
            onDisconnected?()
            
        default:
            print("ℹ️ BLEStateManager: Other state - \(state)")
        }
    }
    
    // MARK: - Public Methods
    func hasConnectedDevice() -> Bool {
        return YCProduct.shared.currentPeripheral != nil
    }
    
    func debugInfo() -> String {
        return """
        BLEStateManager Debug Info:
        - currentState: \(currentState)
        - isConnected: \(isConnected)
        - hasConnectedDevice(): \(hasConnectedDevice())
        - Bluetooth ON: \(isBluetoothOn)
        - YCProduct.shared.currentPeripheral: \(YCProduct.shared.currentPeripheral != nil ? "EXISTS" : "NIL")
        - Peripheral name: \(YCProduct.shared.currentPeripheral?.name ?? "N/A")
        - Peripheral mac: \(YCProduct.shared.currentPeripheral?.macAddress ?? "N/A")
        """
    }
    
}

// MARK: - CBCentralManagerDelegate
extension BLEStateManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothOn = true
            DeviceInfoManager.shared.saveBluetoothStatus(true)
            print("📶 BLEStateManager: Bluetooth is ON")
            
        case .poweredOff:
            isBluetoothOn = false
            DeviceInfoManager.shared.saveBluetoothStatus(false)
            print("📵 BLEStateManager: Bluetooth is OFF")
            
        case .unauthorized:
            isBluetoothOn = false
            DeviceInfoManager.shared.saveBluetoothStatus(false)
            print("⚠️ BLEStateManager: Bluetooth unauthorized")
            
        default:
            isBluetoothOn = false
            DeviceInfoManager.shared.saveBluetoothStatus(false)
            print("ℹ️ BLEStateManager: Bluetooth state - \(central.state.rawValue)")
        }
    }
}

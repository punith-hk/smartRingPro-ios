import UIKit
import YCProductSDK

/// Centralized BLE connection state manager for the entire app
/// This manager maintains the current BLE connection state and notifies observers
class BLEStateManager {
    
    static let shared = BLEStateManager()
    
    // MARK: - Public State
    private(set) var currentState: YCProductState = .poweredOff
    private(set) var isConnected: Bool = false
    
    // MARK: - Observers
    var onStateChanged: ((YCProductState) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    
    private init() {
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
            onConnected?()
        case .disconnected, .connectedFailed:
            print("❌ BLEStateManager: Device DISCONNECTED/FAILED")
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
        - YCProduct.shared.currentPeripheral: \(YCProduct.shared.currentPeripheral != nil ? "EXISTS" : "NIL")
        - Peripheral name: \(YCProduct.shared.currentPeripheral?.name ?? "N/A")
        - Peripheral mac: \(YCProduct.shared.currentPeripheral?.macAddress ?? "N/A")
        """
    }
    
}

//
//  SceneDelegate.swift
//  SwiftDemo
//

import UIKit
import YCProductSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // 🔒 BLE bootstrap flag (process-lifetime)
    private var bleInitialized = false

    // MARK: - Scene Entry
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.overrideUserInterfaceStyle = .light

        // 🔁 Decide root WITHOUT initializing BLE
        if UserDefaultsManager.shared.isLoggedIn() {
            initializeBLEIfNeeded()   // ✅ BLE init only if logged in
            window.rootViewController = SideMenuContainerController()
        } else {
            let nav = UINavigationController(rootViewController: LoginViewController())
            window.rootViewController = nav
        }

        window.makeKeyAndVisible()
    }

    // MARK: - BLE Initialization (ONE TIME)
    private func initializeBLEIfNeeded() {

        guard !bleInitialized else {
            print("ℹ️ BLE already initialized, skipping")
            return
        }

        // 🔊 SDK logging (adjust later if needed)
        #if DEBUG
        YCProduct.setLogLevel(.normal, saveLevel: .error)
        #else
        YCProduct.setLogLevel(.off, saveLevel: .off)
        #endif

        // 🔥 FORCE SDK + BLE INIT
        _ = YCProduct.shared

        // 🔔 Observe BLE state globally
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceStateChanged(_:)),
            name: YCProduct.deviceStateNotification,
            object: nil
        )

        bleInitialized = true
        print("✅ BLE SDK initialized after login")
    }

    // MARK: - Global BLE State Listener
    @objc private func deviceStateChanged(_ notification: Notification) {

        guard
            let info = notification.userInfo as? [String: Any],
            let state = info[YCProduct.connecteStateKey] as? YCProductState
        else { return }

        print("🔵 BLE STATE:", state)

        switch state {
        case .poweredOn:
            print("Bluetooth ON")

        case .poweredOff:
            print("Bluetooth OFF")

        case .connected:
            print("Device CONNECTED")

        case .disconnected:
            print("Device DISCONNECTED")

        case .connectedFailed:
            print("Connection FAILED")

        default:
            break
        }
    }

    // MARK: - Post Login Routing
    func setHomeAsRoot() {
        guard let window = window else { return }

        // 🔥 BLE INIT HAPPENS HERE AFTER LOGIN
        initializeBLEIfNeeded()

        let root = SideMenuContainerController()
        window.rootViewController = root
        window.makeKeyAndVisible()
    }

    // MARK: - Generic Root Switch
    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {

        guard let window = self.window else { return }

        if animated {
            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    window.rootViewController = viewController
                },
                completion: nil
            )
        } else {
            window.rootViewController = viewController
        }

        window.makeKeyAndVisible()
    }

    // MARK: - Scene Lifecycle (optional hooks)
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

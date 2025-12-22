//
//  SceneDelegate.swift
//  SwiftDemo
//
//  Created by macos on 2021/11/29.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
//        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
//        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        guard let _ = (scene as? UIWindowScene) else { return }
//        
//        window?.overrideUserInterfaceStyle = .light
//    }
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.overrideUserInterfaceStyle = .light

        // ✅ CHECK LOGIN STATE
        if UserDefaultsManager.shared.isLoggedIn() {
            // User already logged in → go to Home
            window.rootViewController = SideMenuContainerController()

        } else {
            // User not logged in → show Login
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            window.rootViewController = nav
        }

        window.makeKeyAndVisible()
    }
    
    func setHomeAsRoot() {
        guard let window = window else { return }
        let root = SideMenuContainerController()
        window.rootViewController = root
        window.makeKeyAndVisible()
    }

    
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


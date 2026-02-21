//
//  AppDelegate.swift
//  SwiftDemo
//
//  Created by macos on 2021/11/29.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Core Data
        _ = CoreDataManager.shared.persistentContainer
        print("✅ AppDelegate - Core Data initialized")
        
        // Set notification center delegate for foreground notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Configure Firebase (only if GoogleService-Info.plist exists)
        if let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            FirebaseApp.configure()
            print("✅ AppDelegate - Firebase configured")
            
            // Set FCM messaging delegate
            Messaging.messaging().delegate = self
            
            // Request notification permissions
            FCMService.requestNotificationPermissions { granted in
                if granted {
                    print("✅ AppDelegate - Notification permissions granted")
                } else {
                    print("⚠️ AppDelegate - Notification permissions denied")
                }
            }
        } else {
            print("⚠️ AppDelegate - GoogleService-Info.plist not found. Please add it from Firebase Console.")
            print("   Download from: https://console.firebase.google.com")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Save Core Data changes before app terminates
        CoreDataManager.shared.saveContext()
        print("✅ AppDelegate - Core Data saved on termination")
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass APNS token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        print("✅ AppDelegate - APNS token registered with Firebase")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ AppDelegate - Failed to register for remote notifications: \(error.localizedDescription)")
    }

}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("❌ AppDelegate - FCM token is nil")
            return
        }
        
        print("✅ AppDelegate - FCM token received: \(fcmToken.prefix(30))...")
        
        // Save token locally
        FCMService.saveFCMToken(fcmToken)
        
        // Send to server if user is logged in
        if UserDefaultsManager.shared.isLoggedIn() {
            let userId = UserDefaultsManager.shared.fcmUserId  // Use actual user_id for FCM
            print("📤 AppDelegate - Sending FCM token for logged in user (ID: \(userId))")
            
            FCMService.forceSendTokenToServer { success, message in
                if success {
                    print("✅ AppDelegate - FCM token sent to server")
                } else {
                    print("❌ AppDelegate - Failed to send FCM token: \(message ?? "unknown error")")
                }
            }
        } else {
            print("⏭️ AppDelegate - User not logged in, token will be sent after login")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in FOREGROUND
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 AppDelegate - Notification received in foreground")
        
        // Show alert, sound, and badge even when app is in foreground
        // Using .alert for iOS 13 compatibility (iOS 14+ uses .banner)
        completionHandler([.alert, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 AppDelegate - Notification tapped")
        
        let userInfo = response.notification.request.content.userInfo
        print("Notification data: \(userInfo)")
        
        // Handle different notification types here
        if response.notification.request.identifier.contains("ring_low_battery") {
            print("📱 Low battery notification tapped")
            // Navigate to device screen if needed
        }
        
        completionHandler()
    }
}


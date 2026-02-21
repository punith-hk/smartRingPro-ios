import Foundation
import UIKit
import Firebase
import FirebaseMessaging

/// Service for Firebase Cloud Messaging token management
class FCMService {
    
    // MARK: - Firebase Check
    
    /// Check if Firebase is configured
    private static func isFirebaseConfigured() -> Bool {
        return FirebaseApp.app() != nil
    }
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let fcmToken = "fcm_token"
        static let tokenSent = "fcm_token_sent"
    }
    
    // MARK: - Save Token Locally
    
    /// Save FCM token to UserDefaults
    static func saveFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: Keys.fcmToken)
        print("[FCMService] 💾 Saved FCM token: \(token.prefix(20))...")
    }
    
    /// Get saved FCM token from Firebase Messaging
    static func getSavedFCMToken() -> String? {
        // First try to get from Firebase Messaging (if configured)
        if isFirebaseConfigured(), let firebaseToken = Messaging.messaging().fcmToken {
            return firebaseToken
        }
        // Fallback to UserDefaults
        return UserDefaults.standard.string(forKey: Keys.fcmToken)
    }
    
    /// Mark token as sent to server
    static func markTokenAsSent() {
        UserDefaults.standard.set(true, forKey: Keys.tokenSent)
    }
    
    /// Check if token was sent to server
    static func isTokenSent() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.tokenSent)
    }
    
    /// Reset token sent flag (call when token refreshes)
    static func resetTokenSentFlag() {
        UserDefaults.standard.set(false, forKey: Keys.tokenSent)
    }
    
    // MARK: - Send Token to Server
    
    /// Send FCM token to backend API
    /// POST /api/user/fcm-token
    static func sendTokenToServer(completion: @escaping (Bool, String?) -> Void) {
        
        guard let token = getSavedFCMToken(), !token.isEmpty else {
            print("[FCMService] ❌ No FCM token available")
            completion(false, "No FCM token")
            return
        }
        
        guard UserDefaultsManager.shared.isLoggedIn() else {
            print("[FCMService] ❌ User not logged in")
            completion(false, "User not logged in")
            return
        }
        
        let userId = UserDefaultsManager.shared.fcmUserId  // Use actual user_id for FCM
        guard userId > 0 else {
            print("[FCMService] ❌ Invalid user ID")
            completion(false, "Invalid user ID")
            return
        }
        
        // Check if already sent (avoid duplicate calls)
        if isTokenSent() {
            print("[FCMService] ⏭️ Token already sent to server")
            completion(true, "Already sent")
            return
        }
        
        let request = FCMTokenRequest(
            fcm_token: token,
            user_id: String(userId)
        )
        
        print("[FCMService] 📤 Sending FCM token to server")
        print("  - User ID: \(userId)")
        print("  - Token: \(token.prefix(30))...")
        
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.fcmToken,
            body: request,
            responseType: FCMTokenResponse.self
        ) { result in
            
            switch result {
            case .success(let response):
                print("[FCMService] ✅ FCM token sent successfully")
                if let message = response.message {
                    print("[FCMService] Response: \(message)")
                }
                markTokenAsSent()
                completion(true, response.message)
                
            case .failure(let error):
                print("[FCMService] ❌ Failed to send FCM token: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            }
        }
    }
    
    /// Force send token (useful for token refresh)
    static func forceSendTokenToServer(completion: @escaping (Bool, String?) -> Void) {
        resetTokenSentFlag()
        sendTokenToServer(completion: completion)
    }
    
    // MARK: - Request Notification Permissions
    
    /// Request notification permissions from user
    static func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("[FCMService] ✅ Notification permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    completion(true)
                } else {
                    print("[FCMService] ❌ Notification permission denied")
                    if let error = error {
                        print("[FCMService] Error: \(error.localizedDescription)")
                    }
                    completion(false)
                }
            }
        }
    }
    
    /// Check current notification permission status
    static func checkNotificationPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
}

// MARK: - TODO: Add Firebase Integration
/*
 To add real Firebase FCM:
 
 1. Add Firebase via Swift Package Manager in Xcode:
    - File → Add Package Dependencies
    - URL: https://github.com/firebase/firebase-ios-sdk
    - Add: FirebaseCore, FirebaseMessaging
 
 2. Add GoogleService-Info.plist to project
 
 3. In AppDelegate, add:
    import Firebase
    import FirebaseMessaging
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    extension AppDelegate: MessagingDelegate {
        func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
            FCMService.saveFCMToken(fcmToken ?? "")
            FCMService.forceSendTokenToServer { _, _ in }
        }
    }
 
 4. Replace getSavedFCMToken() to use real Firebase token
 */

import Foundation

/// Request model for sending FCM token to server
struct FCMTokenRequest: Codable {
    let fcm_token: String
    let user_id: String
}

/// Response model for FCM token API
struct FCMTokenResponse: Codable {
    let message: String?
    let data: FCMTokenData?
}

struct FCMTokenData: Codable {
    let id: Int
    let user_id: Int  // Server returns int 168
    let fcm_token: String
    let created_at: String?
    let updated_at: String?
}

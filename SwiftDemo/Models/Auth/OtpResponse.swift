import Foundation

struct OtpResponse: Codable {
    let response: Int
    let message: String?
    let user: String?
    let email: String?
    let role_code: String?
    let mobile_number: String?
    let id: Int?           // Session/record ID
    let user_id: Int?      // Actual user ID
    let tokenData: TokenData?
}

struct TokenData: Codable {
    let access_token: String?
    let token_type: String?
    let expires_at: String?
}

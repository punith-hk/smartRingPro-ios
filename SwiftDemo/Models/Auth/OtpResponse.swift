import Foundation

struct OtpResponse: Codable {
    let response: Int
    let message: String?
    let accessToken: String?
    let user: String?
    let email: String?
    let role_code: String?
    let mobile_number: String?
    let id: Int?           // Session/record ID
    let user_id: Int?      // Actual user ID (this is what we need!)
}

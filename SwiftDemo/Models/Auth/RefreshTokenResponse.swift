import Foundation

struct RefreshTokenResponse: Codable {
    let response: Int?
    let access_token: String?
    let token_type: String?
    let expires_at: String?
}

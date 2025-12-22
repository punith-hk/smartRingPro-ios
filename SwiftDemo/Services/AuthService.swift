import Foundation

final class AuthService {

    static let shared = AuthService()
    private init() {}

    func login(
        mobile: String,
        completion: @escaping (Result<LoginResponse, NetworkError>) -> Void
    ) {
        let body = ["mobile_number": mobile]

        APIClient.shared.post(
            endpoint: APIEndpoints.login,
            body: body,
            responseType: LoginResponse.self,
            completion: completion
        )
    }
    
    func verifyOtp(
        userId: Int?,
        otp: String,
        completion: @escaping (Result<OtpResponse, NetworkError>) -> Void
    ) {
        let body: [String: Any] = [
            "user_id": userId ?? 0,
            "otp": otp
        ]

        APIClient.shared.post(
            endpoint: APIEndpoints.verifyOtp,
            body: body,
            responseType: OtpResponse.self,
            completion: completion
        )
    }
    
    func register(
        mobile: String,
        name: String,
        completion: @escaping (Result<RegisterResponse, NetworkError>) -> Void
    ) {
        let body: [String: Any] = [
            "mobile_number": mobile,
            "name": name
        ]

        APIClient.shared.post(
            endpoint: APIEndpoints.register,
            body: body,
            responseType: RegisterResponse.self,
            completion: completion
        )
    }


}

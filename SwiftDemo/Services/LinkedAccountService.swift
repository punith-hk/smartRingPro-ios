import Foundation

final class LinkedAccountService {

    static let shared = LinkedAccountService()
    private init() {}

    // MARK: - Get Linked Accounts
    func getLinkedAccountData(
        userId: Int,
        completion: @escaping (Result<[LinkedAccountInfo], NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.getLinkedAccounts(userId: userId),
            responseType: [LinkedAccountInfo].self,
            completion: completion
        )
    }

    // MARK: - Add Linked Account (Request OTP)
    func addLinkedAccount(
        userId: Int,
        phoneNumber: String,
        completion: @escaping (Result<AddLinkedAccountResponse, NetworkError>) -> Void
    ) {
        let body = CaretakerRequestBody(
            user_id: userId,
            phone_number: phoneNumber
        )

        APIClient.shared.postJSON(
            endpoint: APIEndpoints.addLinkedAccount,
            body: body,
            responseType: AddLinkedAccountResponse.self,
            completion: completion
        )
    }

    // MARK: - Verify Caretaker OTP
    func verifyCaretakerOtp(
        userId: Int,
        receiverId: Int,
        otp: Int,
        relation: String,
        completion: @escaping (Result<CaretakerVerifyOtpResponse, NetworkError>) -> Void
    ) {
        let body = CaretakerVerifyOtpRequestBody(
            user_id: userId,
            receiver_id: receiverId,
            otp: otp,
            relation: relation
        )

        APIClient.shared.postJSON(
            endpoint: APIEndpoints.verifyCaretakerOtp,
            body: body,
            responseType: CaretakerVerifyOtpResponse.self,
            completion: completion
        )
    }

    // MARK: - Get Last Ring Data
    func getLastRingData(
        userId: Int,
        completion: @escaping (Result<LastRingDataResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.lastHealthData(userId: userId),
            responseType: LastRingDataResponse.self,
            completion: completion
        )
    }
}

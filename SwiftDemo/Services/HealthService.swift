import Foundation

final class HealthService {

    static let shared = HealthService()
    private init() {}

    func getLastHealthData(
        userId: Int,
        completion: @escaping (Result<GetLastUserHealthDataResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.get(
            endpoint: APIEndpoints.lastHealthData(userId: userId),
            responseType: GetLastUserHealthDataResponse.self,
            completion: completion
        )
    }
}

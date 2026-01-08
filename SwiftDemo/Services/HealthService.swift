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

// MARK: - Day-wise Ring Data
extension HealthService {
    /// Fetch day-wise ring data for a user and type
    func getRingDataByDay(
        userId: Int,
        type: String,
        completion: @escaping (Result<GetRingDataByDayResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.getRingDataByDay(
                userId: userId,
                type: type
            ),
            responseType: GetRingDataByDayResponse.self,
            completion: completion
        )
    }
}

extension HealthService {

    func getRingDataByType(
        userId: Int,
        type: String,
        selectedDate: String,
        completion: @escaping (Result<GetRingDataByTypeResponse, NetworkError>) -> Void
    ) {

        APIClient.shared.get(
            endpoint: APIEndpoints.getRingDataByType(
                userId: userId,
                type: type,
                selectedDate: selectedDate
            ),
            responseType: GetRingDataByTypeResponse.self,
            completion: completion
        )
    }
}


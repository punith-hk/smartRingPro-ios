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

// MARK: - Upload Ring Data
extension HealthService {
    
    /// Upload batch of health data values to API
    /// - Parameters:
    ///   - userId: User ID
    ///   - type: Type of health data (e.g., "heart_rate", "blood_pressure")
    ///   - values: Array of ring value entries (value + timestamp)
    ///   - completion: Callback with result
    func saveHealthDataBatch(
        userId: Int,
        type: String,
        values: [RingValueEntry],
        completion: @escaping (Result<BatchUploadResponse, NetworkError>) -> Void
    ) {
        let request = CreateRingValuesRequest(
            user_id: userId,
            type: type,
            values: values
        )
        
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.createRingValues,
            body: request,
            responseType: BatchUploadResponse.self,
            completion: completion
        )
    }
    
    /// Upload single health data value to API
    /// - Parameters:
    ///   - userId: User ID
    ///   - type: Type of health data (e.g., "heart_rate", "blood_pressure")
    ///   - value: Value as string
    ///   - timestamp: Unix timestamp in seconds
    ///   - completion: Callback with result
    func saveHealthData(
        userId: Int,
        type: String,
        value: String,
        timestamp: Int64,
        completion: @escaping (Result<AddUserHealthDataResponse, NetworkError>) -> Void
    ) {
        // For GET-style POST (parameters in URL), use empty dictionary
        APIClient.shared.post(
            endpoint: APIEndpoints.createRingValue(
                userId: userId,
                type: type,
                value: value,
                timestamp: timestamp
            ),
            body: [:],
            responseType: AddUserHealthDataResponse.self,
            completion: completion
        )
    }
}

// MARK: - Sleep Data API
extension HealthService {
    
    /// Save sleep session data to API (matching Android saveSleepData)
    /// - Parameters:
    ///   - userId: User ID
    ///   - sleepData: Sleep session with details
    ///   - completion: Callback with result
    func saveSleepData(
        userId: Int,
        sleepData: SleepSessionAPI,
        completion: @escaping (Result<SaveSleepDataResponse, NetworkError>) -> Void
    ) {
        let request = SaveSleepDataRequest(userId: userId, sleepData: sleepData)
        
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.saveSleepData,
            body: request,
            responseType: SaveSleepDataResponse.self,
            completion: completion
        )
    }
    
    /// Fetch sleep data by date range (matching Android getSleepDataByDateWise)
    /// - Parameters:
    ///   - userId: User ID
    ///   - startDate: Start date (yyyy-MM-dd)
    ///   - endDate: End date (yyyy-MM-dd)
    ///   - completion: Callback with result
    func getSleepDataByDateWise(
        userId: Int,
        startDate: String,
        endDate: String,
        completion: @escaping (Result<GetSleepDataResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.getSleepDataByDateWise(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            ),
            responseType: GetSleepDataResponse.self,
            completion: completion
        )
    }
}

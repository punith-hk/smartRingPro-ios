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
    
    /// Upload sleep session data to API (matching Android CreateSleepData)
    /// Sends JSON body directly (not wrapped in request object)
    /// - Parameters:
    ///   - userId: User ID (sent as query parameter)
    ///   - sleepData: Sleep session with details (sent as JSON body)
    ///   - completion: Callback with result
    func saveSleepData(
        userId: Int,
        sleepData: SleepSessionAPI,
        completion: @escaping (Result<SaveSleepDataResponse, NetworkError>) -> Void
    ) {
        // Send sleepData directly as body (not wrapped in request object)
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.createSleepData(userId: userId),
            body: sleepData,
            responseType: SaveSleepDataResponse.self,
            completion: completion
        )
    }
    
    /// Get sleep data for a specific date (matching Android getSleepData)
    /// - Parameters:
    ///   - userId: User ID
    ///   - selectedDate: Date in format "MM/dd/yyyy" (e.g., "01/30/2026")
    ///   - completion: Callback with result
    func getSleepData(
        userId: Int,
        selectedDate: String,
        completion: @escaping (Result<SleepDataResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.getSleepData(userId: userId, selectedDate: selectedDate),
            responseType: SleepDataResponse.self,
            completion: completion
        )
    }
    
    /// Get sleep data for a date range (matching Android getSleepDataByDateWise)
    /// Used for weekly/monthly charts
    /// - Parameters:
    ///   - userId: User ID
    ///   - startDate: Start date in format "MM/dd/yyyy"
    ///   - endDate: End date in format "MM/dd/yyyy"
    ///   - completion: Callback with result
    func getSleepDataByDateRange(
        userId: Int,
        startDate: String,
        endDate: String,
        completion: @escaping (Result<SleepDataResponse, NetworkError>) -> Void
    ) {
        print("📊 [HealthService] Getting sleep data for range: \(startDate) - \(endDate)")
        print("   URL: getSleepData?user_id=\(userId)&startDate=\(startDate)&endDate=\(endDate)")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getSleepDataByDateRange(userId: userId, startDate: startDate, endDate: endDate),
            responseType: SleepDataResponse.self
        ) { result in
            switch result {
            case .success(let response):
                let sessionCount = response.data?.count ?? 0
                print("✅ [HealthService] Got \(sessionCount) session(s) for range \(startDate) - \(endDate)")
                
                // Log each session summary
                if let sessions = response.data {
                    for (index, session) in sessions.enumerated() {
                        let totalMinutes = session.totalTimes / 60
                        let deepMinutes = session.deepSleepTimes / 60
                        let lightMinutes = session.lightSleepTimes / 60
                        let awakeMinutes = session.wakeupTimes / 60
                        
                        // Calculate REM from sleep_details
                        let remMinutes = session.sleep_details
                            .filter { $0.sleepType == 4 } // REM type
                            .reduce(0) { $0 + Int(($1.endTime - $1.startTime) / 60) }
                        
                        print("   Session \(index + 1): \(session.startSleepHour):\(String(format: "%02d", session.startSleepMinute)) - \(session.endSleepHour):\(String(format: "%02d", session.endSleepMinute))")
                        print("     Total: \(totalMinutes)min | Deep: \(deepMinutes)min | Light: \(lightMinutes)min | REM: \(remMinutes)min | Awake: \(awakeMinutes)min")
                        print("     Details: \(session.sleep_details.count) segments")
                    }
                }
                
                completion(result)
                
            case .failure(let error):
                print("❌ [HealthService] Failed to get sleep data: \(error.localizedDescription)")
                completion(result)
            }
        }
    }
    
    /// Get all sleep sessions (summaries only, no details)
    /// - Parameters:
    ///   - userId: User ID
    ///   - completion: Callback with result
    func getSleepSessions(
        userId: Int,
        completion: @escaping (Result<SleepSessionsResponse, NetworkError>) -> Void
    ) {
        APIClient.shared.get(
            endpoint: APIEndpoints.getSleepSessions(userId: userId),
            responseType: SleepSessionsResponse.self,
            completion: completion
        )
    }
}

// MARK: - ECG Records API
extension HealthService {
    
    /// Fetch ECG records from server
    /// - Parameters:
    ///   - userId: User ID
    ///   - limit: Maximum number of records to fetch
    ///   - offset: Offset for pagination
    ///   - completion: Callback with fetched records or error
    func fetchECGRecords(
        userId: Int,
        limit: Int = 100,
        offset: Int = 0,
        completion: @escaping (Result<ECGFetchResponse, NetworkError>) -> Void
    ) {
        print("[HealthService] 📥 Fetching ECG records from API (limit: \(limit), offset: \(offset))...")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getECGRecords(userId: userId, limit: limit, offset: offset),
            responseType: ECGFetchResponse.self,
            completion: completion
        )
    }
    
    /// Upload ECG records to server (batch upload)
    /// - Parameters:
    ///   - userId: User ID
    ///   - records: Array of ECG records to upload
    ///   - completion: Callback with success/failure
    func uploadECGRecords(
        userId: Int,
        records: [ECGRecord],
        completion: @escaping (Result<ECGUploadResponse, NetworkError>) -> Void
    ) {
        // Convert ECGRecord to ECGRecordUpload format
        let uploadRecords = records.map { ECGRecordUpload(from: $0) }
        
        // Create request with userId and type at root level (matches Android)
        let request = ECGUploadRequest(userId: userId, records: uploadRecords)
        
        print("[HealthService] 📤 Uploading \(uploadRecords.count) ECG record(s) to API...")
        
        APIClient.shared.postJSON(
            endpoint: APIEndpoints.uploadECGRecords,
            body: request,
            responseType: ECGUploadResponse.self,
            completion: completion
        )
    }
}

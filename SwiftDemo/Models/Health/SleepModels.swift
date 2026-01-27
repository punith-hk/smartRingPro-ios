import Foundation

// MARK: - Sleep Detail (matching Android SleepDetailBean)
struct SleepDetailAPI: Codable {
    let startTime: Int64
    let endTime: Int64
    let sleepType: Int
}

// MARK: - Sleep Session (matching Android SleepBean)
struct SleepSessionAPI: Codable {
    let statisticTime: Int64
    let startSleepHour: Int
    let startSleepMinute: Int
    let endSleepHour: Int
    let endSleepMinute: Int
    let totalTimes: Int
    let deepSleepTimes: Int
    let lightSleepTimes: Int
    let wakeupTimes: Int
    let sleepDetailList: [SleepDetailAPI]
    
    // Note: remSleepTimes is NOT sent to API (Android doesn't send it)
    // REM time is included in totalTimes calculation
}

// MARK: - Save Sleep Data Request
struct SaveSleepDataRequest: Codable {
    let userId: Int
    let sleepData: SleepSessionAPI
}

// MARK: - Save Sleep Data Response
struct SaveSleepDataResponse: Codable {
    let message: String?
    let success: Bool?
}

// MARK: - Get Sleep Data Response (for date range queries)
struct GetSleepDataResponse: Codable {
    let data: [SleepSessionAPI]?
    let message: String?
}

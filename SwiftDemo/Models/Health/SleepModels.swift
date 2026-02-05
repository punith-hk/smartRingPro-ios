import Foundation

// MARK: - API Request Models (Upload)

// MARK: - Sleep Detail (matching Android SleepDetailBean)
/// Individual sleep segment with type and time range
struct SleepDetailAPI: Codable {
    let startTime: Int64     // epoch seconds
    let endTime: Int64       // epoch seconds
    let sleepType: Int       // API mapping: 0=deep, 1=light, 3=awake, 4=REM (matches Android)
}

// MARK: - Sleep Session (matching Android SleepBean)
/// Complete sleep session payload matching Android CreateSleepData API
/// All timestamps in seconds (not milliseconds)
struct SleepSessionAPI: Codable {
    let statisticTime: Int64       // session start timestamp (epoch seconds)
    let startSleepHour: Int        // 0-23
    let startSleepMinute: Int      // 0-59
    let endSleepHour: Int          // 0-23
    let endSleepMinute: Int        // 0-59
    let totalTimes: Int            // total sleep duration in seconds (deep + light + REM)
    let deepSleepTimes: Int        // deep sleep duration in seconds
    let lightSleepTimes: Int       // light sleep duration in seconds
    let wakeupTimes: Int           // awake duration in seconds
    let sleepDetailList: [SleepDetailAPI]  // array of sleep segments
    
    // Note: REM is included in totalTimes but not sent as separate field (Android behavior)
}

// MARK: - API Response Models (Download)

/// Sleep detail from server (GET response)
struct SleepDetailResponse: Codable {
    let id: Int
    let startTime: Int64           // epoch seconds
    let endTime: Int64             // epoch seconds
    let sleepType: Int             // 0=deep, 1=light, 3=awake, 4=REM
    let created_at: String
    let updated_at: String
    let sleep_id: Int
}

/// Sleep session from server (GET response)
struct SleepBeanResponse: Codable {
    let id: Int
    let user_id: Int
    let statisticTime: Int64       // epoch seconds
    let startSleepHour: Int
    let startSleepMinute: Int
    let endSleepHour: Int
    let endSleepMinute: Int
    let totalTimes: Int            // seconds
    let deepSleepTimes: Int        // seconds
    let lightSleepTimes: Int       // seconds
    let wakeupTimes: Int           // seconds
    let created_at: String
    let updated_at: String
    let sleep_details: [SleepDetailResponse]
}

/// Response for getSleepData (single date or date range)
struct SleepDataResponse: Codable {
    let message: String
    let data: [SleepBeanResponse]?
}

/// Sleep session summary (from getSleepSessions - no details)
struct SleepSessionSummary: Codable {
    let id: Int
    let user_id: Int
    let statisticTime: Int64
    let startSleepHour: Int
    let startSleepMinute: Int
    let endSleepHour: Int
    let endSleepMinute: Int
    let totalTimes: Int
    let deepSleepTimes: Int
    let lightSleepTimes: Int
    let wakeupTimes: Int
    let created_at: String
    let updated_at: String
}

/// Response for getSleepSessions
struct SleepSessionsResponse: Codable {
    let message: String
    let data: [SleepSessionSummary]?
}

// MARK: - Legacy Response Models (for backward compatibility)

struct SaveSleepDataResponse: Codable {
    let message: String?
    let success: Bool?
}

struct GetSleepDataResponse: Codable {
    let data: [SleepSessionAPI]?
    let message: String?
}

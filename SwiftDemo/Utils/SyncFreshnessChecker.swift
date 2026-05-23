import Foundation

/// Checks whether a vital's data is still "fresh" relative to the device's
/// configured health-measurement interval.
///
/// Logic: if (now − lastSyncTime) < healthIntervalMinutes → up-to-date.
///
/// Each sync helper calls `isUpToDate(lastSyncKey:)` at the start of
/// `startSync()`.  If it returns `true` the helper fires `onUpToDate()` on
/// its listener instead of hitting BLE.
struct SyncFreshnessChecker {

    // MARK: - UserDefaults keys (mirrors BackgroundSyncManager.SyncKey)
    enum SyncTimeKey {
        static let heartRate     = "bg_sync_time_heart_rate"
        static let bloodPressure = "bg_sync_time_blood_pressure"
        static let combined      = "bg_sync_time_hrv"   // proxy for HRV/BO/BG/Temp
        static let steps         = "bg_sync_time_steps"
        static let calories      = "bg_sync_time_calories"

        /// All keys — used for sync-trigger decisions (any stale → sync runs).
        static let all: [String] = [heartRate, bloodPressure, combined, steps, calories]

        /// Primary vital keys — used ONLY for "Last data recorded" display and
        /// "Next sync at" calculation.  Steps/calories are excluded: the user
        /// cares about the core health readings matching up.
        static let primary: [String] = [heartRate, bloodPressure, combined]
    }

    // MARK: - Single vital check

    /// Returns `true` when the elapsed time since the last sync is less than
    /// the current health-measurement interval.
    static func isUpToDate(lastSyncKey: String) -> Bool {
        let ts = UserDefaults.standard.double(forKey: lastSyncKey)
        guard ts > 0 else { return false }
        let elapsed = Date().timeIntervalSince(Date(timeIntervalSince1970: ts))
        return elapsed < intervalSeconds()
    }

    // MARK: - All-vitals check (for dashboard pre-flight)

    /// Returns `true` only when EVERY vital key (including steps/calories) is within the current interval.
    /// If ANY vital is stale, a sync should run for that vital.
    static func allVitalsUpToDate() -> Bool {
        return SyncTimeKey.all.allSatisfy { isUpToDate(lastSyncKey: $0) }
    }

    // MARK: - Primary-vital display helpers (HR + BP + Combined only)

    /// Returns the Date of the OLDEST primary vital (heartRate, bloodPressure, combined).
    ///
    /// Example: HR=8:15, BP=8:00, combined=8:15 → returns 8:00.
    /// Meaning: "all primary vitals had data recorded by 8:00".
    /// BP is the limiting factor and needs to sync first.
    static func lastPrimaryDataDate() -> Date? {
        let minTs = SyncTimeKey.primary.compactMap { key -> Double? in
            let ts = UserDefaults.standard.double(forKey: key)
            return ts > 0 ? ts : nil
        }.min()
        guard let ts = minTs else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    /// "Next sync at X:XX" based on the OLDEST primary vital.
    /// E.g. BP=8:00, HR/combined=8:15, interval=15 min → "Next sync at 8:15" (BP expires first).
    /// Once all three align at 8:15 → "Next sync at 8:30".
    static func nextSyncMessage() -> String {
        let minTs = SyncTimeKey.primary.compactMap { key -> Double? in
            let ts = UserDefaults.standard.double(forKey: key)
            return ts > 0 ? ts : nil
        }.min() ?? 0
        guard minTs > 0 else { return "" }
        let nextDate = Date(timeIntervalSince1970: minTs + intervalSeconds())
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "Next sync at \(fmt.string(from: nextDate))"
    }

    /// Next sync message derived from a *specific* freshness key.
    /// Use this in individual VCs where you know which key was checked.
    /// Because `isUpToDate(lastSyncKey:)` already confirmed the key > 0,
    /// this is guaranteed to return a non-empty string.
    static func nextSyncMessage(for key: String) -> String {
        let ts = UserDefaults.standard.double(forKey: key)
        guard ts > 0 else { return "" }
        let nextDate = Date(timeIntervalSince1970: ts + intervalSeconds())
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "Next sync at \(fmt.string(from: nextDate))"
    }

    // MARK: - Private helpers

    private static func intervalSeconds() -> TimeInterval {
        return AppSettingsManager.shared.getHealthInterval().minuteValue * 60
    }
}

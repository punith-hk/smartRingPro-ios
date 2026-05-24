import Foundation
import YCProductSDK

protocol SleepSyncListener: AnyObject {
    func onSleepDataFetched(sessions: [YCHealthDataSleep])
    func onSyncFailed(error: String)
    func onLocalDataSaved(count: Int)
    func onDayDataLoaded(sessions: [SleepSessionEntity])
}

class SleepSyncHelper {
    
    private weak var listener: SleepSyncListener?
    private let repository: SleepRepository
    
    init(listener: SleepSyncListener, repository: SleepRepository = SleepRepository()) {
        self.listener = listener
        self.repository = repository
    }
    
    // MARK: - Start BLE Sync
    func startSync() {
        print("🔄 [SleepSyncHelper] Starting BLE sync for sleep data...")
        fetchSleepDataFromRing()
    }
    
    // MARK: - Sync Day Data (Load local and upload to API if needed)
    func syncDayData(for date: Date) {
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else {
            print("⚠️ [SleepSyncHelper] No valid user ID")
            listener?.onDayDataLoaded(sessions: [])
            return
        }
        
        // Get date range for selected day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Format date for API (M/d/yyyy)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let selectedDate = dateFormatter.string(from: date)
        
        print("📅 [SleepSyncHelper] Syncing data for: \(selectedDate)")
        
        // Step 1: Get ALL local sessions for this day
        let localSessions = repository.getByDateRange(startDate: startOfDay, endDate: endOfDay)
        
        // ── LOCAL DB LOAD LOG ─────────────────────────────────────────────────
        let fmtTS: (Int64) -> String = { t in
            let d = Date(timeIntervalSince1970: TimeInterval(t))
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"; return f.string(from: d)
        }
        print("\n📂 ======= [SleepSyncHelper] LOCAL DB for \(selectedDate) (\(localSessions.count) session(s)) =======")
        for (i, s) in localSessions.enumerated() {
            let deepMin  = Int(s.deepSleepTimes)  / 60
            let lightMin = Int(s.lightSleepTimes) / 60
            let remMin   = Int(s.remSleepTimes)   / 60
            let wakeMin  = Int(s.wakeupTimes)     / 60
            let totMin   = (Int(s.deepSleepTimes) + Int(s.lightSleepTimes) + Int(s.remSleepTimes)) / 60
            print("  [Session \(i+1)] statisticTime=\(s.statisticTime)")
            print("    start : \(fmtTS(s.startTime))  end : \(fmtTS(s.endTime))")
            print("    deep  : \(s.deepSleepTimes)s ÷60= \(deepMin)m  (truncated from \(Int(s.deepSleepTimes))s)")
            print("    light : \(s.lightSleepTimes)s ÷60= \(lightMin)m  (truncated from \(Int(s.lightSleepTimes))s)")
            print("    REM   : \(s.remSleepTimes)s ÷60= \(remMin)m  (truncated from \(Int(s.remSleepTimes))s)")
            print("    awake : \(s.wakeupTimes)s ÷60= \(wakeMin)m  (truncated from \(Int(s.wakeupTimes))s)")
            print("    sleep duration (deep+light+rem): \(totMin)m  [awake excluded]")
            let details = s.details?.allObjects as? [SleepDetailEntity] ?? []
            print("    detail segments: \(details.count)")
            let typeNames2 = ["?","Deep","Light","REM","Awake"]
            for d in details.sorted(by: { $0.startTime < $1.startTime }) {
                let idx2 = Int(d.sleepType)
                let tn = (idx2 >= 0 && idx2 < typeNames2.count) ? typeNames2[idx2] : "\(d.sleepType)"
                print("      \(tn) | \(fmtTS(d.startTime)) → \(fmtTS(d.endTime)) | \(d.duration)s (\(d.duration/60)m \(d.duration%60)s)")
            }
        }
        print("📂 ============================================================\n")
        // ─────────────────────────────────────────────────────────────────────
        
        print("📊 [SleepSyncHelper] Found \(localSessions.count) local session(s) for \(selectedDate)")
        
        // Step 2: Return all local sessions to VC for display (no upload here)
        listener?.onDayDataLoaded(sessions: localSessions)
    }
    
    // MARK: - Upload Single Session to API
    private func uploadSessionToAPI(_ sessionEntity: SleepSessionEntity, userId: Int) {
        let apiSession = convertEntityToAPIFormat(sessionEntity)
        
        print("📤 [SleepSyncHelper] Uploading session \(apiSession.statisticTime) to API...")
        
        HealthService.shared.saveSleepData(userId: userId, sleepData: apiSession) { result in
            switch result {
            case .success(let response):
                // If success field exists and is true, or if success is nil (API returned 200 with empty response)
                if response.success == true || response.success == nil {
                    print("✅ [SleepSyncHelper] Successfully uploaded session \(apiSession.statisticTime)")
                } else {
                    print("⚠️ [SleepSyncHelper] Upload returned success=false for session \(apiSession.statisticTime)")
                    print("⚠️ [SleepSyncHelper] Response message: \(response.message ?? "no message")")
                }
            case .failure(let error):
                print("❌ [SleepSyncHelper] Failed to upload: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Fetch from BLE Ring
    private func fetchSleepDataFromRing() {
        YCProduct.queryHealthData(dataType: .sleep) { [weak self] state, response in
            guard let self = self else { return }
            
            switch state {
            case .succeed:
                if let sessions = response as? [YCHealthDataSleep] {
                    print("✅ [SleepSyncHelper] Fetched \(sessions.count) sleep sessions from BLE")
                    self.logSleepData(sessions)
                    self.saveToLocalDatabase(sessions)
                    self.listener?.onSleepDataFetched(sessions: sessions)
                } else {
                    print("❌ [SleepSyncHelper] Failed to cast response to [YCHealthDataSleep]")
                    self.listener?.onSyncFailed(error: "Invalid data format")
                }
                
            case .noRecord:
                print("ℹ️ [SleepSyncHelper] No sleep records available")
                self.listener?.onSleepDataFetched(sessions: [])
                
            case .unavailable:
                print("⚠️ [SleepSyncHelper] Sleep data unavailable")
                self.listener?.onSyncFailed(error: "Data unavailable")
                
            case .failed:
                print("❌ [SleepSyncHelper] BLE query failed")
                self.listener?.onSyncFailed(error: "BLE query failed")
                
            @unknown default:
                print("⚠️ [SleepSyncHelper] Unknown state: \(state)")
                self.listener?.onSyncFailed(error: "Unknown state")
            }
        }
    }
    
    // MARK: - Log Sleep Data for Analysis
    private func logSleepData(_ sessions: [YCHealthDataSleep]) {
        print("\n📊 ========== SLEEP DATA LOG (FOR ANALYSIS) ==========")
        print("Total Sessions: \(sessions.count)\n")
        
        for (index, session) in sessions.enumerated() {
            print("--- Session \(index + 1) ---")
            
            // Timestamps
            print("  startTimeStamp: \(session.startTimeStamp) (\(formatTimestamp(session.startTimeStamp)))")
            print("  endTimeStamp: \(session.endTimeStamp) (\(formatTimestamp(session.endTimeStamp)))")
            
            // Check format (new vs legacy)
            let isNewFormat = session.deepSleepCount == 0xFFFF
            print("  Format: \(isNewFormat ? "NEW (0xFFFF)" : "LEGACY")")
            
            // Sleep duration totals
            if isNewFormat {
                print("  deepSleepSeconds: \(session.deepSleepSeconds) (\(session.deepSleepSeconds / 60) min)")
                print("  lightSleepSeconds: \(session.lightSleepSeconds) (\(session.lightSleepSeconds / 60) min)")
                print("  remSleepSeconds: \(session.remSleepSeconds) (\(session.remSleepSeconds / 60) min)")
            } else {
                print("  deepSleepMinutes: \(session.deepSleepMinutes)")
                print("  lightSleepMinutes: \(session.lightSleepMinutes)")
                print("  remSleepMinutes: \(session.remSleepMinutes)")
                print("  deepSleepCount: \(session.deepSleepCount)")
                print("  lightSleepCount: \(session.lightSleepCount)")
            }
            
            // Sleep details (segments)
            print("  sleepDetailDatas count: \(session.sleepDetailDatas.count)")
            
            if !session.sleepDetailDatas.isEmpty {
                print("  Sleep Segments:")
                
                var deepCount = 0
                var lightCount = 0
                var remCount = 0
                var awakeCount = 0
                var totalDuration = 0
                
                for (detailIndex, detail) in session.sleepDetailDatas.enumerated() {
                    let typeString = sleepTypeToString(detail.sleepType)
                    let endTime = detail.startTimeStamp + detail.duration
                    
                    print("    [\(detailIndex + 1)] \(typeString) | start: \(detail.startTimeStamp) | duration: \(detail.duration)s (\(detail.duration / 60) min) | end: \(endTime)")
                    
                    // Count by type
                    switch detail.sleepType {
                    case .deepSleep:
                        deepCount += detail.duration
                    case .lightSleep:
                        lightCount += detail.duration
                    case .rem:
                        remCount += detail.duration
                    case .awake:
                        awakeCount += detail.duration
                    default:
                        break
                    }
                    totalDuration += detail.duration
                }
                
                print("  Summary from details:")
                print("    Deep: \(deepCount)s (\(deepCount / 60) min)")
                print("    Light: \(lightCount)s (\(lightCount / 60) min)")
                print("    REM: \(remCount)s (\(remCount / 60) min)")
                print("    Awake: \(awakeCount)s (\(awakeCount / 60) min)")
                print("    Total: \(totalDuration)s (\(totalDuration / 60) min)")
            }
            
            print("")
        }
        
        print("========== END SLEEP DATA LOG ==========\n")
    }
    
    // MARK: - Save to Local Database
    private func saveToLocalDatabase(_ sessions: [YCHealthDataSleep]) {
        print("💾 [SleepSyncHelper] Saving \(sessions.count) sessions to local DB...")
        
        // Convert BLE sessions to repository format
        var repositorySessions: [(statisticTime: Int64, startTime: Int64, endTime: Int64, totalTimes: Int32, deepSleepTimes: Int32, lightSleepTimes: Int32, remSleepTimes: Int32, wakeupTimes: Int32, details: [(startTime: Int64, endTime: Int64, duration: Int32, sleepType: Int16)])] = []
        
        for session in sessions {
            // Use startTimeStamp as statisticTime (unique identifier)
            let statisticTime = Int64(session.startTimeStamp)
            let startTime = Int64(session.startTimeStamp)
            let endTime = Int64(session.endTimeStamp)
            
            // Detect format (new vs legacy)
            let isNewFormat = session.deepSleepCount == 0xFFFF
            
            // Convert durations to seconds (normalize both formats)
            let deepSleepSeconds = isNewFormat ? Int32(session.deepSleepSeconds) : Int32(session.deepSleepMinutes * 60)
            let lightSleepSeconds = isNewFormat ? Int32(session.lightSleepSeconds) : Int32(session.lightSleepMinutes * 60)
            let remSleepSeconds = isNewFormat ? Int32(session.remSleepSeconds) : Int32(session.remSleepMinutes * 60)
            
            // Calculate awake time from details (sum of all AWAKE segments)
            let wakeupSeconds = session.sleepDetailDatas
                .filter { $0.sleepType == .awake }
                .reduce(0) { $0 + Int32($1.duration) }
            
            // Calculate total time
            let totalSeconds = deepSleepSeconds + lightSleepSeconds + remSleepSeconds + wakeupSeconds
            
            // Convert details
            var detailsArray: [(startTime: Int64, endTime: Int64, duration: Int32, sleepType: Int16)] = []
            
            for detail in session.sleepDetailDatas {
                let detailStartTime = Int64(detail.startTimeStamp)
                let detailDuration = Int32(detail.duration)
                let detailEndTime = detailStartTime + Int64(detailDuration)
                
                // Map sleep type enum to Int16 (1=Deep, 2=Light, 3=REM, 4=Awake)
                let sleepTypeValue: Int16
                switch detail.sleepType {
                case .deepSleep:
                    sleepTypeValue = 1
                case .lightSleep:
                    sleepTypeValue = 2
                case .rem:
                    sleepTypeValue = 3
                case .awake:
                    sleepTypeValue = 4
                case .unknow:
                    sleepTypeValue = 0
                @unknown default:
                    sleepTypeValue = 0
                }
                
                detailsArray.append((
                    startTime: detailStartTime,
                    endTime: detailEndTime,
                    duration: detailDuration,
                    sleepType: sleepTypeValue
                ))
            }
            
            // Add to repository sessions array
            repositorySessions.append((
                statisticTime: statisticTime,
                startTime: startTime,
                endTime: endTime,
                totalTimes: totalSeconds,
                deepSleepTimes: deepSleepSeconds,
                lightSleepTimes: lightSleepSeconds,
                remSleepTimes: remSleepSeconds,
                wakeupTimes: wakeupSeconds,
                details: detailsArray
            ))
        }
        
        // ── BLE → DB CONVERSION LOG ──────────────────────────────────────────
        let ts: (Int64) -> String = { t in
            let d = Date(timeIntervalSince1970: TimeInterval(t))
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"; return f.string(from: d)
        }
        print("\n🛏️ ======= [SleepSyncHelper] BLE→DB CONVERSION (\(repositorySessions.count) session(s)) =======")
        for (i, s) in repositorySessions.enumerated() {
            let deepMin  = Int(s.deepSleepTimes)  / 60; let deepSec  = Int(s.deepSleepTimes)  % 60
            let lightMin = Int(s.lightSleepTimes) / 60; let lightSec = Int(s.lightSleepTimes) % 60
            let remMin   = Int(s.remSleepTimes)   / 60; let remSec   = Int(s.remSleepTimes)   % 60
            let wakeMin  = Int(s.wakeupTimes)     / 60; let wakeSec  = Int(s.wakeupTimes)     % 60
            let totMin   = Int(s.totalTimes)      / 60; let totSec   = Int(s.totalTimes)      % 60
            print("  [Session \(i+1)] statisticTime=\(s.statisticTime)")
            print("    start : \(ts(s.startTime))  end : \(ts(s.endTime))")
            print("    deep  : \(s.deepSleepTimes)s → \(deepMin)m \(deepSec)s")
            print("    light : \(s.lightSleepTimes)s → \(lightMin)m \(lightSec)s")
            print("    REM   : \(s.remSleepTimes)s → \(remMin)m \(remSec)s")
            print("    awake : \(s.wakeupTimes)s → \(wakeMin)m \(wakeSec)s")
            print("    total : \(s.totalTimes)s → \(totMin)m \(totSec)s  (deep+light+rem+awake)")
            print("    details count: \(s.details.count)")
            for (j, d) in s.details.enumerated() {
                let typeNames = ["?","Deep","Light","REM","Awake"]
                let idx = Int(d.sleepType)
                let typeStr = (idx >= 0 && idx < typeNames.count) ? typeNames[idx] : "\(d.sleepType)"
                print("      [\(j+1)] \(typeStr) | start:\(ts(d.startTime)) | dur:\(d.duration)s (\(d.duration/60)m \(d.duration%60)s)")
            }
        }
        print("🛏️ ========================================================\n")
        // ─────────────────────────────────────────────────────────────────────

        // Save to repository
        repository.saveNewBatch(sessions: repositorySessions) { [weak self] success, savedCount in
            if success {
                print("✅ [SleepSyncHelper] Successfully saved \(savedCount) new sessions to local DB")
                self?.listener?.onLocalDataSaved(count: savedCount)
                
                // Always recompute dashboard stats from the latest DB state after sync
                self?.updateDashboardSleepStats()
                
                // Upload to API (matching Android pattern)
                if savedCount > 0 {
                    self?.uploadToAPI(sessions)
                }
            } else {
                print("❌ [SleepSyncHelper] Failed to save sessions to local DB")
            }
        }
    }
    
    // MARK: - Update Dashboard Sleep Stats (UserDefaults)
    /// Called after every BLE sync. Reads all sessions from last 36h, computes
    /// total sleep duration (in minutes) and quality score (0-100), then writes
    /// both to UserDefaults so the dashboard can display them immediately.
    private func updateDashboardSleepStats() {
        // Use the same sleep-group logic as the SleepVC so dashboard matches the detail screen.
        // getByDateRange groups consecutive sessions and returns the group whose last session
        // ends on today, which correctly scopes to tonight's sleep only.
        let today = Date()
        let source = repository.getByDateRange(startDate: today, endDate: today)
        
        guard !source.isEmpty else {
            print("ℹ️ [SleepSyncHelper] No sessions found for today — skipping dashboard stat update")
            return
        }
        
        // Mirror Sleep VC exactly: truncate each session's fields to minutes first, then sum.
        // This avoids the rounding difference between seconds-based and minutes-based formulas.
        var totalSleepMin = 0
        for session in source {
            totalSleepMin += Int(session.deepSleepTimes) / 60
            totalSleepMin += Int(session.lightSleepTimes) / 60
            totalSleepMin += Int(session.remSleepTimes) / 60
        }
        
        // Quality score: same formula as SleepVC.calculateSleepScore (÷480 min = 8h), clamped 12-100
        let qualityScore = min(100, max(12, Int(Double(totalSleepMin) / 480.0 * 100)))
        
        UserDefaults.standard.set(totalSleepMin, forKey: "last_day_sleep_minutes")
        UserDefaults.standard.set(qualityScore,  forKey: "last_day_sleep_quality")
        
        print("📊 [SleepSyncHelper] Dashboard stats → sleep: \(totalSleepMin) min (\(totalSleepMin/60)h \(totalSleepMin%60)m), quality: \(qualityScore)/100  [sessions used: \(source.count)]")
    }
    
    // MARK: - Upload to API (matching Android saveSleepData)
    private func uploadToAPI(_ sessions: [YCHealthDataSleep]) {
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else {
            print("⚠️ [SleepSyncHelper] No valid user ID for API upload")
            return
        }
        
        print("📤 [SleepSyncHelper] Uploading \(sessions.count) sessions to API...")
        
        for session in sessions {
            // Convert to API format (matching Android SleepBean)
            let apiSession = convertToAPIFormat(session)
            
            HealthService.shared.saveSleepData(userId: userId, sleepData: apiSession) { result in
                switch result {
                case .success(let response):
                    // If success field exists and is true, or if success is nil (API returned 200 with empty response)
                    if response.success == true || response.success == nil {
                        print("✅ [SleepSyncHelper] Successfully uploaded session \(apiSession.statisticTime)")
                    } else {
                        print("⚠️ [SleepSyncHelper] Upload returned success=false for session \(apiSession.statisticTime)")
                        print("⚠️ [SleepSyncHelper] Response message: \(response.message ?? "no message")")
                    }
                case .failure(let error):
                    print("❌ [SleepSyncHelper] Failed to upload session \(apiSession.statisticTime): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Convert to API Format
    private func convertToAPIFormat(_ session: YCHealthDataSleep) -> SleepSessionAPI {
        let statisticTime = Int64(session.startTimeStamp)
        
        // Extract start/end hour and minute from timestamps
        let startDate = Date(timeIntervalSince1970: TimeInterval(session.startTimeStamp))
        let endDate = Date(timeIntervalSince1970: TimeInterval(session.endTimeStamp))
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
        
        // Detect format and normalize to seconds
        let isNewFormat = session.deepSleepCount == 0xFFFF
        let deepSleepSeconds = isNewFormat ? session.deepSleepSeconds : (session.deepSleepMinutes * 60)
        let lightSleepSeconds = isNewFormat ? session.lightSleepSeconds : (session.lightSleepMinutes * 60)
        let remSleepSeconds = isNewFormat ? session.remSleepSeconds : (session.remSleepMinutes * 60)
        let wakeupSeconds = session.sleepDetailDatas
            .filter { $0.sleepType == .awake }
            .reduce(0) { $0 + $1.duration }
        let totalSeconds = deepSleepSeconds + lightSleepSeconds + remSleepSeconds + wakeupSeconds
        
        // Convert details
        let apiDetails = session.sleepDetailDatas.map { detail -> SleepDetailAPI in
            // Map iOS enum to API values (matching Android)
            // Android mapping: 242->0(deep), 241->1(light), 243->3(awake), 244->4(REM)
            let sleepTypeValue: Int
            switch detail.sleepType {
            case .deepSleep: sleepTypeValue = 0   // Deep = 0
            case .lightSleep: sleepTypeValue = 1  // Light = 1
            case .awake: sleepTypeValue = 3       // Awake = 3
            case .rem: sleepTypeValue = 4         // REM = 4
            default: sleepTypeValue = 0           // Unknown defaults to deep
            }
            
            return SleepDetailAPI(
                startTime: Int64(detail.startTimeStamp),
                endTime: Int64(detail.startTimeStamp + detail.duration),
                sleepType: sleepTypeValue
            )
        }
        
        return SleepSessionAPI(
            statisticTime: statisticTime,
            startSleepHour: startComponents.hour ?? 0,
            startSleepMinute: startComponents.minute ?? 0,
            endSleepHour: endComponents.hour ?? 0,
            endSleepMinute: endComponents.minute ?? 0,
            totalTimes: totalSeconds,
            deepSleepTimes: deepSleepSeconds,
            lightSleepTimes: lightSleepSeconds,
            wakeupTimes: wakeupSeconds,
            sleepDetailList: apiDetails
        )
    }
    
    // MARK: - Convert Entity to API Format
    private func convertEntityToAPIFormat(_ sessionEntity: SleepSessionEntity) -> SleepSessionAPI {
        // Extract start/end hour and minute from timestamps
        let startDate = Date(timeIntervalSince1970: TimeInterval(sessionEntity.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(sessionEntity.endTime))
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
        
        // Convert details from entity
        var apiDetails: [SleepDetailAPI] = []
        if let detailsSet = sessionEntity.details as? Set<SleepDetailEntity> {
            apiDetails = detailsSet.map { detail in
                // Convert local database type (1=Deep,2=Light,3=REM,4=Awake) to API type
                // API expects: 0=Deep, 1=Light, 3=Awake, 4=REM
                let apiSleepType: Int
                switch detail.sleepType {
                case 1: apiSleepType = 0  // Deep: 1 -> 0
                case 2: apiSleepType = 1  // Light: 2 -> 1
                case 3: apiSleepType = 4  // REM: 3 -> 4
                case 4: apiSleepType = 3  // Awake: 4 -> 3
                default: apiSleepType = 0 // Unknown -> Deep
                }
                
                return SleepDetailAPI(
                    startTime: detail.startTime,
                    endTime: detail.endTime,
                    sleepType: apiSleepType
                )
            }.sorted { $0.startTime < $1.startTime } // Sort by start time
        }
        
        return SleepSessionAPI(
            statisticTime: sessionEntity.statisticTime,
            startSleepHour: startComponents.hour ?? 0,
            startSleepMinute: startComponents.minute ?? 0,
            endSleepHour: endComponents.hour ?? 0,
            endSleepMinute: endComponents.minute ?? 0,
            totalTimes: Int(sessionEntity.totalTimes),
            deepSleepTimes: Int(sessionEntity.deepSleepTimes),
            lightSleepTimes: Int(sessionEntity.lightSleepTimes),
            wakeupTimes: Int(sessionEntity.wakeupTimes),
            sleepDetailList: apiDetails
        )
    }
    
    // MARK: - Helper Methods
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func sleepTypeToString(_ type: YCHealthDataSleepType) -> String {
        switch type {
        case .deepSleep:
            return "DEEP (1)"
        case .lightSleep:
            return "LIGHT (2)"
        case .rem:
            return "REM (3)"
        case .awake:
            return "AWAKE (4)"
        case .unknow:
            return "UNKNOWN (0)"
        @unknown default:
            return "UNKNOWN (\(type.rawValue))"
        }
    }
}

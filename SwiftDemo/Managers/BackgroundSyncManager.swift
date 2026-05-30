import Foundation
import YCProductSDK

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO FILTER LOGS IN XCODE CONSOLE
//
//  All messages use the prefix  [BGSync]  — type it in the console filter bar.
//
//  Sub-tags for finer filtering:
//    [BGSync][PHASE]   Phase start / end markers
//    [BGSync][BLE]     BLE query events (start, received, failed)
//    [BGSync][LOCAL]   Local DB save events
//    [BGSync][API]     API upload events (start, success, failure)
//    [BGSync][SUMMARY] Final summary printed after full sync
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates a full background sync in three sequential BLE phases:
///   Phase 1 → Heart Rate  (BLE → local → API)
///   Phase 2 → Blood Pressure (BLE → local → API)
///   Phase 3 → Combined (ONE BLE call → local for all 4)
///             → API one-by-one: HRV → Blood Oxygen → Blood Glucose → Temperature
final class BackgroundSyncManager {

    static let shared = BackgroundSyncManager()
    private init() {}

    // MARK: - UserDefaults keys (per-vital last sync timestamp)

    private enum SyncKey {
        static let heartRate     = "bg_sync_time_heart_rate"
        static let bloodPressure = "bg_sync_time_blood_pressure"
        static let hrv           = "bg_sync_time_hrv"
        static let bloodOxygen   = "bg_sync_time_blood_oxygen"
        static let bloodGlucose  = "bg_sync_time_blood_glucose"
        static let temperature   = "bg_sync_time_temperature"
        static let steps         = "bg_sync_time_steps"
        static let calories      = "bg_sync_time_calories"
    }

    private enum SyncCountKey {
        static let heartRate     = "bg_sync_count_heart_rate"
        static let bloodPressure = "bg_sync_count_blood_pressure"
        static let hrv           = "bg_sync_count_hrv"
        static let bloodOxygen   = "bg_sync_count_blood_oxygen"
        static let bloodGlucose  = "bg_sync_count_blood_glucose"
        static let temperature   = "bg_sync_count_temperature"
        static let steps         = "bg_sync_count_steps"
        static let calories      = "bg_sync_count_calories"
    }

    // MARK: - Result tracking (for final summary)

    private struct VitalResult {
        var bleCount: Int = 0
        var bleStatus: String = "–"
        var apiStatus: String = "–"
        var duration: TimeInterval = 0
    }

    private var results: [String: VitalResult] = [:]
    private var fullSyncStartTime: Date = Date()
    private var phaseStartTime:    Date = Date()

    // MARK: - State

    private enum Phase { case heartRate, bloodPressure, combined, steps, sleep }
    private var currentPhase: Phase = .heartRate

    private(set) var isSyncing = false

    private var hrHelper:       HeartRateSyncHelper?
    private var bpHelper:       BloodPressureSyncHelper?
    private var combinedHelper: CombinedDataSyncHelper?
    private var stepsHelper:    StepsSyncHelper?
    private var sleepHelper:    SleepSyncHelper?

    private var fullSyncCompletion: ((Bool) -> Void)?
    private var syncTimeoutWork:    DispatchWorkItem?
    private var userId: Int { UserDefaultsManager.shared.userId }

    // MARK: - Structured Logging

    private func log(_ tag: String, _ message: String) {
        print("[BGSync][\(tag)] \(message)")
    }

    private func elapsed(from start: Date) -> String {
        return String(format: "%.2fs", Date().timeIntervalSince(start))
    }

    // MARK: - Public API

    func startFullSync(completion: @escaping (Bool) -> Void) {
        guard !isSyncing else {
            log("PHASE", "⚠️  Sync already in progress — ignoring new request")
            completion(false)
            return
        }
        guard BLEStateManager.shared.hasConnectedDevice() else {
            log("BLE", "❌  No device connected — aborting sync")
            completion(false)
            return
        }
        isSyncing = true
        fullSyncCompletion = completion
        results = [:]
        fullSyncStartTime = Date()

        log("PHASE", "╔══════════════════════════════════════════════")
        log("PHASE", "║  FULL SYNC STARTED")
        log("PHASE", "║  User ID : \(userId)")
        log("PHASE", "╚══════════════════════════════════════════════")

        // Safety net: if BLE device never responds, abort after 45 s
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.isSyncing else { return }
            self.log("PHASE", "⚠️  Sync timed out after 45 s — forcing finish")
            self.finishSync()
        }
        syncTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: work)

        beginHeartRate()
    }

    func lastSyncDate(for key: String) -> Date? {
        let ts = UserDefaults.standard.double(forKey: key)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    // MARK: - Per-vital Sync Timestamps (public accessors)

    var lastHeartRateSync:    Date? { lastSyncDate(for: SyncKey.heartRate) }
    var lastBloodPressureSync: Date? { lastSyncDate(for: SyncKey.bloodPressure) }
    var lastHRVSync:          Date? { lastSyncDate(for: SyncKey.hrv) }
    var lastBloodOxygenSync:  Date? { lastSyncDate(for: SyncKey.bloodOxygen) }
    var lastBloodGlucoseSync: Date? { lastSyncDate(for: SyncKey.bloodGlucose) }
    var lastTemperatureSync:  Date? { lastSyncDate(for: SyncKey.temperature) }

    // MARK: - Per-vital BLE new-data counts from last sync

    private func lastBleCount(for countKey: String) -> Int {
        let v = UserDefaults.standard.integer(forKey: countKey)
        // -1 means "never synced"
        return UserDefaults.standard.object(forKey: countKey) == nil ? -1 : v
    }

    var lastHeartRateBleCount:    Int { lastBleCount(for: SyncCountKey.heartRate) }
    var lastBloodPressureBleCount: Int { lastBleCount(for: SyncCountKey.bloodPressure) }
    var lastHRVBleCount:          Int { lastBleCount(for: SyncCountKey.hrv) }
    var lastBloodOxygenBleCount:  Int { lastBleCount(for: SyncCountKey.bloodOxygen) }
    var lastBloodGlucoseBleCount: Int { lastBleCount(for: SyncCountKey.bloodGlucose) }
    var lastTemperatureBleCount:  Int { lastBleCount(for: SyncCountKey.temperature) }
    var lastStepsBleCount:        Int { lastBleCount(for: SyncCountKey.steps) }
    var lastCaloriesBleCount:     Int { lastBleCount(for: SyncCountKey.calories) }

    var lastStepsSync:    Date? { lastSyncDate(for: SyncKey.steps) }
    var lastCaloriesSync: Date? { lastSyncDate(for: SyncKey.calories) }

    // MARK: - Internal Helpers

    private func markSynced(_ key: String, countKey: String, bleCount: Int, latestDataTimestamp: TimeInterval? = nil) {
        // Only update the sync time when the ring actually provided data.
        // If latestDataTimestamp is nil (BLE returned nothing), leave the existing
        // timestamp unchanged — so the freshness check keeps retrying until the
        // ring records the next interval's data.
        if let ts = latestDataTimestamp {
            UserDefaults.standard.set(ts, forKey: key)
        }
        UserDefaults.standard.set(bleCount, forKey: countKey)
    }

    private func finishSync() {
        syncTimeoutWork?.cancel()
        syncTimeoutWork = nil
        isSyncing = false
        let totalTime = elapsed(from: fullSyncStartTime)
        printSummary(totalTime: totalTime)
        let cb = fullSyncCompletion
        fullSyncCompletion = nil
        hrHelper = nil
        bpHelper = nil
        combinedHelper = nil
        stepsHelper = nil
        sleepHelper = nil
        DispatchQueue.main.async { cb?(true) }
    }

    private func printSummary(totalTime: String) {
        let order = ["Heart Rate", "Blood Pressure", "HRV", "Blood Oxygen", "Blood Glucose", "Temperature", "Steps", "Calories", "Sleep"]
        log("SUMMARY", "╔══════════════════════════════════════════════")
        log("SUMMARY", "║  FULL SYNC COMPLETE  ·  Total: \(totalTime)")
        log("SUMMARY", "╠══════════════════════════════════════════════")
        for vital in order {
            let r = results[vital] ?? VitalResult()
            let durationStr = r.duration > 0 ? String(format: "%.2fs", r.duration) : "–"
            log("SUMMARY", "║  \(vital.padding(toLength: 16, withPad: " ", startingAt: 0))  BLE: \(r.bleStatus) \(r.bleCount) entries  API: \(r.apiStatus)  (\(durationStr))")
        }
        log("SUMMARY", "╚══════════════════════════════════════════════")
    }

    // MARK: - Phase 1: Heart Rate

    private func beginHeartRate() {
        currentPhase  = .heartRate
        phaseStartTime = Date()
        log("PHASE", "── Phase 1 / 3 : Heart Rate ──────────────────")
        log("BLE",   "  → Querying device for heart rate data…")
        hrHelper = HeartRateSyncHelper(listener: self)
        hrHelper?.startSync()
    }

    private func uploadHeartRateThenContinue(_ data: [YCHealthDataHeartRate]) {
        let duration = Date().timeIntervalSince(phaseStartTime)
        results["Heart Rate"] = VitalResult(bleCount: data.count,
                                            bleStatus: "✅",
                                            apiStatus: "–",
                                            duration: duration)
        log("LOCAL", "  → Saved \(data.count) HR entries to local DB")

        guard userId > 0 && !data.isEmpty else {
            log("API",   "  → Skipped (no data or no userId)")
            results["Heart Rate"]?.apiStatus = "skip"
            markSynced(SyncKey.heartRate, countKey: SyncCountKey.heartRate, bleCount: 0)
            beginBloodPressure()
            return
        }

        let values = data.map { RingValueEntry(value: String($0.heartRate), timestamp: Int64($0.startTimeStamp)) }
        log("API", "  → Uploading \(values.count) HR entries  [heart_rate]…")

        HealthService.shared.saveHealthDataBatch(userId: userId, type: "heart_rate", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                self.log("API", "  ✅ HR upload success · \(resp.message)")
                self.results["Heart Rate"]?.apiStatus = "✅"
                let latestTs = data.max(by: { $0.startTimeStamp < $1.startTimeStamp }).map { TimeInterval($0.startTimeStamp) }
                self.markSynced(SyncKey.heartRate, countKey: SyncCountKey.heartRate, bleCount: data.count, latestDataTimestamp: latestTs)
            case .failure(let err):
                self.log("API", "  ❌ HR upload failed  · \(err.localizedDescription)")
                self.results["Heart Rate"]?.apiStatus = "❌"
            }
            self.beginBloodPressure()
        }
    }

    // MARK: - Phase 2: Blood Pressure

    private func beginBloodPressure() {
        currentPhase   = .bloodPressure
        phaseStartTime = Date()
        log("PHASE", "── Phase 2 / 3 : Blood Pressure ──────────────")
        log("BLE",   "  → Querying device for blood pressure data…")
        bpHelper = BloodPressureSyncHelper(listener: self)
        bpHelper?.startSync()
    }

    private func uploadBloodPressureThenContinue(_ data: [YCHealthDataBloodPressure]) {
        let duration = Date().timeIntervalSince(phaseStartTime)
        results["Blood Pressure"] = VitalResult(bleCount: data.count,
                                                bleStatus: "✅",
                                                apiStatus: "–",
                                                duration: duration)
        log("LOCAL", "  → Saved \(data.count) BP entries to local DB")

        guard userId > 0 && !data.isEmpty else {
            log("API",   "  → Skipped (no data or no userId)")
            results["Blood Pressure"]?.apiStatus = "skip"
            markSynced(SyncKey.bloodPressure, countKey: SyncCountKey.bloodPressure, bleCount: 0)
            beginCombined()
            return
        }

        let values = data.map {
            RingValueEntry(value: "\($0.systolicBloodPressure)/\($0.diastolicBloodPressure)",
                           timestamp: Int64($0.startTimeStamp))
        }
        log("API", "  → Uploading \(values.count) BP entries  [blood_pressure]…")

        HealthService.shared.saveHealthDataBatch(userId: userId, type: "blood_pressure", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                self.log("API", "  ✅ BP upload success · \(resp.message)")
                self.results["Blood Pressure"]?.apiStatus = "✅"
                let latestTs = data.max(by: { $0.startTimeStamp < $1.startTimeStamp }).map { TimeInterval($0.startTimeStamp) }
                self.markSynced(SyncKey.bloodPressure, countKey: SyncCountKey.bloodPressure, bleCount: data.count, latestDataTimestamp: latestTs)
            case .failure(let err):
                self.log("API", "  ❌ BP upload failed  · \(err.localizedDescription)")
                self.results["Blood Pressure"]?.apiStatus = "❌"
            }
            self.beginCombined()
        }
    }

    // MARK: - Phase 3: Combined

    private func beginCombined() {
        currentPhase   = .combined
        phaseStartTime = Date()
        log("PHASE", "── Phase 3 / 3 : Combined (HRV + O₂ + Glucose + Temp) ──")
        log("BLE",   "  → Querying device — single combined BLE call…")
        combinedHelper = CombinedDataSyncHelper(listener: self)
        combinedHelper?.startSync()
    }

    private func uploadCombinedSequentially(
        hrv: [YCHealthDataCombinedData],
        bloodOxygen: [YCHealthDataCombinedData],
        bloodGlucose: [YCHealthDataCombinedData],
        temperature: [YCHealthDataCombinedData]
    ) {
        log("BLE", "  ✅ Combined BLE done — HRV:\(hrv.count)  O₂:\(bloodOxygen.count)  Glucose:\(bloodGlucose.count)  Temp:\(temperature.count)")
        log("LOCAL", "  → Saving all 4 vital types to local DB (concurrent)…")

        // Upload sequentially: HRV → O₂ → Glucose → Temp
        log("API", "  ─── [1/4] HRV ─────────────────────────────")
        uploadHRV(hrv) { [weak self] in
            guard let self = self else { return }
            self.log("API", "  ─── [2/4] Blood Oxygen ─────────────────────")
            self.uploadBloodOxygen(bloodOxygen) { [weak self] in
                guard let self = self else { return }
                self.log("API", "  ─── [3/4] Blood Glucose ────────────────────")
                self.uploadBloodGlucose(bloodGlucose) { [weak self] in
                    guard let self = self else { return }
                    self.log("API", "  ─── [4/4] Temperature ──────────────────────")
                    self.uploadTemperature(temperature) { [weak self] in
                        self?.beginSteps()
                    }
                }
            }
        }
    }

    private func uploadHRV(_ data: [YCHealthDataCombinedData], completion: @escaping () -> Void) {
        guard userId > 0 && !data.isEmpty else {
            log("API", "      → HRV skipped (no data)")
            results["HRV"] = VitalResult(bleCount: 0, bleStatus: "–", apiStatus: "skip", duration: 0)
            markSynced(SyncKey.hrv, countKey: SyncCountKey.hrv, bleCount: 0); completion(); return
        }
        let values = data.map { RingValueEntry(value: String($0.hrv), timestamp: Int64($0.startTimeStamp)) }
        log("API", "      → Uploading \(values.count) HRV entries  [hrv]…")
        HealthService.shared.saveHealthDataBatch(userId: userId, type: "hrv", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                self.log("API", "      ✅ HRV upload success · \(resp.message)")
                self.results["HRV"] = VitalResult(bleCount: data.count, bleStatus: "✅", apiStatus: "✅", duration: 0)
                let latestTs = data.max(by: { $0.startTimeStamp < $1.startTimeStamp }).map { TimeInterval($0.startTimeStamp) }
                self.markSynced(SyncKey.hrv, countKey: SyncCountKey.hrv, bleCount: data.count, latestDataTimestamp: latestTs)
            case .failure(let err):
                self.log("API", "      ❌ HRV upload failed  · \(err.localizedDescription)")
                self.results["HRV"] = VitalResult(bleCount: data.count, bleStatus: "✅", apiStatus: "❌", duration: 0)
            }
            completion()
        }
    }

    private func uploadBloodOxygen(_ data: [YCHealthDataCombinedData], completion: @escaping () -> Void) {
        guard userId > 0 && !data.isEmpty else {
            log("API", "      → Blood Oxygen skipped (no data)")
            results["Blood Oxygen"] = VitalResult(bleCount: 0, bleStatus: "–", apiStatus: "skip", duration: 0)
            markSynced(SyncKey.bloodOxygen, countKey: SyncCountKey.bloodOxygen, bleCount: 0); completion(); return
        }
        let values = data.map { RingValueEntry(value: String($0.bloodOxygen), timestamp: Int64($0.startTimeStamp)) }
        log("API", "      → Uploading \(values.count) Blood Oxygen entries  [blood_oxygen]…")
        HealthService.shared.saveHealthDataBatch(userId: userId, type: "blood_oxygen", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                self.log("API", "      ✅ Blood Oxygen upload success · \(resp.message)")
                self.results["Blood Oxygen"] = VitalResult(bleCount: data.count, bleStatus: "✅", apiStatus: "✅", duration: 0)
                let latestTs = data.max(by: { $0.startTimeStamp < $1.startTimeStamp }).map { TimeInterval($0.startTimeStamp) }
                self.markSynced(SyncKey.bloodOxygen, countKey: SyncCountKey.bloodOxygen, bleCount: data.count, latestDataTimestamp: latestTs)
            case .failure(let err):
                self.log("API", "      ❌ Blood Oxygen upload failed  · \(err.localizedDescription)")
                self.results["Blood Oxygen"] = VitalResult(bleCount: data.count, bleStatus: "✅", apiStatus: "❌", duration: 0)
            }
            completion()
        }
    }

    private func uploadBloodGlucose(_ data: [YCHealthDataCombinedData], completion: @escaping () -> Void) {
        guard userId > 0 && !data.isEmpty else {
            log("API", "      → Blood Glucose skipped (no data)")
            results["Blood Glucose"] = VitalResult(bleCount: 0, bleStatus: "–", apiStatus: "skip", duration: 0)
            markSynced(SyncKey.bloodGlucose, countKey: SyncCountKey.bloodGlucose, bleCount: 0); completion(); return
        }
        // iOS SDK returns bloodGlucose in mmol/L (4–8); multiply ×10 to match Android/server scale
        let values = data.map { RingValueEntry(value: String(format: "%.1f", $0.bloodGlucose * 10), timestamp: Int64($0.startTimeStamp)) }
        log("API", "      → Uploading \(values.count) Blood Glucose entries  [blood_glucose]…")
        HealthService.shared.saveHealthDataBatch(userId: userId, type: "blood_glucose", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                self.log("API", "      ✅ Blood Glucose upload success · \(resp.message)")
                self.results["Blood Glucose"] = VitalResult(bleCount: data.count, bleStatus: "✅", apiStatus: "✅", duration: 0)
                let latestTs = data.max(by: { $0.startTimeStamp < $1.startTimeStamp }).map { TimeInterval($0.startTimeStamp) }
                self.markSynced(SyncKey.bloodGlucose, countKey: SyncCountKey.bloodGlucose, bleCount: data.count, latestDataTimestamp: latestTs)
            case .failure(let err):
                self.log("API", "      ❌ Blood Glucose upload failed  · \(err.localizedDescription)")
                self.results["Blood Glucose"] = VitalResult(bleCount: data.count, bleStatus: "✅", apiStatus: "❌", duration: 0)
            }
            completion()
        }
    }

    private func uploadTemperature(_ data: [YCHealthDataCombinedData], completion: @escaping () -> Void) {
        let validData = data.filter { $0.temperatureValid }
        guard userId > 0 && !validData.isEmpty else {
            log("API", "      → Temperature skipped (\(data.isEmpty ? "no data" : "no valid readings"))")
            results["Temperature"] = VitalResult(bleCount: data.count, bleStatus: data.isEmpty ? "–" : "✅", apiStatus: "skip", duration: 0)
            markSynced(SyncKey.temperature, countKey: SyncCountKey.temperature, bleCount: 0); completion(); return
        }
        let values = validData.map { RingValueEntry(value: String(format: "%.2f", $0.temperature), timestamp: Int64($0.startTimeStamp)) }
        log("API", "      → Uploading \(values.count) Temperature entries  [temperature]  (\(data.count - validData.count) invalid filtered)…")
        HealthService.shared.saveHealthDataBatch(userId: userId, type: "temperature", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                self.log("API", "      ✅ Temperature upload success · \(resp.message)")
                self.results["Temperature"] = VitalResult(bleCount: validData.count, bleStatus: "✅", apiStatus: "✅", duration: 0)
                let latestTs = validData.max(by: { $0.startTimeStamp < $1.startTimeStamp }).map { TimeInterval($0.startTimeStamp) }
                self.markSynced(SyncKey.temperature, countKey: SyncCountKey.temperature, bleCount: validData.count, latestDataTimestamp: latestTs)
            case .failure(let err):
                self.log("API", "      ❌ Temperature upload failed  · \(err.localizedDescription)")
                self.results["Temperature"] = VitalResult(bleCount: validData.count, bleStatus: "✅", apiStatus: "❌", duration: 0)
            }
            completion()
        }
    }
}
    // MARK: - Phase 4: Steps / Calories

extension BackgroundSyncManager {
    fileprivate func beginSteps() {
        currentPhase   = .steps
        phaseStartTime = Date()
        log("PHASE", "── Phase 4 / 5 : Steps + Calories ────────────")
        log("BLE",   "  → Querying device for steps data…")
        stepsHelper = StepsSyncHelper(listener: self)
        stepsHelper?.startSync()
    }

    fileprivate func uploadStepsThenCalories(_ data: [YCHealthDataStep]) {
        let duration = Date().timeIntervalSince(phaseStartTime)
        log("LOCAL", "  → Saved \(data.count) step entries to local DB")
        results["Steps"]    = VitalResult(bleCount: data.count, bleStatus: data.isEmpty ? "–" : "✅", apiStatus: "–", duration: duration)
        results["Calories"] = VitalResult(bleCount: data.count, bleStatus: data.isEmpty ? "–" : "✅", apiStatus: "–", duration: 0)

        guard userId > 0 && !data.isEmpty else {
            log("API", "  → Skipped (no data or no userId)")
            results["Steps"]?.apiStatus    = "skip"
            results["Calories"]?.apiStatus = "skip"
            markSynced(SyncKey.steps,    countKey: SyncCountKey.steps,    bleCount: 0)
            markSynced(SyncKey.calories, countKey: SyncCountKey.calories, bleCount: 0)
            finishSync()
            return
        }

        // Build UTC-day date string for API comparison
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let today = Date()
        let utcStart = utcCal.startOfDay(for: today)
        guard let utcEnd = utcCal.date(byAdding: .day, value: 1, to: utcStart) else {
            finishSync(); return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let dateString = dateFormatter.string(from: today)

        // Filter BLE data to UTC day only
        let bleTimestamps = data.filter {
            let ts = Date(timeIntervalSince1970: TimeInterval($0.startTimeStamp))
            return ts >= utcStart && ts < utcEnd
        }

        log("API", "  ─── [1/2] Steps ────────────────────────────")

        // Compare with API before uploading steps
        HealthService.shared.getRingDataByType(userId: userId, type: "steps", selectedDate: dateString) { [weak self] result in
            guard let self = self else { return }

            let missingSteps: [YCHealthDataStep]
            switch result {
            case .success(let response):
                let apiTs = Set(response.data.map { Int64($0.timestamp) })
                missingSteps = bleTimestamps.filter { !apiTs.contains(Int64($0.startTimeStamp)) }
                if missingSteps.isEmpty {
                    self.log("API", "  ✅ Steps already up to date — skipping upload")
                } else {
                    self.log("API", "  → Uploading \(missingSteps.count) missing step entries  [steps]…")
                }
            case .failure:
                // If check fails, fall back to uploading all BLE entries
                missingSteps = bleTimestamps
                self.log("API", "  → API check failed — uploading \(missingSteps.count) step entries  [steps]…")
            }

            let uploadSteps: () -> Void = {
                if missingSteps.isEmpty {
                    self.results["Steps"]?.apiStatus = "✅"
                    self.markSynced(SyncKey.steps, countKey: SyncCountKey.steps, bleCount: data.count)
                    self.uploadCalories(data: data, bleTimestamps: bleTimestamps, dateString: dateString)
                    return
                }
                let stepValues = missingSteps.map { RingValueEntry(value: String($0.step), timestamp: Int64($0.startTimeStamp)) }
                HealthService.shared.saveHealthDataBatch(userId: self.userId, type: "steps", values: stepValues) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let resp):
                        self.log("API", "  ✅ Steps upload success · \(resp.message)")
                        self.results["Steps"]?.apiStatus = "✅"
                        self.markSynced(SyncKey.steps, countKey: SyncCountKey.steps, bleCount: data.count)
                    case .failure(let err):
                        self.log("API", "  ❌ Steps upload failed  · \(err.localizedDescription)")
                        self.results["Steps"]?.apiStatus = "❌"
                    }
                    self.uploadCalories(data: data, bleTimestamps: bleTimestamps, dateString: dateString)
                }
            }
            uploadSteps()
        }
    }

    private func uploadCalories(data: [YCHealthDataStep], bleTimestamps: [YCHealthDataStep], dateString: String) {
        log("API", "  ─── [2/2] Calories ─────────────────────────")

        HealthService.shared.getRingDataByType(userId: userId, type: "calories", selectedDate: dateString) { [weak self] result in
            guard let self = self else { return }

            let missingCals: [YCHealthDataStep]
            switch result {
            case .success(let response):
                let apiTs = Set(response.data.map { Int64($0.timestamp) })
                missingCals = bleTimestamps.filter { !apiTs.contains(Int64($0.startTimeStamp)) }
                if missingCals.isEmpty {
                    self.log("API", "  ✅ Calories already up to date — skipping upload")
                } else {
                    self.log("API", "  → Uploading \(missingCals.count) missing calorie entries  [calories]…")
                }
            case .failure:
                missingCals = bleTimestamps
                self.log("API", "  → API check failed — uploading \(missingCals.count) calorie entries  [calories]…")
            }

            if missingCals.isEmpty {
                self.results["Calories"]?.apiStatus = "✅"
                self.markSynced(SyncKey.calories, countKey: SyncCountKey.calories, bleCount: data.count)
                self.beginSleep()
                return
            }
            let calValues = missingCals.map { RingValueEntry(value: String($0.calories), timestamp: Int64($0.startTimeStamp)) }
            HealthService.shared.saveHealthDataBatch(userId: self.userId, type: "calories", values: calValues) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let resp):
                    self.log("API", "  ✅ Calories upload success · \(resp.message)")
                    self.results["Calories"]?.apiStatus = "✅"
                    self.markSynced(SyncKey.calories, countKey: SyncCountKey.calories, bleCount: data.count)
                case .failure(let err):
                    self.log("API", "  ❌ Calories upload failed  · \(err.localizedDescription)")
                    self.results["Calories"]?.apiStatus = "❌"
                }
                self.beginSleep()
            }
        }
    }
}

// MARK: - Phase 5: Sleep

extension BackgroundSyncManager {
    fileprivate func beginSleep() {
        currentPhase   = .sleep
        phaseStartTime = Date()
        log("PHASE", "── Phase 5 / 5 : Sleep ────────────────────────────────")

        // Check if today's sleep data is already in local DB — skip BLE if so
        let repo = SleepRepository()
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let utcStart = utcCal.startOfDay(for: Date())
        let utcEnd   = utcCal.date(byAdding: .day, value: 1, to: utcStart)!
        let todaySessions = repo.getByDateRange(startDate: utcStart, endDate: utcEnd)

        if !todaySessions.isEmpty {
            log("BLE", "  ✅ Sleep data already exists for today (\(todaySessions.count) session(s)) — skipping BLE")
            results["Sleep"] = VitalResult(bleCount: 0, bleStatus: "–", apiStatus: "–", duration: 0)
            finishSync()
            return
        }

        log("BLE", "  → Querying device for sleep data…")
        sleepHelper = SleepSyncHelper(listener: self)
        sleepHelper?.startSync()
    }
}

extension BackgroundSyncManager: SleepSyncListener {
    func onSleepDataFetched(sessions: [YCHealthDataSleep]) {
        let duration = Date().timeIntervalSince(phaseStartTime)
        log("BLE", "  ✅ Sleep BLE done — \(sessions.count) sessions (save+upload running in background)")
        results["Sleep"] = VitalResult(bleCount: sessions.count,
                                        bleStatus: sessions.isEmpty ? "–" : "✅",
                                        apiStatus: sessions.isEmpty ? "–" : "✅",
                                        duration: duration)
        finishSync()
    }

    func onLocalDataSaved(count: Int) {
        // no-op in BGSync context — handled inside SleepSyncHelper
    }

    func onDayDataLoaded(sessions: [SleepSessionEntity]) {
        // no-op in BGSync context
    }
}

extension BackgroundSyncManager: HeartRateSyncHelper.HeartRateSyncListener {
    func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate]) {
        log("BLE", "  ✅ HR BLE fetch done — \(data.count) entries received, saved to local DB")
        uploadHeartRateThenContinue(data)
    }

    func onLocalDataFetched(_ data: [(timestamp: Int64, bpm: Int)]) {
        // No-op: BackgroundSyncManager uses raw BLE data directly
    }
}

// MARK: - BloodPressureSyncHelper.BloodPressureSyncListener

extension BackgroundSyncManager: BloodPressureSyncHelper.BloodPressureSyncListener {
    func onBloodPressureDataFetched(_ data: [YCHealthDataBloodPressure]) {
        log("BLE", "✅ BP BLE+local done (\(data.count) entries) → uploading to API")
        uploadBloodPressureThenContinue(data)
    }

    func onLocalDataFetched(data: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)]) {
        // No-op
    }
}

// MARK: - StepsSyncHelper.StepsSyncListener

extension BackgroundSyncManager: StepsSyncHelper.StepsSyncListener {
    func onStepsDataFetched(_ data: [YCHealthDataStep]) {
        log("BLE", "  ✅ Steps BLE fetch done — \(data.count) entries received, saved to local DB")
        uploadStepsThenCalories(data)
    }

    func onLocalDataFetched(_ data: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)]) {
        // No-op
    }
}

// MARK: - CombinedDataSyncHelper.CombinedDataSyncListener

extension BackgroundSyncManager: CombinedDataSyncHelper.CombinedDataSyncListener {
    func onCombinedDataFetched(
        hrv: [YCHealthDataCombinedData],
        bloodOxygen: [YCHealthDataCombinedData],
        bloodGlucose: [YCHealthDataCombinedData],
        temperature: [YCHealthDataCombinedData]
    ) {
        log("BLE", "✅ Combined BLE+local done → uploading HRV→O₂→Glucose→Temp to API sequentially")
        // Local saves happen concurrently in the helper (CombinedDataSyncHelper.saveToLocalDatabases).
        // We use the raw BLE data arrays directly for API upload — no need to re-read local DB.
        uploadCombinedSequentially(hrv: hrv, bloodOxygen: bloodOxygen,
                                   bloodGlucose: bloodGlucose, temperature: temperature)
    }

    func onLocalDataFetched(
        hrv: [(timestamp: Int64, hrvValue: Int)],
        bloodOxygen: [(timestamp: Int64, oxygenValue: Int)],
        bloodGlucose: [(timestamp: Int64, glucoseValue: Double)],
        temperature: [(timestamp: Int64, temperatureValue: Double)]
    ) {
        // No-op
    }
}

// MARK: - Shared onSyncFailed / onUpToDate (satisfies all listener protocols)

extension BackgroundSyncManager {
    /// Called by any helper when BLE fetch fails.
    /// Always moves to the next phase so the overall sync doesn't get stuck.
    func onSyncFailed(error: String) {
        log("BLE", "❌ Phase \(currentPhase) BLE sync failed: \(error) — proceeding to next phase")
        switch currentPhase {
        case .heartRate:     beginBloodPressure()
        case .bloodPressure: beginCombined()
        case .combined:      beginSteps()
        case .steps:         beginSleep()
        case .sleep:         finishSync()
        }
    }

    /// Called by any helper when data is still within the measurement interval.
    /// Skips the phase and moves to the next one — no timestamp update needed.
    func onUpToDate() {
        log("BLE", "✅ Phase \(currentPhase) is up to date — skipping to next phase")
        switch currentPhase {
        case .heartRate:     beginBloodPressure()
        case .bloodPressure: beginCombined()
        case .combined:      beginSteps()
        case .steps:         beginSleep()
        case .sleep:         finishSync()
        }
    }
}

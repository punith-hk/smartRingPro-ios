import UIKit
import YCProductSDK

/// Sync helper dedicated to the Calories screen.
/// Pulls step/activity data from the BLE ring (which contains calories),
/// saves to local StepsRepository, and keeps the API in sync.
class CaloriesSyncHelper {

    protocol CaloriesSyncListener: AnyObject {
        /// Called after BLE ring data is saved to local DB
        func onCaloriesDataFetched(_ data: [YCHealthDataStep])
        /// Called with local DB entries ready to display
        func onLocalCaloriesDataFetched(_ data: [(timestamp: Int64, calories: Int)])
        /// Called on any failure
        func onCaloriesSyncFailed(error: String)
        /// Called when data is still within the measurement interval — BLE skipped.
        func onCaloriesUpToDate()
    }

    private weak var listener: CaloriesSyncListener?
    private let TAG = "CaloriesSyncHelper"
    private let repository: StepsRepository

    /// Prevents duplicate API uploads within the same session
    private var lastUploadedDateString: String?

    init(listener: CaloriesSyncListener) {
        self.listener = listener
        self.repository = StepsRepository()
    }

    // MARK: - BLE Sync (Ring → Local DB → API)

    /// Entry point: pulls data from ring, saves to local DB, then syncs to API.
    /// No-op if BLE device is not connected.
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onCaloriesSyncFailed(error: "No device connected")
            return
        }
        if SyncFreshnessChecker.isUpToDate(lastSyncKey: SyncFreshnessChecker.SyncTimeKey.calories) {
            print("[\(TAG)] ✅ Data is up to date — skipping BLE query")
            listener?.onCaloriesUpToDate()
            return
        }
        print("[\(TAG)] 🔄 Starting BLE sync for calories...")
        fetchFromRing()
    }

    private func fetchFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.step) { [weak self] state, datas in
            guard let self = self else { return }

            switch state {
            case .succeed:
                if let stepDatas = datas as? [YCHealthDataStep] {
                    print("[\(self.TAG)] ✅ Fetched \(stepDatas.count) entries from BLE")
                    self.saveToLocalDB(stepDatas)
                } else {
                    self.listener?.onCaloriesSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No data on device")
                DispatchQueue.main.async { self.listener?.onCaloriesDataFetched([]) }
            case .unavailable, .failed:
                self.listener?.onCaloriesSyncFailed(error: "BLE fetch failed")
            @unknown default:
                self.listener?.onCaloriesSyncFailed(error: "Unknown BLE state")
            }
        }
    }

    private func saveToLocalDB(_ datas: [YCHealthDataStep]) {
        let readings: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)] = datas.map {
            (timestamp: Int64($0.startTimeStamp),
             steps: Int($0.step),
             distance: Int($0.distance),
             calories: Int($0.calories))
        }

        repository.saveNewBatch(readings: readings) { [weak self] success, savedCount in
            guard let self = self else { return }

            if success {
                print("[\(self.TAG)] 💾 Saved \(savedCount) new entries, \(readings.count - savedCount) duplicates")
                if savedCount > 0 { self.lastUploadedDateString = nil }
                DispatchQueue.main.async { self.listener?.onCaloriesDataFetched(datas) }
            } else {
                DispatchQueue.main.async {
                    self.listener?.onCaloriesSyncFailed(error: "Failed to save to local DB")
                }
            }
        }
    }

    // MARK: - Local DB Fetch (for chart display)

    /// Reads calories for a specific date from local DB, then triggers API sync in background.
    func fetchDataForDate(userId: Int, date: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else {
            listener?.onLocalCaloriesDataFetched([])
            return
        }

        let entries = repository.getByDateRange(start: start, end: end)
        let sorted = entries
            .map { (timestamp: $0.timestamp, calories: Int($0.calories)) }
            .sorted { $0.timestamp < $1.timestamp }

        let total = sorted.reduce(0) { $0 + $1.calories }
        print("[\(TAG)] 📊 Loaded \(sorted.count) entries | Total: \(total) kcal")

        listener?.onLocalCaloriesDataFetched(sorted)

        // Compare with API in background and upload if mismatch
        syncWithAPI(userId: userId, date: date, localData: sorted)
    }

    // MARK: - API Sync

    private func syncWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, calories: Int)]) {
        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy"
        let dateStr = df.string(from: date)

        guard lastUploadedDateString != dateStr else { return }

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let utcStart = utcCalendar.startOfDay(for: date)
        guard let utcEnd = utcCalendar.date(byAdding: .day, value: 1, to: utcStart) else { return }
        let dataForComparison = localData.filter {
            let ts = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
            return ts >= utcStart && ts < utcEnd
        }

        HealthService.shared.getRingDataByType(userId: userId, type: "calories", selectedDate: dateStr) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }
                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ API already in sync")
                    self.lastUploadedDateString = dateStr
                } else {
                    print("[\(self.TAG)] ⚠️ Missing \(missingEntries.count) entries — uploading")
                    self.uploadToAPI(userId: userId, date: date, data: missingEntries)
                }
            case .failure(let err):
                print("[\(self.TAG)] ❌ API compare failed: \(err)")
            }
        }
    }

    private func uploadToAPI(userId: Int, date: Date, data: [(timestamp: Int64, calories: Int)]) {
        guard !data.isEmpty else { return }

        let df = DateFormatter()
        df.dateFormat = "M/d/yyyy"
        let dateStr = df.string(from: date)

        let values = data.map { RingValueEntry(value: String($0.calories), timestamp: $0.timestamp) }
        print("[\(TAG)] 📤 Uploading \(values.count) calorie entries...")

        HealthService.shared.saveHealthDataBatch(userId: userId, type: "calories", values: values) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                print("[\(self.TAG)] ✅ Upload success: \(resp.message)")
                self.lastUploadedDateString = dateStr
            case .failure(let err):
                print("[\(self.TAG)] ❌ Upload failed: \(err)")
            }
        }
    }
    
}

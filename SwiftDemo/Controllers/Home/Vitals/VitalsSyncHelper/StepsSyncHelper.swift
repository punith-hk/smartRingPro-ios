import UIKit
import YCProductSDK

class StepsSyncHelper {
    
    protocol StepsSyncListener: AnyObject {
        func onStepsDataFetched(_ data: [YCHealthDataStep])
        func onSyncFailed(error: String)
        func onLocalDataFetched(_ data: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)])
        /// Called when data is still within the measurement interval — BLE skipped.
        func onUpToDate()
    }
    
    private weak var listener: StepsSyncListener?
    private let TAG = "StepsSyncHelper"
    private let repository: StepsRepository
    
    // Track last uploaded date to prevent duplicate uploads within one VC session
    private var lastUploadedDateString: String?
    
    init(listener: StepsSyncListener) {
        self.listener = listener
        self.repository = StepsRepository()
    }
    
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        if SyncFreshnessChecker.isUpToDate(lastSyncKey: SyncFreshnessChecker.SyncTimeKey.steps) {
            print("[\(TAG)] ✅ Data is up to date — skipping BLE query")
            listener?.onUpToDate()
            return
        }
        print("[\(TAG)] 🔄 Starting BLE sync for steps...")
        fetchStepsFromRing()
    }
    
    private func fetchStepsFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.step) { [weak self] state, datas in
            guard let self = self else { return }
            
            switch state {
            case .succeed:
                if let stepDatas = datas as? [YCHealthDataStep] {
                    print("[\(self.TAG)] ✅ Fetched \(stepDatas.count) step entries from BLE")
                    self.processStepsData(stepDatas)
                } else {
                    print("[\(self.TAG)] ❌ Invalid data format")
                    self.listener?.onSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No step data on device")
                self.listener?.onStepsDataFetched([])
            case .unavailable, .failed:
                print("[\(self.TAG)] ❌ BLE fetch failed: \(state)")
                self.listener?.onSyncFailed(error: "Fetch failed")
            @unknown default:
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processStepsData(_ datas: [YCHealthDataStep]) {
        saveToLocalDatabase(datas)
    }
    
    private func saveToLocalDatabase(_ datas: [YCHealthDataStep]) {
        // Map YCHealthDataStep to repository format
        let readings: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)] = datas.map { data in
            (
                timestamp: Int64(data.startTimeStamp),
                steps: Int(data.step),
                distance: Int(data.distance),  // meters
                calories: Int(data.calories)   // kcal
            )
        }
        
        repository.saveNewBatch(readings: readings) { [weak self] success, savedCount in
            guard let self = self else { return }
            
            if success {
                print("[\(self.TAG)] 💾 Saved \(savedCount) new entries, \(readings.count - savedCount) duplicates")
                
                // Clear upload flag when new data is saved
                if savedCount > 0 {
                    self.lastUploadedDateString = nil
                }
                
                DispatchQueue.main.async {
                    self.listener?.onStepsDataFetched(datas)
                }
            } else {
                print("[\(self.TAG)] ❌ Database save failed")
                DispatchQueue.main.async {
                    self.listener?.onSyncFailed(error: "Failed to save to local database")
                }
            }
        }
    }
    
    // MARK: - Fetch Data from Local DB
    
    /// Fetch steps data for a specific date from local database
    /// Also triggers API comparison in background
    func fetchDataForDate(userId: Int, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            listener?.onLocalDataFetched([])
            return
        }
        
        let entries = repository.getByDateRange(start: startOfDay, end: endOfDay)
        let sortedData = entries.map { 
            (
                timestamp: $0.timestamp,
                steps: Int($0.steps),
                distance: Int($0.distance),
                calories: Int($0.calories)
            )
        }.sorted { $0.timestamp < $1.timestamp }
        
        print("[\(TAG)] 📊 Loaded \(sortedData.count) step entries from local DB")
        
        // Calculate totals for the day
        let totalSteps = sortedData.reduce(0) { $0 + $1.steps }
        let totalDistance = sortedData.reduce(0) { $0 + $1.distance }
        let totalCalories = sortedData.reduce(0) { $0 + $1.calories }
        
        print("[\(TAG)] 📊 Day totals: \(totalSteps) steps, \(totalDistance)m, \(totalCalories) kcal")
        
        listener?.onLocalDataFetched(sortedData)
        
        // Compare with API in background
        compareAndSyncWithAPI(userId: userId, date: date, localData: sortedData)
    }
    
    // MARK: - API Sync
    
    /// Compare local DB data with API data and upload if mismatch
    private func compareAndSyncWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        // Skip if already uploaded this date
        if lastUploadedDateString == dateString {
            return
        }
        
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let utcStart = utcCalendar.startOfDay(for: date)
        guard let utcEnd = utcCalendar.date(byAdding: .day, value: 1, to: utcStart) else { return }
        let dataForComparison = localData.filter {
            let ts = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
            return ts >= utcStart && ts < utcEnd
        }
        
        HealthService.shared.getRingDataByType(
            userId: userId,
            type: "steps",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }

                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ API synced")
                    self.lastUploadedDateString = dateString
                } else {
                    print("[\(self.TAG)] ⚠️ API missing \(missingEntries.count) entries — uploading")
                    self.uploadStepsDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ API comparison failed: \(error)")
            }
        }
    }
    
    /// Upload steps data to API for a specific date
    private func uploadStepsDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String($0.steps), timestamp: $0.timestamp) }
        let latestEntry = data.last
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) step entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "steps",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Upload successful: \(response.message)")
                if let latest = latestEntry {
                    UserDefaults.standard.set(latest.timestamp, forKey: "last_uploaded_steps_timestamp")
                    UserDefaults.standard.set(latest.steps, forKey: "last_uploaded_steps_value")
                }
                self.lastUploadedDateString = dateString
            case .failure(let error):
                print("[\(self.TAG)] ❌ Upload failed: \(error)")
            }
        }
    }
    
}

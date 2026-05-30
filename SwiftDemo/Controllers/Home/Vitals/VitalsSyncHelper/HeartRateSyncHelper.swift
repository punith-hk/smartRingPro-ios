import UIKit
import YCProductSDK

class HeartRateSyncHelper {
    
    protocol HeartRateSyncListener: AnyObject {
        func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate])
        func onSyncFailed(error: String)
        func onLocalDataFetched(_ data: [(timestamp: Int64, bpm: Int)])
        /// Called when data is still within the measurement interval — BLE skipped.
        func onUpToDate()
    }
    
    private weak var listener: HeartRateSyncListener?
    private let TAG = "HeartRateSyncHelper"
    private let repository: HeartRateRepository
    
    // Track last uploaded date to prevent duplicate uploads within one VC session
    private var lastUploadedDateString: String?
    
    init(listener: HeartRateSyncListener) {
        self.listener = listener
        self.repository = HeartRateRepository()
    }
    
    func startSync(force: Bool = false) {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        if !force && SyncFreshnessChecker.isUpToDate(lastSyncKey: SyncFreshnessChecker.SyncTimeKey.heartRate) {
            print("[\(TAG)] ✅ Data is up to date — skipping BLE query")
            listener?.onUpToDate()
            return
        }
        print("[\(TAG)] 🔄 Starting BLE sync...")
        fetchHeartRateFromRing()
    }
    
    private func fetchHeartRateFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.heartRate) { [weak self] state, datas in
            guard let self = self else { return }
            
            switch state {
            case .succeed:
                if let heartRateDatas = datas as? [YCHealthDataHeartRate] {
                    print("[\(self.TAG)] ✅ Fetched \(heartRateDatas.count) entries from BLE")
                    self.processHeartRateData(heartRateDatas)
                } else {
                    print("[\(self.TAG)] ❌ Invalid data format")
                    self.listener?.onSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No data on device")
                self.listener?.onHeartRateDataFetched([])
            case .unavailable, .failed:
                print("[\(self.TAG)] ❌ BLE fetch failed: \(state)")
                self.listener?.onSyncFailed(error: "Fetch failed")
            @unknown default:
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processHeartRateData(_ datas: [YCHealthDataHeartRate]) {
        saveToLocalDatabase(datas)
    }
    
    private func saveToLocalDatabase(_ datas: [YCHealthDataHeartRate]) {
        let readings: [(timestamp: Int64, bpm: Int)] = datas.map { data in
            (timestamp: Int64(data.startTimeStamp), bpm: Int(data.heartRate))
        }
        
        repository.saveNewBatch(readings: readings) { [weak self] success, savedCount in
            guard let self = self else { return }
            
            if success {
                print("[\(self.TAG)] 💾 Saved \(savedCount) new, \(readings.count - savedCount) duplicates")
                
                // Clear upload flag when new data is saved
                if savedCount > 0 {
                    self.lastUploadedDateString = nil
                }
                
                DispatchQueue.main.async {
                    self.listener?.onHeartRateDataFetched(datas)
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
    
    /// Fetch heart rate data for a specific date from local database
    /// Also triggers API comparison in background
    func fetchDataForDate(userId: Int, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            listener?.onLocalDataFetched([])
            return
        }
        
        let entries = repository.getByDateRange(start: startOfDay, end: endOfDay)
        let sortedData = entries.map { (timestamp: $0.timestamp, bpm: Int($0.bpm)) }
            .sorted { $0.timestamp < $1.timestamp }
        
        print("[\(TAG)] 📊 Loaded \(sortedData.count) entries from local DB")
        listener?.onLocalDataFetched(sortedData)
        
        // Compare with API in background
        compareAndSyncWithAPI(userId: userId, date: date, localData: sortedData)
    }
    
    // MARK: - API Sync
    
    /// Compare local DB data with API data and upload if mismatch
    private func compareAndSyncWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, bpm: Int)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        // Skip if already uploaded this date
        if lastUploadedDateString == dateString {
            return
        }
        
        // The server filters entries by UTC date from the timestamp.
        // Only compare entries whose timestamp falls on this UTC day,
        // so local data and API data use the same date boundary.
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let utcStart = utcCalendar.startOfDay(for: date)
        guard let utcEnd = utcCalendar.date(byAdding: .day, value: 1, to: utcStart) else { return }
        let dataForComparison = localData.filter {
            let ts = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
            return ts >= utcStart && ts < utcEnd
        }
        
        // --- DIAGNOSTIC LOGS ---
        print("[\(TAG)] ========== HEART RATE SYNC ANALYSIS ==========")
        print("[\(TAG)] 📅 Date queried : \(dateString)")
        print("[\(TAG)] 🌍 UTC window   : \(utcStart) → \(utcEnd)")
        print("[\(TAG)] 📱 LOCAL total  : \(localData.count) entries (IST day)")
        print("[\(TAG)] 📱 LOCAL utc    : \(dataForComparison.count) entries (UTC-filtered, used for API compare)")
        localData.forEach { entry in
            let ts = Date(timeIntervalSince1970: TimeInterval(entry.timestamp))
            let inUtcWindow = ts >= utcStart && ts < utcEnd
            print("[\(TAG)]   local ts=\(entry.timestamp) bpm=\(entry.bpm) utcTime=\(ts) inUTCWindow=\(inUtcWindow)")
        }
        // -----------------------
        
        HealthService.shared.getRingDataByType(
            userId: userId,
            type: "heart_rate",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }
                
                // --- DIAGNOSTIC LOGS ---
                print("[\(self.TAG)] 🌐 API returned : \(response.data.count) entries for \(dateString)")
                response.data.forEach { entry in
                    let ts = Date(timeIntervalSince1970: TimeInterval(entry.timestamp))
                    print("[\(self.TAG)]   api ts=\(entry.timestamp) utcTime=\(ts)")
                }
                print("[\(self.TAG)] 🔍 MISSING      : \(missingEntries.count) entries (in UTC window but not in API)")
                missingEntries.forEach { entry in
                    print("[\(self.TAG)]   missing ts=\(entry.timestamp) bpm=\(entry.bpm)")
                }
                print("[\(self.TAG)] ===============================================")
                // -----------------------
                
                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ API synced")
                    self.lastUploadedDateString = dateString
                } else {
                    print("[\(self.TAG)] ⚠️ API missing \(missingEntries.count) entr\(missingEntries.count == 1 ? "y" : "ies") — uploading")
                    self.uploadHeartRateDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ API comparison failed: \(error)")
            }
        }
    }
    
    /// Upload heart rate data to API for a specific date
    private func uploadHeartRateDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, bpm: Int)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String($0.bpm), timestamp: $0.timestamp) }
        let latestEntry = data.last
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "heart_rate",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Upload successful: \(response.message)")
                
                // Save last uploaded entry
                if let latest = latestEntry {
                    UserDefaults.standard.set(latest.timestamp, forKey: "last_uploaded_heart_rate_timestamp")
                    UserDefaults.standard.set(latest.bpm, forKey: "last_uploaded_heart_rate_value")
                }
                
                // Mark date as uploaded
                self.lastUploadedDateString = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Upload failed: \(error)")
            }
        }
    }
    
}

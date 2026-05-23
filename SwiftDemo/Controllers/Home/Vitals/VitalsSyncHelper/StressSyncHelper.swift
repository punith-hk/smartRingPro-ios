import UIKit
import YCProductSDK

class StressSyncHelper {
    
    protocol StressSyncListener: AnyObject {
        func onStressDataFetched(_ data: [YCHealthDataBodyIndexData])
        func onSyncFailed(error: String)
        func onLocalDataFetched(_ data: [(timestamp: Int64, level: Int)])
    }
    
    private weak var listener: StressSyncListener?
    private let TAG = "StressSyncHelper"
    private let repository: StressRepository
    
    // Track last uploaded date to prevent duplicate uploads
    private var lastUploadedDateString: String?
    
    init(listener: StressSyncListener) {
        self.listener = listener
        self.repository = StressRepository()
    }
    
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        
        print("[\(TAG)] 🔄 Starting BLE sync...")
        fetchStressFromRing()
    }
    
    private func fetchStressFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.bodyIndexData) { [weak self] state, datas in
            guard let self = self else { return }
            
            switch state {
            case .succeed:
                if let bodyIndexDatas = datas as? [YCHealthDataBodyIndexData] {
                    print("[\(self.TAG)] ✅ Fetched \(bodyIndexDatas.count) stress entries from BLE")
                    self.processStressData(bodyIndexDatas)
                } else {
                    print("[\(self.TAG)] ❌ Invalid data format")
                    self.listener?.onSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No stress data on device")
                self.listener?.onStressDataFetched([])
            case .unavailable, .failed:
                print("[\(self.TAG)] ❌ BLE fetch failed: \(state)")
                self.listener?.onSyncFailed(error: "Fetch failed")
            @unknown default:
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processStressData(_ datas: [YCHealthDataBodyIndexData]) {
        saveToLocalDatabase(datas)
    }
    
    private func saveToLocalDatabase(_ datas: [YCHealthDataBodyIndexData]) {
        let readings: [(timestamp: Int64, level: Int)] = datas.map { data in
            (timestamp: Int64(data.startTimeStamp), level: Int(data.pressureIndex))
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
                    self.listener?.onStressDataFetched(datas)
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
    
    /// Fetch stress data for a specific date from local database
    /// Also triggers API comparison in background
    func fetchDataForDate(userId: Int, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            listener?.onLocalDataFetched([])
            return
        }
        
        let entries = repository.getByDateRange(start: startOfDay, end: endOfDay)
        let sortedData = entries.map { (timestamp: $0.timestamp, level: Int($0.level)) }
            .sorted { $0.timestamp < $1.timestamp }
        
        print("[\(TAG)] 📊 Loaded \(sortedData.count) entries from local DB")
        listener?.onLocalDataFetched(sortedData)
        
        // Compare with API in background
        compareAndSyncWithAPI(userId: userId, date: date, localData: sortedData)
    }
    
    // MARK: - API Sync
    
    /// Compare local DB data with API data and upload if mismatch
    private func compareAndSyncWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, level: Int)]) {
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
            type: "stress",
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
                    self.uploadStressDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ API comparison failed: \(error)")
            }
        }
    }
    
    /// Upload stress data to API for a specific date
    private func uploadStressDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, level: Int)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String($0.level), timestamp: $0.timestamp) }
        let latestEntry = data.last
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "stress",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Upload successful: \(response.message)")
                
                // Save last uploaded entry
                if let latest = latestEntry {
                    UserDefaults.standard.set(latest.timestamp, forKey: "last_uploaded_stress_timestamp")
                    UserDefaults.standard.set(latest.level, forKey: "last_uploaded_stress_value")
                }
                
                // Mark date as uploaded
                self.lastUploadedDateString = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Upload failed: \(error)")
            }
        }
    }
}

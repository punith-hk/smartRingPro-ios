import UIKit
import YCProductSDK

class HeartRateSyncHelper {
    
    protocol HeartRateSyncListener: AnyObject {
        func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate])
        func onSyncFailed(error: String)
        func onLocalDataFetched(_ data: [(timestamp: Int64, bpm: Int)])
    }
    
    private weak var listener: HeartRateSyncListener?
    private let TAG = "HeartRateSyncHelper"
    private let repository: HeartRateRepository
    
    // Track last uploaded date to prevent duplicate uploads
    private var lastUploadedDateString: String?
    
    init(listener: HeartRateSyncListener) {
        self.listener = listener
        self.repository = HeartRateRepository()
    }
    
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onSyncFailed(error: "No device connected")
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
        
        HealthService.shared.getRingDataByType(
            userId: userId,
            type: "heart_rate",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiData = response.data
                let countMatches = localData.count == apiData.count
                
                // Compare latest entry (API returns descending, local is ascending)
                var latestMatches = true
                if let localLatest = localData.last, let apiLatest = apiData.first {
                    let apiTimestamp = Int64(apiLatest.timestamp)
                    let apiBpm = Int(apiLatest.value) ?? 0
                    latestMatches = (localLatest.timestamp == apiTimestamp && localLatest.bpm == apiBpm)
                }
                
                if !countMatches || !latestMatches {
                    print("[\(self.TAG)] ⚠️ API mismatch - Local: \(localData.count), API: \(apiData.count)")
                    self.uploadHeartRateDataToAPI(userId: userId, date: date, data: localData)
                } else {
                    print("[\(self.TAG)] ✅ API synced")
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

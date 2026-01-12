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
    
    init(listener: HeartRateSyncListener) {
        self.listener = listener
        self.repository = HeartRateRepository()
        print("[HeartRateSyncHelper] ✅ Initialized with repository")
    }
    
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            print("[\(TAG)] ❌ No BLE device connected, skipping heart rate sync")
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        
        print("[\(TAG)] 🟢 Starting heart rate sync from BLE device")
        fetchHeartRateFromRing()
    }
    
    private func fetchHeartRateFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.heartRate) { [weak self] state, datas in
            guard let self = self else { 
                print("[HeartRateSyncHelper] ⚠️ Self is nil in completion handler")
                return 
            }
            
            print("[\(self.TAG)] 🔵 Completion handler called")
            print("[\(self.TAG)] 📦 State received: \(state)")
            print("[\(self.TAG)] 📦 Data type: \(type(of: datas))")
            print("[\(self.TAG)] 📦 Data: \(String(describing: datas))")
            
            switch state {
            case .succeed:
                print("[\(self.TAG)] ✅ State is .succeed")
                if let heartRateDatas = datas as? [YCHealthDataHeartRate] {
                    print("[\(self.TAG)] ✅ Successfully cast to [YCHealthDataHeartRate], count: \(heartRateDatas.count)")
                    self.processHeartRateData(heartRateDatas)
                } else {
                    print("[\(self.TAG)] ❌ Failed to cast data to [YCHealthDataHeartRate]")
                    print("[\(self.TAG)] ❌ Actual data type: \(type(of: datas))")
                    self.listener?.onSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No heart rate data found on device")
                self.listener?.onHeartRateDataFetched([])
            case .unavailable:
                print("[\(self.TAG)] ⚠️ Heart rate data unavailable")
                self.listener?.onSyncFailed(error: "Data unavailable")
            case .failed:
                print("[\(self.TAG)] ❌ Failed to fetch heart rate data")
                self.listener?.onSyncFailed(error: "Fetch failed")
            @unknown default:
                print("[\(self.TAG)] ❓ Unknown state received: \(state)")
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processHeartRateData(_ datas: [YCHealthDataHeartRate]) {
        print("[\(TAG)] 📊 Total entries fetched from BLE: \(datas.count)")
        
        // Print last 5 entries for debugging
        if !datas.isEmpty {
            printLast5Entries(datas)
        }
        
        // Phase 2: Save to local database (deduplication happens in repository)
        // Notification to listener will happen AFTER save completes
        saveToLocalDatabase(datas)
    }
    
    private func saveToLocalDatabase(_ datas: [YCHealthDataHeartRate]) {
        print("[\(TAG)] 💾 Saving to local database...")
        
        // Convert BLE data to repository format
        let readings: [(timestamp: Int64, bpm: Int)] = datas.map { data in
            // Extract timestamp and heart rate from YCHealthDataHeartRate
            let timestamp = Int64(data.startTimeStamp)
            let bpm = Int(data.heartRate)
            return (timestamp, bpm)
        }
        
        print("[\(TAG)] 📝 Prepared \(readings.count) readings for DB insertion")
        
        // Save to database using instance repository
        repository.saveNewBatch(readings: readings) { [weak self] success, savedCount in
            guard let self = self else { return }
            
            if success {
                print("[\(self.TAG)] ✅ Database save complete: \(savedCount) new entries saved")
                print("[\(self.TAG)] 🔄 Duplicates filtered: \(readings.count - savedCount)")
                
                // Print database summary
                self.repository.printSummary()
                
                // Print database file location for manual inspection
                CoreDataManager.shared.printDatabaseLocation()
                
                // ✅ Notify listener AFTER save is complete (on main thread)
                DispatchQueue.main.async {
                    self.listener?.onHeartRateDataFetched(datas)
                }
                
                // Phase 3: Later sync new entries to API
                // if savedCount > 0 {
                //     self.syncToAPI(newEntries)
                // }
            } else {
                print("[\(self.TAG)] ❌ Database save failed")
                DispatchQueue.main.async {
                    self.listener?.onSyncFailed(error: "Failed to save to local database")
                }
            }
        }
    }
    
    private func printLast5Entries(_ datas: [YCHealthDataHeartRate]) {
        let last5 = Array(datas.suffix(5))
        print("[\(TAG)] 🔥 Last 5 Heart Rate Entries:")
        for (index, entry) in last5.enumerated() {
            print("  \(index + 1). \(entry.toString)")
        }
    }
    
    // MARK: - Fetch Data from Local DB
    
    /// Fetch heart rate data for a specific date from local database
    /// Also triggers API comparison in background
    func fetchDataForDate(userId: Int, date: Date) {
        print("[\(TAG)] 📅 Fetching data from local DB for date: \(date)")
        
        // Calculate start and end of day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("[\(TAG)] ❌ Failed to calculate end of day")
            listener?.onLocalDataFetched([])
            return
        }
        
        // Fetch from repository
        let entries = repository.getByDateRange(start: startOfDay, end: endOfDay)
        print("[\(TAG)] 📊 Found \(entries.count) entries for selected date")
        
        // Convert to simple format for chart
        let data: [(timestamp: Int64, bpm: Int)] = entries.map { entry in
            (timestamp: entry.timestamp, bpm: Int(entry.bpm))
        }
        
        // Sort by timestamp ascending (oldest first, for chart)
        let sortedData = data.sorted { $0.timestamp < $1.timestamp }
        
        print("[\(TAG)] ✅ Returning \(sortedData.count) entries to listener")
        listener?.onLocalDataFetched(sortedData)
        
        // 🔄 Simultaneously compare with API data in background
        compareAndSyncWithAPI(userId: userId, date: date, localData: sortedData)
    }
    
    // MARK: - API Sync
    
    /// Compare local DB data with API data and upload if mismatch
    private func compareAndSyncWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, bpm: Int)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 🔄 Comparing local data with API for date: \(dateString)")
        
        HealthService.shared.getRingDataByType(
            userId: userId,
            type: "heart_rate",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiData = response.data
                print("[\(self.TAG)] 📊 Comparison - Local: \(localData.count) | API: \(apiData.count)")
                
                // Compare counts
                let countMatches = localData.count == apiData.count
                
                // Compare last entry (timestamp + value) if both have data
                var lastEntryMatches = true
                if let localLast = localData.last, let apiLast = apiData.last {
                    let apiTimestamp = Int64(apiLast.timestamp)
                    let apiBpm = Int(apiLast.value) ?? 0
                    
                    lastEntryMatches = (localLast.timestamp == apiTimestamp && localLast.bpm == apiBpm)
                    
                    print("[\(self.TAG)] 🔍 Last Entry - Local: [\(localLast.timestamp), \(localLast.bpm)] | API: [\(apiTimestamp), \(apiBpm)]")
                }
                
                // If mismatch detected, upload local data to API
                if !countMatches || !lastEntryMatches {
                    print("[\(self.TAG)] ⚠️ Mismatch detected! Uploading local data to API...")
                    self.uploadHeartRateDataToAPI(userId: userId, date: date, data: localData)
                } else {
                    print("[\(self.TAG)] ✅ Local and API data match, no upload needed")
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ API fetch failed: \(error) - Skipping comparison")
            }
        }
    }
    
    /// Upload heart rate data to API for a specific date
    /// TODO: Implement with POST API endpoint and payload structure
    private func uploadHeartRateDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, bpm: Int)]) {
        print("[\(TAG)] 🚀 uploadHeartRateDataToAPI called")
        print("[\(TAG)] 📤 User ID: \(userId)")
        print("[\(TAG)] 📤 Date: \(date)")
        print("[\(TAG)] 📤 Total entries to upload: \(data.count)")
        
        // TODO: Implement POST API call with payload
        // Payload structure to be provided by user
        // Format: { userId, date, heartRateData: [...] }
        
        print("[\(TAG)] ⏳ Upload function not yet implemented - waiting for API details")
    }
}

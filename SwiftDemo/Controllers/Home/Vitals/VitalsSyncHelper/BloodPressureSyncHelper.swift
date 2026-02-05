import UIKit
import YCProductSDK

/// Syncs Blood Pressure data from BLE ring
/// Unlike combined data, BP has its own separate query: YCQueryHealthDataType.bloodPressure
class BloodPressureSyncHelper {
    
    protocol BloodPressureSyncListener: AnyObject {
        func onBloodPressureDataFetched(_ data: [YCHealthDataBloodPressure])
        func onSyncFailed(error: String)
        func onLocalDataFetched(data: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)])
    }
    
    private weak var listener: BloodPressureSyncListener?
    private let TAG = "BloodPressureSyncHelper"
    
    private let bloodPressureRepository: BloodPressureRepository
    
    // Track last uploaded date to prevent duplicate uploads
    private var lastUploadedDateString: String?
    
    init(listener: BloodPressureSyncListener) {
        self.listener = listener
        self.bloodPressureRepository = BloodPressureRepository()
    }
    
    // MARK: - BLE Sync
    
    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        
        print("[\(TAG)] 🔄 Starting BLE blood pressure sync...")
        fetchBloodPressureFromRing()
    }
    
    private func fetchBloodPressureFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.bloodPressure) { [weak self] state, datas in
            guard let self = self else { return }
            
            switch state {
            case .succeed:
                if let bpData = datas as? [YCHealthDataBloodPressure] {
                    print("[\(self.TAG)] ✅ Received \(bpData.count) blood pressure readings from ring")
                    self.processBloodPressureData(bpData)
                } else {
                    print("[\(self.TAG)] ⚠️ No blood pressure data available")
                    self.listener?.onBloodPressureDataFetched([])
                }
                
            case .failed:
                print("[\(self.TAG)] ❌ BLE query failed")
                self.listener?.onSyncFailed(error: "BLE query failed")
                
            case .unsupported:
                print("[\(self.TAG)] ❌ Blood pressure query not supported")
                self.listener?.onSyncFailed(error: "Blood pressure not supported")
                
            @unknown default:
                print("[\(self.TAG)] ❌ Unknown BLE state")
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processBloodPressureData(_ datas: [YCHealthDataBloodPressure]) {
        // Print statistics
        if let first = datas.first, let last = datas.last {
            print("[\(TAG)] 📊 BP Data Range:")
            print("   - First: \(first.systolicBloodPressure)/\(first.diastolicBloodPressure) mmHg at \(first.startTimeStamp)")
            print("   - Last: \(last.systolicBloodPressure)/\(last.diastolicBloodPressure) mmHg at \(last.startTimeStamp)")
        }
        
        // Save to local database
        saveToLocalDatabase(datas)
        
        // Notify listener with BLE data
        listener?.onBloodPressureDataFetched(datas)
    }
    
    // MARK: - Save to Local DB
    
    private func saveToLocalDatabase(_ datas: [YCHealthDataBloodPressure]) {
        let readings = datas.map { data -> (timestamp: Int64, systolicValue: Int, diastolicValue: Int) in
            return (
                timestamp: Int64(data.startTimeStamp),
                systolicValue: Int(data.systolicBloodPressure),
                diastolicValue: Int(data.diastolicBloodPressure)
            )
        }
        
        bloodPressureRepository.saveNewBatch(readings: readings) { [weak self] success, savedCount in
            guard let self = self else { return }
            
            if success {
                print("[\(self.TAG)] ✅ Saved \(savedCount)/\(readings.count) blood pressure readings to local DB")
                
                // Reload data from local DB to update chart
                DispatchQueue.main.async {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
                    
                    let entries = self.bloodPressureRepository.getByDateRange(start: today, end: tomorrow)
                    let bpData = entries.map {
                        (timestamp: $0.timestamp, systolicValue: Int($0.systolicValue), diastolicValue: Int($0.diastolicValue))
                    }.sorted { $0.timestamp < $1.timestamp }
                    
                    print("[\(self.TAG)] 🔄 Reloaded \(bpData.count) readings from local DB after save")
                    self.listener?.onLocalDataFetched(data: bpData)
                }
            } else {
                print("[\(self.TAG)] ❌ Failed to save blood pressure data to local DB")
            }
        }
    }
    
    // MARK: - Fetch Data from Local DB
    
    /// Fetch blood pressure data for a specific date from local database
    /// Also triggers API comparison in background
    func fetchDataForDate(userId: Int, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            listener?.onLocalDataFetched(data: [])
            return
        }
        
        // Fetch from repository
        let entries = bloodPressureRepository.getByDateRange(start: startOfDay, end: endOfDay)
        let bpData = entries.map { 
            (timestamp: $0.timestamp, systolicValue: Int($0.systolicValue), diastolicValue: Int($0.diastolicValue))
        }.sorted { $0.timestamp < $1.timestamp }
        
        print("[\(TAG)] 📊 Loaded \(bpData.count) blood pressure readings from local DB")
        
        listener?.onLocalDataFetched(data: bpData)
        
        // Compare with API in background
        compareAndSyncWithAPI(userId: userId, date: date, localData: bpData)
    }
    
    // MARK: - API Sync
    
    private func compareAndSyncWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        if lastUploadedDateString == dateString {
            return
        }
        
        HealthService.shared.getRingDataByType(
            userId: userId,
            type: "blood_pressure",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiData = response.data
                let countMatches = localData.count == apiData.count
                
                var latestMatches = true
                if let localLatest = localData.last, let apiLatest = apiData.first {
                    let apiTimestamp = Int64(apiLatest.timestamp)
                    // BP value format from API is "120/80", parse it
                    let bpComponents = apiLatest.value.split(separator: "/").compactMap { Int($0) }
                    if bpComponents.count == 2 {
                        let apiSystolic = bpComponents[0]
                        let apiDiastolic = bpComponents[1]
                        latestMatches = (localLatest.timestamp == apiTimestamp && 
                                       localLatest.systolicValue == apiSystolic && 
                                       localLatest.diastolicValue == apiDiastolic)
                    }
                }
                
                if !countMatches || !latestMatches {
                    print("[\(self.TAG)] 🔄 Mismatch detected - uploading to API")
                    self.uploadToAPI(userId: userId, data: localData, dateString: dateString)
                } else {
                    print("[\(self.TAG)] ✅ API data matches local DB - no upload needed")
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ⚠️ API comparison failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func uploadToAPI(userId: Int, data: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)], dateString: String) {
        let bpRecords = data.map { reading -> RingValueEntry in
            return RingValueEntry(
                value: "\(reading.systolicValue)/\(reading.diastolicValue)",
                timestamp: reading.timestamp
            )
        }
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "blood_pressure",
            values: bpRecords
        ) { [weak self] (result: Result<BatchUploadResponse, NetworkError>) in
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("[\(self.TAG)] ✅ Successfully uploaded \(data.count) BP readings to API")
                self.lastUploadedDateString = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Failed to upload to API: \(error.localizedDescription)")
            }
        }
    }
}

import UIKit
import YCProductSDK

/// Syncs combined data (HRV, Temperature, Blood Glucose, Blood Oxygen) from BLE
/// Used for day view - fetches all 4 vitals in one BLE call
class CombinedDataSyncHelper {
    
    protocol CombinedDataSyncListener: AnyObject {
        func onCombinedDataFetched(
            hrv: [YCHealthDataCombinedData],
            bloodOxygen: [YCHealthDataCombinedData],
            bloodGlucose: [YCHealthDataCombinedData],
            temperature: [YCHealthDataCombinedData]
        )
        func onSyncFailed(error: String)
        func onLocalDataFetched(
            hrv: [(timestamp: Int64, hrvValue: Int)],
            bloodOxygen: [(timestamp: Int64, oxygenValue: Int)],
            bloodGlucose: [(timestamp: Int64, glucoseValue: Double)],
            temperature: [(timestamp: Int64, temperatureValue: Double)]
        )
        /// Called when data is still within the measurement interval — BLE skipped.
        func onUpToDate()
    }
    
    private weak var listener: CombinedDataSyncListener?
    private let TAG = "CombinedDataSyncHelper"
    
    private let hrvRepository: HrvRepository
    private let bloodOxygenRepository: BloodOxygenRepository
    private let bloodGlucoseRepository: BloodGlucoseRepository
    private let temperatureRepository: TemperatureRepository
    
    // Track last uploaded dates to prevent duplicate uploads
    private var lastUploadedDateStrings: [String: String] = [:] // [type: dateString]
    
    init(listener: CombinedDataSyncListener) {
        self.listener = listener
        self.hrvRepository = HrvRepository()
        self.bloodOxygenRepository = BloodOxygenRepository()
        self.bloodGlucoseRepository = BloodGlucoseRepository()
        self.temperatureRepository = TemperatureRepository()
    }
    
    // MARK: - BLE Sync

    func startSync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            listener?.onSyncFailed(error: "No device connected")
            return
        }
        if SyncFreshnessChecker.isUpToDate(lastSyncKey: SyncFreshnessChecker.SyncTimeKey.combined) {
            print("[\(TAG)] ✅ Data is up to date — skipping BLE query")
            listener?.onUpToDate()
            return
        }
        print("[\(TAG)] 🔄 Starting BLE combined data sync...")
        fetchCombinedDataFromRing()
    }
    
    private func fetchCombinedDataFromRing() {
        YCProduct.queryHealthData(dataType: YCQueryHealthDataType.combinedData) { [weak self] state, datas in
            guard let self = self else { return }
            
            switch state {
            case .succeed:
                if let combinedDatas = datas as? [YCHealthDataCombinedData] {
                    print("[\(self.TAG)] ✅ Fetched \(combinedDatas.count) combined entries from BLE")
                    self.processCombinedData(combinedDatas)
                } else {
                    print("[\(self.TAG)] ❌ Invalid data format")
                    self.listener?.onSyncFailed(error: "Data type mismatch")
                }
            case .noRecord:
                print("[\(self.TAG)] ℹ️ No data on device")
                self.listener?.onCombinedDataFetched(hrv: [], bloodOxygen: [], bloodGlucose: [], temperature: [])
            case .unavailable, .failed:
                print("[\(self.TAG)] ❌ BLE fetch failed: \(state)")
                self.listener?.onSyncFailed(error: "Fetch failed")
            @unknown default:
                self.listener?.onSyncFailed(error: "Unknown error")
            }
        }
    }
    
    private func processCombinedData(_ datas: [YCHealthDataCombinedData]) {
        // Print the BLE data statistics
        printCombinedData(datas)
        
        // Save to local database
        saveToLocalDatabases(datas)
    }
    
    private func printCombinedData(_ datas: [YCHealthDataCombinedData]) {
        print("[\(TAG)] 📊 ========== COMBINED DATA FROM BLE ==========")
        print("[\(TAG)] Total entries: \(datas.count)")
        print("[\(TAG)] ===============================================")
        
        // Print detailed breakdown
        let hrvValues = datas.map { $0.hrv }
        let oxygenValues = datas.map { $0.bloodOxygen }
        let glucoseValues = datas.map { $0.bloodGlucose }
        let temperatureValues = datas.filter { $0.temperatureValid }.map { $0.temperature }
        
        print("[\(TAG)] 📈 HRV Values (\(hrvValues.count) entries):")
        print("     Min: \(hrvValues.min() ?? 0)ms, Max: \(hrvValues.max() ?? 0)ms, Avg: \(hrvValues.isEmpty ? 0 : hrvValues.reduce(0, +) / hrvValues.count)ms")
        
        print("[\(TAG)] 🫁 Blood Oxygen Values (\(oxygenValues.count) entries):")
        print("     Min: \(oxygenValues.min() ?? 0)%, Max: \(oxygenValues.max() ?? 0)%, Avg: \(oxygenValues.isEmpty ? 0 : oxygenValues.reduce(0, +) / oxygenValues.count)%")
        
        print("[\(TAG)] 🩸 Blood Glucose Values (\(glucoseValues.count) entries):")
        let avgGlucose = glucoseValues.isEmpty ? 0.0 : glucoseValues.reduce(0.0, +) / Double(glucoseValues.count)
        print("     Min: \(glucoseValues.min() ?? 0.0)mg/dL, Max: \(glucoseValues.max() ?? 0.0)mg/dL, Avg: \(String(format: "%.2f", avgGlucose))mg/dL")
        
        print("[\(TAG)] 🌡️ Temperature Values (\(temperatureValues.count) valid entries out of \(datas.count)):")
        if !temperatureValues.isEmpty {
            let avgTemp = temperatureValues.reduce(0.0, +) / Double(temperatureValues.count)
            print("     Min: \(String(format: "%.2f", temperatureValues.min() ?? 0.0))°C, Max: \(String(format: "%.2f", temperatureValues.max() ?? 0.0))°C, Avg: \(String(format: "%.2f", avgTemp))°C")
        } else {
            print("     No valid temperature readings")
        }
        
        // Print first 3 entries as sample
        print("[\(TAG)] 📋 Sample Entries (first 3):")
        for (index, data) in datas.prefix(3).enumerated() {
            let date = Date(timeIntervalSince1970: TimeInterval(data.startTimeStamp))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            print("     [\(index + 1)] Time: \(formatter.string(from: date))")
            print("         HRV: \(data.hrv)ms")
            print("         Blood Oxygen: \(data.bloodOxygen)%")
            print("         Blood Glucose: \(data.bloodGlucose)mg/dL")
            print("         Temperature: \(data.temperature)°C (Valid: \(data.temperatureValid))")
        }
        
        print("[\(TAG)] ===============================================")
        
        // Notify listener with data
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.listener?.onCombinedDataFetched(
                hrv: datas,
                bloodOxygen: datas,
                bloodGlucose: datas,
                temperature: datas.filter { $0.temperatureValid }
            )
        }
    }
    
    private func saveToLocalDatabases(_ datas: [YCHealthDataCombinedData]) {
        // Separate data into individual vital types
        let hrvReadings: [(timestamp: Int64, hrvValue: Int)] = datas.map {
            (timestamp: Int64($0.startTimeStamp), hrvValue: $0.hrv)
        }
        
        let bloodOxygenReadings: [(timestamp: Int64, oxygenValue: Int)] = datas.map {
            (timestamp: Int64($0.startTimeStamp), oxygenValue: $0.bloodOxygen)
        }
        
        let bloodGlucoseReadings: [(timestamp: Int64, glucoseValue: Double)] = datas.map {
            (timestamp: Int64($0.startTimeStamp), glucoseValue: $0.bloodGlucose)
        }
        
        // Only save temperature if valid
        let temperatureReadings: [(timestamp: Int64, temperatureValue: Double)] = datas
            .filter { $0.temperatureValid }
            .map { (timestamp: Int64($0.startTimeStamp), temperatureValue: $0.temperature) }
        
        // Save to databases concurrently
        let group = DispatchGroup()
        var allSuccess = true
        var totalSaved = 0
        
        // Save HRV
        group.enter()
        hrvRepository.saveNewBatch(readings: hrvReadings) { success, savedCount in
            if success {
                print("[\(self.TAG)] 💾 HRV: Saved \(savedCount) new, \(hrvReadings.count - savedCount) duplicates")
                totalSaved += savedCount
            } else {
                allSuccess = false
            }
            group.leave()
        }
        
        // Save Blood Oxygen
        group.enter()
        bloodOxygenRepository.saveNewBatch(readings: bloodOxygenReadings) { success, savedCount in
            if success {
                print("[\(self.TAG)] 💾 Blood Oxygen: Saved \(savedCount) new, \(bloodOxygenReadings.count - savedCount) duplicates")
                totalSaved += savedCount
            } else {
                allSuccess = false
            }
            group.leave()
        }
        
        // Save Blood Glucose
        group.enter()
        bloodGlucoseRepository.saveNewBatch(readings: bloodGlucoseReadings) { success, savedCount in
            if success {
                print("[\(self.TAG)] 💾 Blood Glucose: Saved \(savedCount) new, \(bloodGlucoseReadings.count - savedCount) duplicates")
                totalSaved += savedCount
            } else {
                allSuccess = false
            }
            group.leave()
        }
        
        // Save Temperature
        group.enter()
        temperatureRepository.saveNewBatch(readings: temperatureReadings) { success, savedCount in
            if success {
                print("[\(self.TAG)] 💾 Temperature: Saved \(savedCount) new, \(temperatureReadings.count - savedCount) duplicates")
                totalSaved += savedCount
            } else {
                allSuccess = false
            }
            group.leave()
        }
        
        // Wait for all saves to complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if allSuccess {
                print("[\(self.TAG)] ✅ All combined data saved successfully (total: \(totalSaved) new entries)")
                
                // Clear upload flags when new data is saved
                if totalSaved > 0 {
                    self.lastUploadedDateStrings.removeAll()
                }
            } else {
                print("[\(self.TAG)] ❌ Some database saves failed")
                self.listener?.onSyncFailed(error: "Failed to save to local database")
            }
        }
    }
    
    // MARK: - Fetch Data from Local DB
    
    /// Fetch all combined data for a specific date from local databases
    /// Also triggers API comparison in background for each vital
    func fetchDataForDate(userId: Int, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            listener?.onLocalDataFetched(hrv: [], bloodOxygen: [], bloodGlucose: [], temperature: [])
            return
        }
        
        // Fetch from all repositories
        let hrvEntries = hrvRepository.getByDateRange(start: startOfDay, end: endOfDay)
        let hrvData = hrvEntries.map { (timestamp: $0.timestamp, hrvValue: Int($0.hrvValue)) }
            .sorted { $0.timestamp < $1.timestamp }
        
        let oxygenEntries = bloodOxygenRepository.getByDateRange(start: startOfDay, end: endOfDay)
        let oxygenData = oxygenEntries.map { (timestamp: $0.timestamp, oxygenValue: Int($0.oxygenValue)) }
            .sorted { $0.timestamp < $1.timestamp }
        
        let glucoseEntries = bloodGlucoseRepository.getByDateRange(start: startOfDay, end: endOfDay)
        let glucoseData = glucoseEntries.map { (timestamp: $0.timestamp, glucoseValue: $0.glucoseValue) }
            .sorted { $0.timestamp < $1.timestamp }
        
        let tempEntries = temperatureRepository.getByDateRange(start: startOfDay, end: endOfDay)
        let tempData = tempEntries.map { (timestamp: $0.timestamp, temperatureValue: $0.temperatureValue) }
            .sorted { $0.timestamp < $1.timestamp }
        
        print("[\(TAG)] 📊 Loaded from local DB - HRV: \(hrvData.count), O2: \(oxygenData.count), Glucose: \(glucoseData.count), Temp: \(tempData.count)")
        
        listener?.onLocalDataFetched(
            hrv: hrvData,
            bloodOxygen: oxygenData,
            bloodGlucose: glucoseData,
            temperature: tempData
        )
        
        // Compare with API in background for each vital
        compareAndSyncHRVWithAPI(userId: userId, date: date, localData: hrvData)
        compareAndSyncBloodOxygenWithAPI(userId: userId, date: date, localData: oxygenData)
        compareAndSyncBloodGlucoseWithAPI(userId: userId, date: date, localData: glucoseData)
        compareAndSyncTemperatureWithAPI(userId: userId, date: date, localData: tempData)
    }
    
    // MARK: - API Sync - HRV
    
    private func compareAndSyncHRVWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, hrvValue: Int)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        if lastUploadedDateStrings["hrv"] == dateString {
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
            type: "hrv",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }

                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ HRV API synced")
                    self.lastUploadedDateStrings["hrv"] = dateString
                } else {
                    print("[\(self.TAG)] ⚠️ HRV missing \(missingEntries.count) entries — uploading")
                    self.uploadHRVDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ HRV API comparison failed: \(error)")
            }
        }
    }
    
    private func uploadHRVDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, hrvValue: Int)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String($0.hrvValue), timestamp: $0.timestamp) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) HRV entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "hrv",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ HRV upload successful: \(response.message)")
                self.lastUploadedDateStrings["hrv"] = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ HRV upload failed: \(error)")
            }
        }
    }
    
    // MARK: - API Sync - Blood Oxygen
    
    private func compareAndSyncBloodOxygenWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, oxygenValue: Int)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        if lastUploadedDateStrings["blood_oxygen"] == dateString {
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
            type: "blood_oxygen",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }

                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ Blood Oxygen API synced")
                    self.lastUploadedDateStrings["blood_oxygen"] = dateString
                } else {
                    print("[\(self.TAG)] ⚠️ Blood Oxygen missing \(missingEntries.count) entries — uploading")
                    self.uploadBloodOxygenDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Blood Oxygen API comparison failed: \(error)")
            }
        }
    }
    
    private func uploadBloodOxygenDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, oxygenValue: Int)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String($0.oxygenValue), timestamp: $0.timestamp) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) Blood Oxygen entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "blood_oxygen",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Blood Oxygen upload successful: \(response.message)")
                self.lastUploadedDateStrings["blood_oxygen"] = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Blood Oxygen upload failed: \(error)")
            }
        }
    }
    
    // MARK: - API Sync - Blood Glucose
    
    private func compareAndSyncBloodGlucoseWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, glucoseValue: Double)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        if lastUploadedDateStrings["blood_glucose"] == dateString {
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
            type: "blood_glucose",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }

                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ Blood Glucose API synced")
                    self.lastUploadedDateStrings["blood_glucose"] = dateString
                } else {
                    print("[\(self.TAG)] ⚠️ Blood Glucose missing \(missingEntries.count) entries — uploading")
                    self.uploadBloodGlucoseDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Blood Glucose API comparison failed: \(error)")
            }
        }
    }
    
    private func uploadBloodGlucoseDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, glucoseValue: Double)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String(format: "%.2f", $0.glucoseValue), timestamp: $0.timestamp) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) Blood Glucose entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "blood_glucose",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Blood Glucose upload successful: \(response.message)")
                self.lastUploadedDateStrings["blood_glucose"] = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Blood Glucose upload failed: \(error)")
            }
        }
    }
    
    // MARK: - API Sync - Temperature
    
    private func compareAndSyncTemperatureWithAPI(userId: Int, date: Date, localData: [(timestamp: Int64, temperatureValue: Double)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        if lastUploadedDateStrings["temperature"] == dateString {
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
            type: "temperature",
            selectedDate: dateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let apiTimestamps = Set(response.data.map { Int64($0.timestamp) })
                let missingEntries = dataForComparison.filter { !apiTimestamps.contains($0.timestamp) }

                if missingEntries.isEmpty {
                    print("[\(self.TAG)] ✅ Temperature API synced")
                    self.lastUploadedDateStrings["temperature"] = dateString
                } else {
                    print("[\(self.TAG)] ⚠️ Temperature missing \(missingEntries.count) entries — uploading")
                    self.uploadTemperatureDataToAPI(userId: userId, date: date, data: missingEntries)
                }
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Temperature API comparison failed: \(error)")
            }
        }
    }
    
    private func uploadTemperatureDataToAPI(userId: Int, date: Date, data: [(timestamp: Int64, temperatureValue: Double)]) {
        guard !data.isEmpty else { return }
        
        let values: [RingValueEntry] = data.map { RingValueEntry(value: String(format: "%.2f", $0.temperatureValue), timestamp: $0.timestamp) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: date)
        
        print("[\(TAG)] 📤 Uploading \(values.count) Temperature entries to API...")
        
        HealthService.shared.saveHealthDataBatch(
            userId: userId,
            type: "temperature",
            values: values
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Temperature upload successful: \(response.message)")
                self.lastUploadedDateStrings["temperature"] = dateString
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ Temperature upload failed: \(error)")
            }
        }
    }
    
}

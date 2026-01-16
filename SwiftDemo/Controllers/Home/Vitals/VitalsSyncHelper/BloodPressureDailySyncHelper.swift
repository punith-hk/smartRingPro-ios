import UIKit

/// Helper to sync daily aggregated blood pressure data
/// Flow: Load from local DB → Show UI → Fetch from API → Compare → Update DB if changed → Reload UI
class BloodPressureDailySyncHelper {
    
    protocol BloodPressureDailySyncListener: AnyObject {
        func onLocalDailyBPDataFetched(_ systolicData: [VitalDataPoint], _ diastolicData: [VitalDataPoint])
        func onAPIDailyBPDataFetched(_ systolicData: [VitalDataPoint], _ diastolicData: [VitalDataPoint])
        func onDailyBPSyncFailed(error: String)
    }
    
    private weak var listener: BloodPressureDailySyncListener?
    private let TAG = "BloodPressureDailySyncHelper"
    private let repository: BloodPressureDailyStatsRepository
    
    // Track if API sync is in progress
    private var isSyncing = false
    
    init(listener: BloodPressureDailySyncListener) {
        self.listener = listener
        self.repository = BloodPressureDailyStatsRepository()
    }
    
    // MARK: - Main Sync Flow
    
    /// Fetch daily data: First from local DB (instant), then sync with API (background)
    func fetchDailyData(userId: Int, completion: @escaping ([VitalDataPoint], [VitalDataPoint]) -> Void) {
        // Step 1: Load from local DB immediately
        let localData = loadFromLocalDB(userId: userId)
        let (systolicPoints, diastolicPoints) = convertToDataPoints(localData)
        
        print("[\(TAG)] 📊 Loaded \(systolicPoints.count) daily entries from local DB")
        
        // Return local data immediately
        completion(systolicPoints, diastolicPoints)
        listener?.onLocalDailyBPDataFetched(systolicPoints, diastolicPoints)
        
        // Step 2: Sync with API in background
        syncWithAPI(userId: userId)
    }
    
    /// Load data for specific date range from local DB (no API call)
    /// Used when switching tabs or changing dates - data is already synced
    func loadDataForDateRange(userId: Int, range: VitalChartRange, selectedDate: Date, completion: @escaping ([VitalDataPoint], [VitalDataPoint]) -> Void) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var startDate: Date
        var endDate: Date
        
        switch range {
        case .week:
            // Get start of week (Monday) and end of week (Sunday)
            let weekday = calendar.component(.weekday, from: selectedDate)
            let daysToMonday = (weekday == 1) ? -6 : -(weekday - 2)
            startDate = calendar.date(byAdding: .day, value: daysToMonday, to: selectedDate)!
            endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
            
        case .month:
            // Get start and end of month
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            startDate = calendar.date(from: components)!
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
            
        case .day:
            // Not used for this method, but handle it anyway
            startDate = calendar.startOfDay(for: selectedDate)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        }
        
        print("[\(TAG)] 📅 Loading data from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))")
        
        // Query local DB for date range
        let allStats = repository.getAllForUser(userId: userId)
        let filteredStats = allStats.filter { stat in
            guard let dateString = stat.date,
                  let statDate = dateFormatter.date(from: dateString) else {
                return false
            }
            return statDate >= startDate && statDate <= endDate
        }
        
        let (systolicPoints, diastolicPoints) = convertToDataPoints(filteredStats)
        print("[\(TAG)] 📊 Found \(systolicPoints.count) entries for selected \(range) range")
        
        completion(systolicPoints, diastolicPoints)
    }
    
    // MARK: - Local DB Operations
    
    /// Load data from local database (last 60 days)
    private func loadFromLocalDB(userId: Int) -> [BloodPressureDailyStatsEntity] {
        let stats = repository.getRecentDays(userId: userId, days: 60)
        return stats
    }
    
    // MARK: - API Sync
    
    /// Fetch from API, compare with local DB, update if different
    private func syncWithAPI(userId: Int) {
        guard !isSyncing else {
            print("[\(TAG)] ⚠️ Sync already in progress")
            return
        }
        
        isSyncing = true
        print("[\(TAG)] 🔄 Starting API sync...")
        
        HealthService.shared.getRingDataByDay(
            userId: userId,
            type: "blood_pressure"
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.isSyncing = false
            
            switch result {
            case .success(let response):
                print("[\(TAG)] ✅ API returned \(response.data.count) daily records")
                
                guard !response.data.isEmpty else {
                    print("[\(TAG)] ℹ️ No daily data from API")
                    return
                }
                
                // Compare and update
                self.compareAndUpdate(userId: userId, apiStats: response.data)
                
            case .failure(let error):
                print("[\(TAG)] ❌ API sync failed: \(error.localizedDescription)")
                self.listener?.onDailyBPSyncFailed(error: error.localizedDescription)
            }
        }
    }
    
    /// Compare API data with local DB, update if different
    private func compareAndUpdate(userId: Int, apiStats: [GetRingDataByDayResponse.DayData]) {
        // Get existing local data
        let localStats = repository.getAllForUser(userId: userId)
        let localDict = Dictionary(uniqueKeysWithValues: localStats.compactMap { stat -> (String, BloodPressureDailyStatsEntity)? in
            guard let date = stat.date else { return nil }
            return (date, stat)
        })
        
        // Prepare batch for saving
        var statsToSave: [(date: String, value: String, diastolicValue: String)] = []
        var hasChanges = false
        
        for apiEntry in apiStats {
            let date = apiEntry.vDate
            let value = apiEntry.value
            let diastolicValue = apiEntry.diastolicValue
            
            if let local = localDict[date] {
                // Entry exists - check if value changed
                if local.value != value || local.diastolicValue != diastolicValue {
                    statsToSave.append((date: date, value: value, diastolicValue: diastolicValue))
                    hasChanges = true
                    print("[\(TAG)] 🔄 Updated entry for \(date): \(local.value ?? "nil")/\(local.diastolicValue ?? "nil") → \(value)/\(diastolicValue)")
                }
            } else {
                // New entry
                statsToSave.append((date: date, value: value, diastolicValue: diastolicValue))
                hasChanges = true
                print("[\(TAG)] ➕ New entry for \(date): \(value)/\(diastolicValue)")
            }
        }
        
        // Save batch if there are changes
        if !statsToSave.isEmpty {
            repository.saveBatch(userId: userId, stats: statsToSave) { [weak self] success, savedCount in
                guard let self = self else { return }
                
                if success {
                    print("[\(self.TAG)] ✅ Saved \(savedCount) daily entries")
                    
                    // Reload from DB and notify
                    let updatedData = self.loadFromLocalDB(userId: userId)
                    let (systolicPoints, diastolicPoints) = self.convertToDataPoints(updatedData)
                    
                    DispatchQueue.main.async {
                        self.listener?.onAPIDailyBPDataFetched(systolicPoints, diastolicPoints)
                    }
                } else {
                    print("[\(self.TAG)] ❌ Failed to save batch")
                }
            }
        } else if hasChanges {
            print("[\(TAG)] ✅ Database updated, notifying UI...")
            
            // Reload from DB and notify
            let updatedData = loadFromLocalDB(userId: userId)
            let (systolicPoints, diastolicPoints) = convertToDataPoints(updatedData)
            
            DispatchQueue.main.async {
                self.listener?.onAPIDailyBPDataFetched(systolicPoints, diastolicPoints)
            }
        } else {
            print("[\(TAG)] ℹ️ No changes detected")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert DB entities to VitalDataPoint arrays (systolic and diastolic)
    private func convertToDataPoints(_ entities: [BloodPressureDailyStatsEntity]) -> ([VitalDataPoint], [VitalDataPoint]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var systolicPoints: [VitalDataPoint] = []
        var diastolicPoints: [VitalDataPoint] = []
        
        for entity in entities {
            guard let dateString = entity.date,
                  let date = dateFormatter.date(from: dateString),
                  let systolicStr = entity.value,
                  let diastolicStr = entity.diastolicValue,
                  let systolicValue = Double(systolicStr),
                  let diastolicValue = Double(diastolicStr) else {
                continue
            }
            
            let timestamp = Int64(date.timeIntervalSince1970)
            systolicPoints.append(VitalDataPoint(timestamp: timestamp, value: systolicValue))
            diastolicPoints.append(VitalDataPoint(timestamp: timestamp, value: diastolicValue))
        }
        
        return (systolicPoints, diastolicPoints)
    }
}

import UIKit

/// Helper to sync daily aggregated stress data
/// Flow: Load from local DB → Show UI → Fetch from API → Compare → Update DB if changed → Reload UI
class StressDailySyncHelper {
    
    protocol StressDailySyncListener: AnyObject {
        func onLocalDailyDataFetched(_ data: [VitalDataPoint])
        func onAPIDailyDataFetched(_ data: [VitalDataPoint])
        func onDailySyncFailed(error: String)
    }
    
    private weak var listener: StressDailySyncListener?
    private let TAG = "StressDailySyncHelper"
    private let repository: StressDailyStatsRepository
    
    // Track if API sync is in progress
    private var isSyncing = false
    
    init(listener: StressDailySyncListener) {
        self.listener = listener
        self.repository = StressDailyStatsRepository()
    }
    
    // MARK: - Main Sync Flow
    
    /// Fetch daily data: First from local DB (instant), then sync with API (background)
    func fetchDailyData(userId: Int, completion: @escaping ([VitalDataPoint]) -> Void) {
        // Step 1: Load from local DB immediately
        let localData = loadFromLocalDB(userId: userId)
        let dataPoints = convertToDataPoints(localData)
        
        print("[\(TAG)] 📊 Loaded \(dataPoints.count) daily entries from local DB")
        
        // Return local data immediately
        completion(dataPoints)
        listener?.onLocalDailyDataFetched(dataPoints)
        
        // Step 2: Sync with API in background
        syncWithAPI(userId: userId)
    }
    
    /// Load data for specific date range from local DB (no API call)
    /// Used when switching tabs or changing dates - data is already synced
    func loadDataForDateRange(userId: Int, range: VitalChartRange, selectedDate: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
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
            let weekStart = calendar.date(byAdding: .day, value: daysToMonday, to: selectedDate)!
            startDate = calendar.startOfDay(for: weekStart)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: startDate)!
            endDate = calendar.date(byAdding: .day, value: 1, to: weekEnd)! // Start of next day for comparison
            
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
            return statDate >= startDate && statDate < endDate
        }
        
        let dataPoints = convertToDataPoints(filteredStats)
        print("[\(TAG)] 📊 Found \(dataPoints.count) entries for selected \(range) range")
        
        completion(dataPoints)
    }
    
    // MARK: - Local DB Operations
    
    /// Load data from local database (last 60 days)
    private func loadFromLocalDB(userId: Int) -> [StressDailyStatsEntity] {
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
            type: "stress"
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.isSyncing = false
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ API returned \(response.data.count) daily entries")
                self.processAPIData(userId: userId, apiData: response.data)
                
            case .failure(let error):
                print("[\(self.TAG)] ❌ API sync failed: \(error)")
                self.listener?.onDailySyncFailed(error: error.localizedDescription)
            }
        }
    }
    
    /// Process API data: Compare with local DB and update if changed
    private func processAPIData(userId: Int, apiData: [GetRingDataByDayResponse.DayData]) {
        // Get existing local data
        let localStats = repository.getAllForUser(userId: userId)
        let localDict = Dictionary(uniqueKeysWithValues: localStats.compactMap { stat -> (String, StressDailyStatsEntity)? in
            guard let date = stat.date else { return nil }
            return (date, stat)
        })
        
        // Prepare batch for saving
        var statsToSave: [(date: String, value: String)] = []
        var hasChanges = false
        
        for apiEntry in apiData {
            let date = apiEntry.vDate
            let value = apiEntry.value
            
            // Check if this date exists in local DB
            if let localStat = localDict[date] {
                // Compare values
                if localStat.value != value {
                    statsToSave.append((date: date, value: value))
                    hasChanges = true
                }
            } else {
                // New entry from API
                statsToSave.append((date: date, value: value))
                hasChanges = true
            }
        }
        
        if hasChanges {
            print("[\(TAG)] 📝 Updating \(statsToSave.count) entries in local DB")
            repository.saveBatch(userId: userId, stats: statsToSave)
            
            // Reload UI with updated data
            let updatedData = repository.getRecentDays(userId: userId, days: 60)
            let dataPoints = convertToDataPoints(updatedData)
            
            DispatchQueue.main.async { [weak self] in
                self?.listener?.onAPIDailyDataFetched(dataPoints)
            }
        } else {
            print("[\(TAG)] ✅ Local DB is up to date with API")
        }
    }
    
    // MARK: - Data Conversion
    
    /// Convert daily stats entities to data points for chart
    private func convertToDataPoints(_ entities: [StressDailyStatsEntity]) -> [VitalDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return entities.compactMap { entity in
            guard let dateString = entity.date,
                  let date = dateFormatter.date(from: dateString),
                  let valueString = entity.value,
                  let level = Int(valueString) else {
                return nil
            }
            
            let timestamp = Int64(date.timeIntervalSince1970)
            return VitalDataPoint(timestamp: timestamp, value: Double(level))
        }
    }
}

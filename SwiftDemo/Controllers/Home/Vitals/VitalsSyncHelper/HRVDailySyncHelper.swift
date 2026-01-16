import UIKit

/// Helper to sync daily aggregated HRV data
/// Flow: Load from local DB → Show UI → Fetch from API → Compare → Update DB if changed → Reload UI
class HRVDailySyncHelper {
    
    protocol HRVDailySyncListener: AnyObject {
        func onLocalDailyDataFetched(_ data: [VitalDataPoint])
        func onAPIDailyDataFetched(_ data: [VitalDataPoint])
        func onDailySyncFailed(error: String)
    }
    
    private weak var listener: HRVDailySyncListener?
    private let TAG = "HRVDailySyncHelper"
    private let repository: HrvDailyStatsRepository
    
    private var isSyncing = false
    
    init(listener: HRVDailySyncListener) {
        self.listener = listener
        self.repository = HrvDailyStatsRepository()
    }
    
    // MARK: - Main Sync Flow
    
    /// Fetch daily data: First from local DB (instant), then sync with API (background)
    func fetchDailyData(userId: Int, completion: @escaping ([VitalDataPoint]) -> Void) {
        let localData = loadFromLocalDB(userId: userId)
        let dataPoints = convertToDataPoints(localData)
        
        print("[\(TAG)] 📊 Loaded \(dataPoints.count) daily entries from local DB")
        
        completion(dataPoints)
        listener?.onLocalDailyDataFetched(dataPoints)
        
        syncWithAPI(userId: userId)
    }
    
    /// Load data for specific date range from local DB (no API call)
    func loadDataForDateRange(userId: Int, range: VitalChartRange, selectedDate: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var startDate: Date
        var endDate: Date
        
        switch range {
        case .week:
            let weekday = calendar.component(.weekday, from: selectedDate)
            let daysToMonday = (weekday == 1) ? -6 : -(weekday - 2)
            startDate = calendar.date(byAdding: .day, value: daysToMonday, to: selectedDate)!
            endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            startDate = calendar.date(from: components)!
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
            
        case .day:
            startDate = calendar.startOfDay(for: selectedDate)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        }
        
        print("[\(TAG)] 📅 Loading data from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))")
        
        let allStats = repository.getAllForUser(userId: userId)
        let filteredStats = allStats.filter { stat in
            guard let dateString = stat.date,
                  let statDate = dateFormatter.date(from: dateString) else {
                return false
            }
            return statDate >= startDate && statDate <= endDate
        }
        
        let dataPoints = convertToDataPoints(filteredStats)
        print("[\(TAG)] 📊 Found \(dataPoints.count) entries for selected \(range) range")
        
        completion(dataPoints)
    }
    
    // MARK: - Local DB Operations
    
    private func loadFromLocalDB(userId: Int) -> [HrvDailyStatsEntity] {
        let stats = repository.getRecentDays(userId: userId, days: 60)
        return stats
    }
    
    // MARK: - API Sync
    
    private func syncWithAPI(userId: Int) {
        guard !isSyncing else {
            print("[\(TAG)] ⚠️ Sync already in progress")
            return
        }
        
        isSyncing = true
        print("[\(TAG)] 🔄 Starting API sync...")
        
        HealthService.shared.getRingDataByDay(
            userId: userId,
            type: "hrv"
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
    
    private func processAPIData(userId: Int, apiData: [GetRingDataByDayResponse.DayData]) {
        let localStats = repository.getAllForUser(userId: userId)
        let localDict = Dictionary(uniqueKeysWithValues: localStats.compactMap { stat -> (String, HrvDailyStatsEntity)? in
            guard let date = stat.date else { return nil }
            return (date, stat)
        })
        
        var statsToSave: [(date: String, value: String)] = []
        var hasChanges = false
        
        for apiEntry in apiData {
            let date = apiEntry.vDate
            let value = apiEntry.value
            let diastolicValue = apiEntry.diastolicValue
            
            if let local = localDict[date] {
                if local.value != value {
                    statsToSave.append((date: date, value: value))
                    hasChanges = true
                    print("[\(TAG)] 🔄 Updated entry for \(date): \(local.value ?? "nil") → \(value)")
                }
            } else {
                statsToSave.append((date: date, value: value))
                hasChanges = true
                print("[\(TAG)] ➕ New entry for \(date): \(value)")
            }
        }
        
        if statsToSave.isEmpty {
            print("[\(TAG)] ✅ Local DB is up to date")
            return
        }
        
        repository.saveBatch(userId: userId, stats: statsToSave) { [weak self] (success: Bool, savedCount: Int) in
            guard let self = self else { return }
            
            if success && savedCount > 0 {
                print("[\(self.TAG)] 💾 Saved \(savedCount) entries to local DB")
                
                let updatedData = self.loadFromLocalDB(userId: userId)
                let dataPoints = self.convertToDataPoints(updatedData)
                
                DispatchQueue.main.async {
                    self.listener?.onAPIDailyDataFetched(dataPoints)
                }
            }
        }
    }
    
    // MARK: - Conversion
    
    private func convertToDataPoints(_ stats: [HrvDailyStatsEntity]) -> [VitalDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return stats.compactMap { stat -> VitalDataPoint? in
            guard let dateString = stat.date,
                  let date = dateFormatter.date(from: dateString),
                  let valueString = stat.value,
                  let value = Double(valueString) else {
                return nil
            }
            
            return VitalDataPoint(
                timestamp: Int64(date.timeIntervalSince1970),
                value: value
            )
        }
    }
}

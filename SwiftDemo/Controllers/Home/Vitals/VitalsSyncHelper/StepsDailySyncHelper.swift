import UIKit

/// Helper to aggregate daily steps/calories data
/// Aggregates raw step entries from StepsRepository into daily stats for charting
class StepsDailySyncHelper {
    
    struct DailyTotals {
        let totalSteps: Int
        let totalDistance: Int
        let totalCalories: Int
    }
    
    protocol StepsDailySyncListener: AnyObject {
        func onLocalDailyDataFetched(_ data: [VitalDataPoint])
        func onDailySyncFailed(error: String)
    }
    
    private weak var listener: StepsDailySyncListener?
    private let TAG = "StepsDailySyncHelper"
    private let repository: StepsRepository
    private let statsRepository: StepsDailyStatsRepository
    
    init(listener: StepsDailySyncListener) {
        self.listener = listener
        self.repository = StepsRepository()
        self.statsRepository = StepsDailyStatsRepository()
    }
    
    // MARK: - Main Data Loading
    
    /// Load and aggregate data for specific date range
    /// Used for Week and Month chart views - aggregates by day
    func loadDataForDateRange(userId: Int, range: VitalChartRange, selectedDate: Date, completion: @escaping ([VitalDataPoint], DailyTotals) -> Void) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"  // API format
        
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
            endDate = calendar.date(byAdding: .day, value: 1, to: weekEnd)! // Start of next day
            
        case .month:
            // Get start and end of month
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            startDate = calendar.date(from: components)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate)!
            endDate = nextMonth
            
        case .day:
            // Day view handled by sync helper, not this method
            startDate = calendar.startOfDay(for: selectedDate)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        }
        
        print("[\(TAG)] 📅 Loading data from \\(dateFormatter.string(from: startDate)) to \\(dateFormatter.string(from: endDate))")
        
        // Aggregate data day by day
        var dailyDataPoints: [VitalDataPoint] = []
        var cumulativeSteps = 0
        var cumulativeDistance = 0
        var cumulativeCalories = 0
        var currentDate = startDate
        
        while currentDate < endDate {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            // Get all step entries for this day
            let dayEntries = repository.getByDateRange(start: currentDate, end: dayEnd)
            
            if !dayEntries.isEmpty {
                // Calculate totals for the day
                let totalSteps = dayEntries.reduce(0) { $0 + Int($1.steps) }
                let totalDistance = dayEntries.reduce(0) { $0 + Int($1.distance) }
                let totalCalories = dayEntries.reduce(0) { $0 + Int($1.calories) }
                
                let caloriesValues = dayEntries.map { Int($0.calories) }
                let minCalories = caloriesValues.min() ?? 0
                let maxCalories = caloriesValues.max() ?? 0
                let avgCalories = caloriesValues.isEmpty ? 0 : (caloriesValues.reduce(0, +) / caloriesValues.count)
                
                // Use middle of day as timestamp for charting
                let midDay = calendar.date(byAdding: .hour, value: 12, to: currentDate)!
                let timestamp = Int64(midDay.timeIntervalSince1970)
                
                // Create data point with TOTAL STEPS for the day (bar chart value)
                let dataPoint = VitalDataPoint(timestamp: timestamp, value: Double(totalSteps))
                dailyDataPoints.append(dataPoint)
                
                // Add to cumulative totals
                cumulativeSteps += totalSteps
                cumulativeDistance += totalDistance
                cumulativeCalories += totalCalories
                
                // Save aggregated stats to DB for future reference
                let dateString = dateFormatter.string(from: currentDate)
                statsRepository.saveDailyStats(
                    userId: userId,
                    date: dateString,
                    totalSteps: totalSteps,
                    totalDistance: totalDistance,
                    totalCalories: totalCalories,
                    minCalories: minCalories,
                    maxCalories: maxCalories,
                    avgCalories: avgCalories
                ) { _ in }
            }
            
            currentDate = dayEnd
        }
        
        print("[\(TAG)] 📊 Aggregated \(dailyDataPoints.count) days of data")
        print("[\(TAG)] 📊 Total: \(cumulativeCalories) kcal, \(cumulativeSteps) steps, \(cumulativeDistance)m")
        
        let totals = DailyTotals(
            totalSteps: cumulativeSteps,
            totalDistance: cumulativeDistance,
            totalCalories: cumulativeCalories
        )
        completion(dailyDataPoints, totals)
    }

    // MARK: - API Merge (supplement local with server steps data)

    /// Fetches API daily step aggregates and merges dates missing from localPoints.
    /// Never overwrites local data. Completion called on main thread with (mergedPoints, totalSteps).
    func fetchAPIAndMerge(
        userId: Int,
        range: VitalChartRange,
        selectedDate: Date,
        localPoints: [VitalDataPoint],
        completion: @escaping ([VitalDataPoint], Int) -> Void
    ) {
        guard range != .day else {
            completion(localPoints, localPoints.reduce(0) { $0 + Int($1.value) })
            return
        }

        let calendar = Calendar.current
        var rangeStart: Date
        var rangeEnd: Date
        switch range {
        case .week:
            let weekday = calendar.component(.weekday, from: selectedDate)
            let daysToMon = (weekday == 1) ? -6 : -(weekday - 2)
            rangeStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: daysToMon, to: selectedDate)!)
            rangeEnd   = calendar.date(byAdding: .day, value: 7, to: rangeStart)!
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: selectedDate)
            rangeStart = calendar.date(from: comps)!
            rangeEnd   = calendar.date(byAdding: .month, value: 1, to: rangeStart)!
        case .day:
            completion(localPoints, localPoints.reduce(0) { $0 + Int($1.value) })
            return
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        var localDates = Set<String>()
        for point in localPoints {
            let d = Date(timeIntervalSince1970: TimeInterval(point.timestamp))
            localDates.insert(df.string(from: d))
        }

        HealthService.shared.getRingDataByDay(userId: userId, type: "steps") { result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    completion(localPoints, localPoints.reduce(0) { $0 + Int($1.value) })
                }
            case .success(let response):
                var merged = localPoints
                for entry in response.data {
                    guard let entryDate = df.date(from: entry.vDate) else { continue }
                    guard entryDate >= rangeStart, entryDate < rangeEnd else { continue }
                    guard !localDates.contains(entry.vDate) else { continue }
                    guard let steps = Int(entry.value), steps > 0, steps < 100_000 else { continue }

                    let midDay = calendar.date(byAdding: .hour, value: 12, to: entryDate)!
                    merged.append(VitalDataPoint(timestamp: Int64(midDay.timeIntervalSince1970), value: Double(steps)))
                }
                merged.sort { $0.timestamp < $1.timestamp }
                let total = merged.reduce(0) { $0 + Int($1.value) }
                print("[StepsDailySyncHelper] 🌐 API merge: \(merged.count - localPoints.count) new dates added")
                DispatchQueue.main.async { completion(merged, total) }
            }
        }
    }

    // MARK: - API Logging (Read-only)

    /// Fetch daily calories data from API for logging purposes only
    /// Does NOT sync to local DB - just prints last 5 entries
    private func fetchAPIDataForLogging(userId: Int) {
        print("[\(TAG)] 🔍 Fetching API data for logging...")

        HealthService.shared.getRingDataByDay(
            userId: userId,
            type: "calories"
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                let apiData = response.data
                print("[\(self.TAG)] ✅ API returned \(apiData.count) daily calorie entries")

                let last5 = Array(apiData.prefix(5))
                if !last5.isEmpty {
                    print("[\(self.TAG)] 📋 Last 5 API entries:")
                    for (index, entry) in last5.enumerated() {
                        print("   \(index + 1). Date: \(entry.vDate) | Calories: \(entry.value) kcal")
                    }
                } else {
                    print("[\(self.TAG)] ℹ️ No API data found")
                }

            case .failure(let error):
                print("[\(self.TAG)] ❌ API fetch failed: \(error)")
            }
        }
    }
}

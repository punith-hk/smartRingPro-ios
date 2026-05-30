import UIKit

/// Daily aggregation helper dedicated to the Calories screen.
/// Reads raw entries from StepsRepository, aggregates by day (calories only),
/// and can merge server-side daily totals for historical data from other devices.
class CaloriesDailySyncHelper {

    struct CaloriesTotals {
        let totalCalories: Int
    }

    private let TAG = "CaloriesDailySyncHelper"
    private let repository: StepsRepository

    init() {
        self.repository = StepsRepository()
    }

    // MARK: - Local DB Aggregation (Week / Month)

    /// Aggregates daily calorie totals from local DB for the given range.
    /// Calls completion synchronously on the calling thread, then triggers
    /// background API merge (see fetchAPIAndMerge).
    func loadDataForDateRange(
        userId: Int,
        range: VitalChartRange,
        selectedDate: Date,
        completion: @escaping ([VitalDataPoint], CaloriesTotals) -> Void
    ) {
        let calendar = Calendar.current

        let (startDate, endDate) = dateRange(for: range, selectedDate: selectedDate, calendar: calendar)

        var dataPoints: [VitalDataPoint] = []
        var cumulativeCalories = 0
        var current = startDate

        while current < endDate {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!
            let dayEntries = repository.getByDateRange(start: current, end: dayEnd)

            if !dayEntries.isEmpty {
                let totalCalories = dayEntries.reduce(0) { $0 + Int($1.calories) }
                // Sanity-check: ignore corrupted values > 10 million
                guard totalCalories < 10_000_000 else { current = dayEnd; continue }

                let midDay = calendar.date(byAdding: .hour, value: 12, to: current)!
                dataPoints.append(VitalDataPoint(timestamp: Int64(midDay.timeIntervalSince1970),
                                                  value: Double(totalCalories)))
                cumulativeCalories += totalCalories
            }
            current = dayEnd
        }

        print("[\(TAG)] 📊 \(dataPoints.count) days loaded | \(cumulativeCalories) kcal total")
        completion(dataPoints, CaloriesTotals(totalCalories: cumulativeCalories))
    }

    // MARK: - API Merge (supplement local with server data)

    /// Fetches API daily calorie aggregates and merges dates missing from localPoints.
    /// Safe to call after loadDataForDateRange — never overwrites local data.
    /// Completion called on main thread with (mergedPoints, totalCalories).
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
        let (rangeStart, rangeEnd) = dateRange(for: range, selectedDate: selectedDate, calendar: calendar)

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        // Dates already covered locally
        var localDates = Set<String>()
        for point in localPoints {
            let d = Date(timeIntervalSince1970: TimeInterval(point.timestamp))
            localDates.insert(df.string(from: d))
        }

        HealthService.shared.getRingDataByDay(userId: userId, type: "calories") { result in
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
                    guard let cal = Int(entry.value), cal > 0, cal < 10_000_000 else { continue }

                    let midDay = calendar.date(byAdding: .hour, value: 12, to: entryDate)!
                    merged.append(VitalDataPoint(timestamp: Int64(midDay.timeIntervalSince1970),
                                                  value: Double(cal)))
                }

                merged.sort { $0.timestamp < $1.timestamp }
                let total = merged.reduce(0) { $0 + Int($1.value) }
                print("[CaloriesDailySyncHelper] 🌐 API merge: \(merged.count - localPoints.count) new dates added")
                DispatchQueue.main.async { completion(merged, total) }
            }
        }
    }

    // MARK: - Private Helpers

    private func dateRange(
        for range: VitalChartRange,
        selectedDate: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        switch range {
        case .week:
            let weekday = calendar.component(.weekday, from: selectedDate)
            let daysToMon = (weekday == 1) ? -6 : -(weekday - 2)
            let mon = calendar.startOfDay(for: calendar.date(byAdding: .day, value: daysToMon, to: selectedDate)!)
            let end = calendar.date(byAdding: .day, value: 7, to: mon)!
            return (mon, end)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: selectedDate)
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .day:
            let start = calendar.startOfDay(for: selectedDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        }
    }
}

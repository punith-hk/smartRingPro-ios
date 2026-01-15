import Foundation
import CoreData

/// HeartRate Repository (equivalent to Android's BloodGlucoseRepository)
/// Handles all database operations for heart rate data
class BloodGlucoseRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "BloodGlucoseRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save new batch of blood glucose readings from BLE device
    /// Equivalent to Android's saveNewBatch(readings: List<Pair<Long, String>>)
    func saveNewBatch(readings: [(timestamp: Int64, glucoseValue: Double)], completion: @escaping (Bool, Int) -> Void) {
        print("[\(TAG)] 🔵 saveNewBatch called with \(readings.count) readings")
        
        guard !readings.isEmpty else {
            print("[\(TAG)] ⚠️ No readings to save")
            completion(true, 0)
            return
        }
        
        print("[\(TAG)] 🔄 Starting background task...")
        
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else {
                print("[BloodGlucoseRepository] ⚠️ Self is nil in background task")
                return
            }
            
            print("[\(self.TAG)] 🔵 Background task started")
            
            let batchTime = Int64(Date().timeIntervalSince1970)
            print("[\(self.TAG)] 📅 Batch time: \(batchTime)")
            
            // Get existing timestamps to check for duplicates
            let existingTimestamps = self.getExistingTimestamps(in: backgroundContext)
            print("[\(self.TAG)] 📊 Found \(existingTimestamps.count) existing entries in DB")
            
            // Filter out duplicates
            let newReadings = readings.filter { !existingTimestamps.contains($0.timestamp) }
            print("[\(self.TAG)] 🔍 Filtered: \(readings.count) total, \(newReadings.count) new, \(readings.count - newReadings.count) duplicates")
            
            guard !newReadings.isEmpty else {
                print("[\(self.TAG)] ℹ️ All readings already exist in DB")
                DispatchQueue.main.async {
                    completion(true, 0)
                }
                return
            }
            
            // Insert new entries
            for reading in newReadings {
                BloodGlucoseEntity.create(
                    timestamp: reading.timestamp,
                    glucoseValue: reading.glucoseValue,
                    batchTime: batchTime,
                    in: backgroundContext
                )
            }
            
            // Save context
            do {
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved \(newReadings.count) new blood glucose entries")
                DispatchQueue.main.async {
                    completion(true, newReadings.count)
                }
            } catch {
                print("[\(self.TAG)] ❌ Failed to save: \(error)")
                DispatchQueue.main.async {
                    completion(false, 0)
                }
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Get all blood glucose entries ordered by timestamp descending
    func getAll() -> [BloodGlucoseEntity] {
        let request = BloodGlucoseEntity.fetchAll()
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) blood glucose entries")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch all: \(error)")
            return []
        }
    }
    
    /// Get latest blood glucose entry
    func getLatestEntry() -> BloodGlucoseEntity? {
        let request = BloodGlucoseEntity.fetchLatest()
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch latest: \(error)")
            return nil
        }
    }
    
    /// Get latest batch of synced data
    func getLatestBatch() -> [BloodGlucoseEntity] {
        let request = BloodGlucoseEntity.fetchAll()
        
        do {
            let allResults = try context.fetch(request)
            guard let maxBatchTime = allResults.max(by: { $0.batchTime < $1.batchTime })?.batchTime else {
                return []
            }
            
            let latestBatch = allResults.filter { $0.batchTime == maxBatchTime }
            print("[\(TAG)] 📦 Latest batch has \(latestBatch.count) entries")
            return latestBatch
        } catch {
            print("[\(TAG)] ❌ Failed to fetch latest batch: \(error)")
            return []
        }
    }
    
    /// Get blood glucose entries for today
    func getTodayLatestEntry() -> BloodGlucoseEntity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = Int64(startOfDay.timeIntervalSince1970)
        let endTimestamp = Int64(endOfDay.timeIntervalSince1970)
        
        let request = BloodGlucoseEntity.fetchByDateRange(start: startTimestamp, end: endTimestamp)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch today's entry: \(error)")
            return nil
        }
    }
    
    /// Get blood glucose entries for specific date range
    func getByDateRange(start: Date, end: Date) -> [BloodGlucoseEntity] {
        let startTimestamp = Int64(start.timeIntervalSince1970)
        let endTimestamp = Int64(end.timeIntervalSince1970)
        
        let request = BloodGlucoseEntity.fetchByDateRange(start: startTimestamp, end: endTimestamp)
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) entries for date range")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch by date range: \(error)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete all blood glucose data
    func deleteAll() {
        CoreDataManager.shared.deleteAllData(for: "BloodGlucoseEntity")
    }
    
    // MARK: - Helper Methods
    
    /// Get all existing timestamps (for duplicate checking)
    private func getExistingTimestamps(in context: NSManagedObjectContext) -> Set<Int64> {
        let request = NSFetchRequest<BloodGlucoseEntity>(entityName: "BloodGlucoseEntity")
        request.propertiesToFetch = ["timestamp"]
        
        do {
            let results = try context.fetch(request)
            return Set(results.map { $0.timestamp })
        } catch {
            print("[\(TAG)] ❌ Failed to fetch existing timestamps: \(error)")
            return []
        }
    }
    
    // MARK: - Debug Methods
    
    /// Print all saved blood glucose data (for debugging)
    func printAllData() {
        let all = getAll()
        print("[\(TAG)] 📊 Total records in database: \(all.count)")
        print("[\(TAG)] 📋 Printing all entries:")
        print("----------------------------------------")
        
        for (index, entry) in all.enumerated() {
            let date = Date(timeIntervalSince1970: TimeInterval(entry.timestamp))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = formatter.string(from: date)
            
            print("  \(index + 1). BPM: \(entry.bpm) | Time: \(dateStr) | Timestamp: \(entry.timestamp)")
        }
        print("----------------------------------------")
    }
    
    /// Print summary statistics
    func printSummary() {
        let all = getAll()
        guard !all.isEmpty else {
            print("[\(TAG)] ℹ️ Database is empty")
            return
        }
        
        let bpmValues = all.map { Int($0.bpm) }
        let minBpm = bpmValues.min() ?? 0
        let maxBpm = bpmValues.max() ?? 0
        let avgBpm = bpmValues.reduce(0, +) / bpmValues.count
        
        let oldestDate = all.last?.timestampAsDate ?? Date()
        let newestDate = all.first?.timestampAsDate ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        print("[\(TAG)] 📊 Database Summary:")
        print("  Total entries: \(all.count)")
        print("  Min BPM: \(minBpm)")
        print("  Max BPM: \(maxBpm)")
        print("  Avg BPM: \(avgBpm)")
        print("  Oldest: \(formatter.string(from: oldestDate))")
        print("  Newest: \(formatter.string(from: newestDate))")
    }
}

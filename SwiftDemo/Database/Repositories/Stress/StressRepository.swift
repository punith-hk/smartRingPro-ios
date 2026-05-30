import Foundation
import CoreData

/// Stress Repository
/// Handles all database operations for stress data
class StressRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "StressRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save new batch of stress readings from BLE device
    func saveNewBatch(readings: [(timestamp: Int64, level: Int)], completion: @escaping (Bool, Int) -> Void) {
        print("[\(TAG)] 🔵 saveNewBatch called with \(readings.count) readings")
        
        guard !readings.isEmpty else {
            print("[\(TAG)] ⚠️ No readings to save")
            completion(true, 0)
            return
        }
        
        print("[\(TAG)] 🔄 Starting background task...")
        
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else {
                print("[StressRepository] ⚠️ Self is nil in background task")
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
                StressEntity.create(
                    timestamp: reading.timestamp,
                    level: Int16(reading.level),
                    batchTime: batchTime,
                    in: backgroundContext
                )
            }
            
            // Save context
            do {
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved \(newReadings.count) new stress entries")
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
    
    /// Get all stress data ordered by timestamp descending
    func getAll() -> [StressEntity] {
        let request = StressEntity.fetchAll()
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) stress entries")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch all: \(error)")
            return []
        }
    }
    
    /// Get latest stress entry
    func getLatestEntry() -> StressEntity? {
        let request = StressEntity.fetchLatest()
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch latest: \(error)")
            return nil
        }
    }
    
    /// Get latest batch of synced data
    func getLatestBatch() -> [StressEntity] {
        let request = StressEntity.fetchAll()
        
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
    
    /// Get stress data for today
    func getTodayLatestEntry() -> StressEntity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = Int64(startOfDay.timeIntervalSince1970)
        let endTimestamp = Int64(endOfDay.timeIntervalSince1970)
        
        let request = StressEntity.fetchByDateRange(start: startTimestamp, end: endTimestamp)
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
    
    /// Get stress data for specific date range
    func getByDateRange(start: Date, end: Date) -> [StressEntity] {
        let startTimestamp = Int64(start.timeIntervalSince1970)
        let endTimestamp = Int64(end.timeIntervalSince1970)
        
        let request = StressEntity.fetchByDateRange(start: startTimestamp, end: endTimestamp)
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) entries for date range")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch by date range: \(error)")
            return []
        }
    }
    
    // MARK: - Helper Methods
    
    private func getExistingTimestamps(in context: NSManagedObjectContext) -> Set<Int64> {
        let request = StressEntity.fetchAll()
        request.propertiesToFetch = ["timestamp"]
        
        do {
            let results = try context.fetch(request)
            return Set(results.map { $0.timestamp })
        } catch {
            print("[\(TAG)] ❌ Failed to fetch existing timestamps: \(error)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete all stress data
    func deleteAll() {
        let request: NSFetchRequest<NSFetchRequestResult> = StressEntity.fetchRequest()
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(batchDelete)
            try context.save()
            print("[\(TAG)] 🗑️ Deleted all stress data")
        } catch {
            print("[\(TAG)] ❌ Failed to delete all: \(error)")
        }
    }
    
    /// Delete entries older than specified number of days
    func deleteOlderThan(days: Int) {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return }
        let cutoffTimestamp = Int64(cutoffDate.timeIntervalSince1970)
        
        let request: NSFetchRequest<NSFetchRequestResult> = StressEntity.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp < %lld", cutoffTimestamp)
        
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(batchDelete)
            try context.save()
            print("[\(TAG)] 🗑️ Deleted stress data older than \(days) days")
        } catch {
            print("[\(TAG)] ❌ Failed to delete old data: \(error)")
        }
    }
}

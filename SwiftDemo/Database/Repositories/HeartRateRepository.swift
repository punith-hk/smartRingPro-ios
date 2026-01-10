import Foundation
import CoreData

/// HeartRate Repository (equivalent to Android's HeartRateRepository)
/// Handles all database operations for heart rate data
class HeartRateRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "HeartRateRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save new batch of heart rate readings from BLE device
    /// Equivalent to Android's saveNewBatch(readings: List<Pair<Long, String>>)
    func saveNewBatch(readings: [(timestamp: Int64, bpm: Int)], completion: @escaping (Bool, Int) -> Void) {
        guard !readings.isEmpty else {
            print("[\(TAG)] ⚠️ No readings to save")
            completion(true, 0)
            return
        }
        
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            let batchTime = Int64(Date().timeIntervalSince1970)
            
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
                HeartRateEntity.create(
                    timestamp: reading.timestamp,
                    bpm: Int16(reading.bpm),
                    batchTime: batchTime,
                    in: backgroundContext
                )
            }
            
            // Save context
            do {
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved \(newReadings.count) new heart rate entries")
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
    
    /// Get all heart rates ordered by timestamp descending
    func getAll() -> [HeartRateEntity] {
        let request = HeartRateEntity.fetchAll()
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) heart rate entries")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch all: \(error)")
            return []
        }
    }
    
    /// Get latest heart rate entry
    func getLatestEntry() -> HeartRateEntity? {
        let request = HeartRateEntity.fetchLatest()
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch latest: \(error)")
            return nil
        }
    }
    
    /// Get latest batch of synced data
    func getLatestBatch() -> [HeartRateEntity] {
        let request = HeartRateEntity.fetchAll()
        
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
    
    /// Get heart rates for today
    func getTodayLatestEntry() -> HeartRateEntity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTimestamp = Int64(startOfDay.timeIntervalSince1970)
        let endTimestamp = Int64(endOfDay.timeIntervalSince1970)
        
        let request = HeartRateEntity.fetchByDateRange(start: startTimestamp, end: endTimestamp)
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
    
    /// Get heart rates for specific date range
    func getByDateRange(start: Date, end: Date) -> [HeartRateEntity] {
        let startTimestamp = Int64(start.timeIntervalSince1970)
        let endTimestamp = Int64(end.timeIntervalSince1970)
        
        let request = HeartRateEntity.fetchByDateRange(start: startTimestamp, end: endTimestamp)
        
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
    
    /// Delete all heart rate data
    func deleteAll() {
        CoreDataManager.shared.deleteAllData(for: "HeartRateEntity")
    }
    
    // MARK: - Helper Methods
    
    /// Get all existing timestamps (for duplicate checking)
    private func getExistingTimestamps(in context: NSManagedObjectContext) -> Set<Int64> {
        let request = NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
        request.propertiesToFetch = ["timestamp"]
        
        do {
            let results = try context.fetch(request)
            return Set(results.map { $0.timestamp })
        } catch {
            print("[\(TAG)] ❌ Failed to fetch existing timestamps: \(error)")
            return []
        }
    }
}

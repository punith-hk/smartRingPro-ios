import Foundation
import CoreData

/// Repository for daily aggregated hrv statistics
/// Stores data from API endpoint: getRingDataByDay
class HrvDailyStatsRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "HrvDailyStatsRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save or update daily stats from API
    func saveDailyStats(userId: Int, date: String, value: String, diastolicValue: String, completion: @escaping (Bool) -> Void) {
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            // Check if entry exists
            let fetchRequest = HrvDailyStatsEntity.fetchByUserAndDate(userId: userId, date: date, in: backgroundContext)
            
            do {
                let results = try backgroundContext.fetch(fetchRequest)
                
                let entity: HrvDailyStatsEntity
                if let existing = results.first {
                    // Update existing
                    entity = existing
                    print("[\(self.TAG)] 🔄 Updating existing entry for \(date)")
                } else {
                    // Create new
                    entity = HrvDailyStatsEntity(context: backgroundContext)
                    entity.userId = Int64(userId)
                    entity.date = date
                    print("[\(self.TAG)] ➕ Creating new entry for \(date)")
                }
                
                entity.value = value
                entity.diastolicValue = diastolicValue
                entity.lastUpdated = Int64(Date().timeIntervalSince1970)
                
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved daily stats for \(date), value: \(value)")
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("[\(self.TAG)] ❌ Failed to save: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Batch save multiple daily stats
    func saveBatch(userId: Int, stats: [(date: String, value: String, diastolicValue: String)], completion: @escaping (Bool, Int) -> Void) {
        guard !stats.isEmpty else {
            completion(true, 0)
            return
        }
        
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            var savedCount = 0
            
            for stat in stats {
                let fetchRequest = HrvDailyStatsEntity.fetchByUserAndDate(userId: userId, date: stat.date, in: backgroundContext)
                
                do {
                    let results = try backgroundContext.fetch(fetchRequest)
                    
                    let entity: HrvDailyStatsEntity
                    if let existing = results.first {
                        // Check if value changed
                        if existing.value != stat.value {
                            existing.value = stat.value
                            existing.diastolicValue = stat.diastolicValue
                            existing.lastUpdated = Int64(Date().timeIntervalSince1970)
                            savedCount += 1
                        }
                    } else {
                        // Create new
                        entity = HrvDailyStatsEntity(context: backgroundContext)
                        entity.userId = Int64(userId)
                        entity.date = stat.date
                        entity.value = stat.value
                        entity.diastolicValue = stat.diastolicValue
                        entity.lastUpdated = Int64(Date().timeIntervalSince1970)
                        savedCount += 1
                    }
                } catch {
                    print("[\(self.TAG)] ❌ Error processing \(stat.date): \(error)")
                }
            }
            
            do {
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Batch saved: \(savedCount) new/updated out of \(stats.count)")
                
                DispatchQueue.main.async {
                    completion(true, savedCount)
                }
            } catch {
                print("[\(self.TAG)] ❌ Failed to save batch: \(error)")
                DispatchQueue.main.async {
                    completion(false, 0)
                }
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Get all daily stats for a user, ordered by date descending
    func getAllForUser(userId: Int) -> [HrvDailyStatsEntity] {
        let request = HrvDailyStatsEntity.fetchAllForUser(userId: userId)
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) daily stats for user \(userId)")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch: \(error)")
            return []
        }
    }
    
    /// Get daily stats for last N days
    func getRecentDays(userId: Int, days: Int) -> [HrvDailyStatsEntity] {
        let request = HrvDailyStatsEntity.fetchAllForUser(userId: userId)
        request.fetchLimit = days
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] 📊 Fetched \(results.count) recent daily stats")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch recent: \(error)")
            return []
        }
    }
    
    /// Get daily stats for specific date
    func getByDate(userId: Int, date: String) -> HrvDailyStatsEntity? {
        let request = HrvDailyStatsEntity.fetchByUserAndDate(userId: userId, date: date, in: context)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch for date \(date): \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete all daily stats for a user
    func deleteAllForUser(userId: Int) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "HrvDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("[\(TAG)] ✅ Deleted all daily stats for user \(userId)")
        } catch {
            print("[\(TAG)] ❌ Failed to delete: \(error)")
        }
    }
    
    /// Delete all daily stats (for all users) - used during logout
    func deleteAll() {
        CoreDataManager.shared.deleteAllData(for: "HrvDailyStatsEntity")
    }
}

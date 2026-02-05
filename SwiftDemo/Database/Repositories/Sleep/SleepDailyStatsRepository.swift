import Foundation
import CoreData

/// Repository for daily aggregated sleep statistics
/// Stores daily sleep totals for weekly/monthly charts
class SleepDailyStatsRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "SleepDailyStatsRepository"
    
    static let shared = SleepDailyStatsRepository()
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save or update daily stats
    func saveDailyStats(
        userId: Int,
        date: String,
        deepSleepMinutes: Int,
        lightSleepMinutes: Int,
        remSleepMinutes: Int,
        awakeMinutes: Int,
        sessionCount: Int,
        completion: @escaping (Bool) -> Void
    ) {
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            // Check if entry exists
            let fetchRequest = SleepDailyStatsEntity.fetchByUserAndDate(userId: userId, date: date, in: backgroundContext)
            
            do {
                let results = try backgroundContext.fetch(fetchRequest)
                
                let entity: SleepDailyStatsEntity
                if let existing = results.first {
                    // Update existing
                    entity = existing
                    print("[\(self.TAG)] 🔄 Updating existing entry for \(date)")
                } else {
                    // Create new
                    entity = SleepDailyStatsEntity(context: backgroundContext)
                    entity.id = UUID()
                    entity.userId = Int64(userId)
                    entity.date = date
                    entity.createdAt = Date()
                    print("[\(self.TAG)] ➕ Creating new entry for \(date)")
                }
                
                entity.deepSleepMinutes = Int32(deepSleepMinutes)
                entity.lightSleepMinutes = Int32(lightSleepMinutes)
                entity.remSleepMinutes = Int32(remSleepMinutes)
                entity.awakeMinutes = Int32(awakeMinutes)
                entity.totalSleepMinutes = Int32(deepSleepMinutes + lightSleepMinutes + remSleepMinutes)
                entity.sessionCount = Int16(sessionCount)
                entity.lastUpdated = Int64(Date().timeIntervalSince1970)
                entity.updatedAt = Date()
                
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved daily stats for \(date): Deep=\(deepSleepMinutes)min, Light=\(lightSleepMinutes)min, REM=\(remSleepMinutes)min, Awake=\(awakeMinutes)min, Sessions=\(sessionCount)")
                
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
    
    /// Batch save multiple daily stats from API
    func saveBatch(userId: Int, stats: [(date: String, deep: Int, light: Int, rem: Int, awake: Int, sessionCount: Int)], completion: @escaping (Bool, Int) -> Void) {
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            var savedCount = 0
            
            for stat in stats {
                // Check if entry exists
                let fetchRequest = SleepDailyStatsEntity.fetchByUserAndDate(userId: userId, date: stat.date, in: backgroundContext)
                
                do {
                    let results = try backgroundContext.fetch(fetchRequest)
                    
                    let entity: SleepDailyStatsEntity
                    let isNew: Bool
                    
                    if let existing = results.first {
                        entity = existing
                        isNew = false
                        
                        // Check if values changed
                        let deepChanged = existing.deepSleepMinutes != Int32(stat.deep)
                        let lightChanged = existing.lightSleepMinutes != Int32(stat.light)
                        let remChanged = existing.remSleepMinutes != Int32(stat.rem)
                        let awakeChanged = existing.awakeMinutes != Int32(stat.awake)
                        
                        if !deepChanged && !lightChanged && !remChanged && !awakeChanged {
                            print("[\(self.TAG)] ⏭️ No changes for \(stat.date), skipping")
                            continue
                        }
                    } else {
                        entity = SleepDailyStatsEntity(context: backgroundContext)
                        entity.id = UUID()
                        entity.userId = Int64(userId)
                        entity.date = stat.date
                        entity.createdAt = Date()
                        isNew = true
                    }
                    
                    entity.deepSleepMinutes = Int32(stat.deep)
                    entity.lightSleepMinutes = Int32(stat.light)
                    entity.remSleepMinutes = Int32(stat.rem)
                    entity.awakeMinutes = Int32(stat.awake)
                    entity.totalSleepMinutes = Int32(stat.deep + stat.light + stat.rem)
                    entity.sessionCount = Int16(stat.sessionCount)
                    entity.lastUpdated = Int64(Date().timeIntervalSince1970)
                    entity.updatedAt = Date()
                    
                    savedCount += 1
                    print("[\(self.TAG)] \(isNew ? "➕" : "🔄") \(stat.date): Deep=\(stat.deep)min, Light=\(stat.light)min, REM=\(stat.rem)min")
                    
                } catch {
                    print("[\(self.TAG)] ❌ Failed to process \(stat.date): \(error)")
                }
            }
            
            // Save context
            do {
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("[\(self.TAG)] ✅ Batch saved \(savedCount) daily stats")
                    DispatchQueue.main.async {
                        completion(true, savedCount)
                    }
                } else {
                    print("[\(self.TAG)] ℹ️ No changes to save")
                    DispatchQueue.main.async {
                        completion(true, 0)
                    }
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
    
    /// Get daily stats for specific date
    func getDailyStats(userId: Int, date: String) -> SleepDailyStatsEntity? {
        let request = SleepDailyStatsEntity.fetchByUserAndDate(userId: userId, date: date, in: context)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch for \(date): \(error)")
            return nil
        }
    }
    
    /// Get daily stats for a date range
    func getDateRange(userId: Int, startDate: String, endDate: String) -> [SleepDailyStatsEntity] {
        let request = SleepDailyStatsEntity.fetchByDateRange(userId: userId, startDate: startDate, endDate: endDate)
        
        do {
            let results = try context.fetch(request)
            print("[\(TAG)] ✅ Fetched \(results.count) daily stats for range \(startDate) - \(endDate)")
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch range: \(error)")
            return []
        }
    }
    
    /// Get all daily stats for a user
    func getAllForUser(userId: Int) -> [SleepDailyStatsEntity] {
        let request = SleepDailyStatsEntity.fetchAllForUser(userId: userId)
        
        do {
            let results = try context.fetch(request)
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch all: \(error)")
            return []
        }
    }
    
    /// Get recent N days
    func getRecentDays(userId: Int, days: Int) -> [SleepDailyStatsEntity] {
        let request = SleepDailyStatsEntity.fetchAllForUser(userId: userId)
        request.fetchLimit = days
        
        do {
            let results = try context.fetch(request)
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch recent days: \(error)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete all daily stats for a user
    func deleteAll(userId: Int, completion: @escaping (Bool) -> Void) {
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            let request = SleepDailyStatsEntity.fetchAllForUser(userId: userId)
            
            do {
                let results = try backgroundContext.fetch(request)
                for entity in results {
                    backgroundContext.delete(entity)
                }
                
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Deleted all daily stats for user \(userId)")
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("[\(self.TAG)] ❌ Failed to delete: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}

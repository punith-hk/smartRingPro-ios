import Foundation
import CoreData

/// Repository for daily aggregated steps/calories statistics
/// Aggregates raw steps data by day for efficient charting
class StepsDailyStatsRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "StepsDailyStatsRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save or update daily stats (aggregated from raw data)
    func saveDailyStats(
        userId: Int,
        date: String,
        totalSteps: Int,
        totalDistance: Int,
        totalCalories: Int,
        minCalories: Int,
        maxCalories: Int,
        avgCalories: Int,
        completion: @escaping (Bool) -> Void
    ) {
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            // Check if entry exists
            let fetchRequest = StepsDailyStatsEntity.fetchByUserAndDate(userId: userId, date: date, in: backgroundContext)
            
            do {
                let results = try backgroundContext.fetch(fetchRequest)
                
                let entity: StepsDailyStatsEntity
                if let existing = results.first {
                    // Update existing
                    entity = existing
                    print("[\(self.TAG)] 🔄 Updating existing entry for \(date)")
                } else {
                    // Create new
                    entity = StepsDailyStatsEntity(context: backgroundContext)
                    entity.id = UUID()
                    entity.userId = Int64(userId)
                    entity.date = date
                    entity.createdAt = Date()
                    print("[\(self.TAG)] ➕ Creating new entry for \(date)")
                }
                
                entity.totalSteps = Int64(totalSteps)
                entity.totalDistance = Int64(totalDistance)
                entity.totalCalories = Int64(totalCalories)
                entity.minCalories = Int16(minCalories)
                entity.maxCalories = Int16(maxCalories)
                entity.avgCalories = Int16(avgCalories)
                entity.lastUpdated = Int64(Date().timeIntervalSince1970)
                entity.updatedAt = Date()
                
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved daily stats for \(date): \(totalSteps) steps, \(totalCalories) kcal")
                
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
    func saveBatch(
        userId: Int,
        stats: [(date: String, totalSteps: Int, totalDistance: Int, totalCalories: Int, minCalories: Int, maxCalories: Int, avgCalories: Int)],
        completion: @escaping (Bool, Int) -> Void
    ) {
        guard !stats.isEmpty else {
            completion(true, 0)
            return
        }
        
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            var savedCount = 0
            
            for stat in stats {
                let fetchRequest = StepsDailyStatsEntity.fetchByUserAndDate(userId: userId, date: stat.date, in: backgroundContext)
                
                do {
                    let results = try backgroundContext.fetch(fetchRequest)
                    
                    if let existing = results.first {
                        // Check if values changed
                        if existing.totalSteps != Int64(stat.totalSteps) ||
                           existing.totalCalories != Int64(stat.totalCalories) {
                            existing.totalSteps = Int64(stat.totalSteps)
                            existing.totalDistance = Int64(stat.totalDistance)
                            existing.totalCalories = Int64(stat.totalCalories)
                            existing.minCalories = Int16(stat.minCalories)
                            existing.maxCalories = Int16(stat.maxCalories)
                            existing.avgCalories = Int16(stat.avgCalories)
                            existing.lastUpdated = Int64(Date().timeIntervalSince1970)
                            existing.updatedAt = Date()
                            savedCount += 1
                        }
                    } else {
                        // Create new
                        let entity = StepsDailyStatsEntity(context: backgroundContext)
                        entity.id = UUID()
                        entity.userId = Int64(userId)
                        entity.date = stat.date
                        entity.totalSteps = Int64(stat.totalSteps)
                        entity.totalDistance = Int64(stat.totalDistance)
                        entity.totalCalories = Int64(stat.totalCalories)
                        entity.minCalories = Int16(stat.minCalories)
                        entity.maxCalories = Int16(stat.maxCalories)
                        entity.avgCalories = Int16(stat.avgCalories)
                        entity.lastUpdated = Int64(Date().timeIntervalSince1970)
                        entity.createdAt = Date()
                        entity.updatedAt = Date()
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
    func getAllForUser(userId: Int) -> [StepsDailyStatsEntity] {
        let request = StepsDailyStatsEntity.fetchAllForUser(userId: userId)
        
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
    func getRecentDays(userId: Int, days: Int) -> [StepsDailyStatsEntity] {
        let request = StepsDailyStatsEntity.fetchAllForUser(userId: userId)
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
    func getByDate(userId: Int, date: String) -> StepsDailyStatsEntity? {
        let request = StepsDailyStatsEntity.fetchByUserAndDate(userId: userId, date: date, in: context)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch by date: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete all daily stats
    func deleteAll() {
        CoreDataManager.shared.deleteAllData(for: "StepsDailyStatsEntity")
    }
    
    /// Delete stats for specific user
    func deleteAllForUser(userId: Int) {
        let request = StepsDailyStatsEntity.fetchAllForUser(userId: userId)
        
        do {
            let results = try context.fetch(request)
            for entity in results {
                context.delete(entity)
            }
            try context.save()
            print("[\(TAG)] 🗑️ Deleted \(results.count) daily stats for user \(userId)")
        } catch {
            print("[\(TAG)] ❌ Failed to delete: \(error)")
        }
    }
}

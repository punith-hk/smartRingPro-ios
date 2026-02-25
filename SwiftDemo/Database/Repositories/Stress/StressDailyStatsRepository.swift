import Foundation
import CoreData

/// Repository for stress daily aggregated stats
class StressDailyStatsRepository {
    
    private let context: NSManagedObjectContext
    private let TAG = "StressDailyStatsRepository"
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    // MARK: - Save Operations
    
    /// Save batch of daily stats from API
    func saveBatch(userId: Int, stats: [(date: String, value: String)]) {
        CoreDataManager.shared.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            for stat in stats {
                _ = StressDailyStatsEntity.createOrUpdate(
                    userId: userId,
                    date: stat.date,
                    value: stat.value,
                    in: backgroundContext
                )
            }
            
            do {
                try backgroundContext.save()
                print("[\(self.TAG)] ✅ Saved \(stats.count) daily stats")
            } catch {
                print("[\(self.TAG)] ❌ Failed to save batch: \(error)")
            }
        }
    }
    
    /// Save or update single daily stat
    func saveOrUpdate(userId: Int, date: String, value: String) {
        _ = StressDailyStatsEntity.createOrUpdate(
            userId: userId,
            date: date,
            value: value,
            in: context
        )
        
        do {
            try context.save()
            print("[\(TAG)] ✅ Saved/updated daily stat for \(date)")
        } catch {
            print("[\(TAG)] ❌ Failed to save: \(error)")
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Get all daily stats for user
    func getAllForUser(userId: Int) -> [StressDailyStatsEntity] {
        let request = StressDailyStatsEntity.fetchAllForUser(userId: userId)
        
        do {
            let results = try context.fetch(request)
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch all for user: \(error)")
            return []
        }
    }
    
    /// Get recent N days for user
    func getRecentDays(userId: Int, days: Int) -> [StressDailyStatsEntity] {
        let request = StressDailyStatsEntity.fetchRecentDays(userId: userId, days: days)
        
        do {
            let results = try context.fetch(request)
            return results
        } catch {
            print("[\(TAG)] ❌ Failed to fetch recent days: \(error)")
            return []
        }
    }
    
    /// Get stat for specific date
    func getForDate(userId: Int, date: String) -> StressDailyStatsEntity? {
        let request = NSFetchRequest<StressDailyStatsEntity>(entityName: "StressDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("[\(TAG)] ❌ Failed to fetch for date: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete all stats for user
    func deleteAllForUser(userId: Int) {
        let request: NSFetchRequest<NSFetchRequestResult> = StressDailyStatsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %d", userId)
        
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(batchDelete)
            try context.save()
            print("[\(TAG)] 🗑️ Deleted all stats for user \(userId)")
        } catch {
            print("[\(TAG)] ❌ Failed to delete: \(error)")
        }
    }
}

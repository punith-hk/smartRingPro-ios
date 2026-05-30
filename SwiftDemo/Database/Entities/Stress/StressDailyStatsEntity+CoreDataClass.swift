import Foundation
import CoreData

@objc(StressDailyStatsEntity)
public class StressDailyStatsEntity: NSManagedObject {
    
    /// Create or update daily stress stats
    static func createOrUpdate(userId: Int, date: String, value: String, in context: NSManagedObjectContext) -> StressDailyStatsEntity {
        // Try to find existing entry
        let request = NSFetchRequest<StressDailyStatsEntity>(entityName: "StressDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        request.fetchLimit = 1
        
        if let existing = try? context.fetch(request).first {
            // Update existing
            existing.value = value
            return existing
        } else {
            // Create new
            let entity = StressDailyStatsEntity(context: context)
            entity.userId = Int32(userId)
            entity.date = date
            entity.value = value
            return entity
        }
    }
    
    /// Fetch all daily stats for a user
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<StressDailyStatsEntity> {
        let request = NSFetchRequest<StressDailyStatsEntity>(entityName: "StressDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch recent days for a user
    static func fetchRecentDays(userId: Int, days: Int) -> NSFetchRequest<StressDailyStatsEntity> {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return fetchAllForUser(userId: userId)
        }
        
        let startDateString = dateFormatter.string(from: startDate)
        
        let request = NSFetchRequest<StressDailyStatsEntity>(entityName: "StressDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date >= %@", userId, startDateString)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
}

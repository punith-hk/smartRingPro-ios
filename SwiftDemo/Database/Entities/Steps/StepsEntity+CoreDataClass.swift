import Foundation
import CoreData

/// Steps Core Data entity extension
/// Provides helper methods and computed properties
extension StepsEntity {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new Steps entry
    @discardableResult
    static func create(
        timestamp: Int64,
        steps: Int16,
        distance: Int16,
        calories: Int16,
        batchTime: Int64,
        in context: NSManagedObjectContext
    ) -> StepsEntity {
        let entity = StepsEntity(context: context)
        entity.id = UUID()
        entity.timestamp = timestamp
        entity.steps = steps
        entity.distance = distance
        entity.calories = calories
        entity.batchTime = batchTime
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch all steps ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<StepsEntity> {
        let request = NSFetchRequest<StepsEntity>(entityName: "StepsEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch steps for a specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<StepsEntity> {
        let request = NSFetchRequest<StepsEntity>(entityName: "StepsEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    /// Fetch latest entry
    static func fetchLatest() -> NSFetchRequest<StepsEntity> {
        let request = NSFetchRequest<StepsEntity>(entityName: "StepsEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch all existing timestamps (for duplicate checking)
    static func fetchAllTimestamps() -> NSFetchRequest<StepsEntity> {
        let request = NSFetchRequest<StepsEntity>(entityName: "StepsEntity")
        request.propertiesToFetch = ["timestamp"]
        request.resultType = .dictionaryResultType
        return request
    }
    
    // MARK: - Helper Methods
    
    /// Convert to readable date string
    var timestampAsDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    /// Format timestamp as string
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestampAsDate)
    }
    
    /// Debug description
    public override var debugDescription: String {
        return "Steps(timestamp: \(timestamp), steps: \(steps), distance: \(distance)m, calories: \(calories)kcal, date: \(formattedTimestamp))"
    }
}

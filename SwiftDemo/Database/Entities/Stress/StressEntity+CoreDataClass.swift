import Foundation
import CoreData

@objc(StressEntity)
public class StressEntity: NSManagedObject {
    
    /// Create a new stress entry
    static func create(timestamp: Int64, level: Int16, batchTime: Int64, in context: NSManagedObjectContext) -> StressEntity {
        let entity = StressEntity(context: context)
        entity.timestamp = timestamp
        entity.level = level
        entity.batchTime = batchTime
        return entity
    }
    
    /// Fetch all stress entries ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<StressEntity> {
        let request = NSFetchRequest<StressEntity>(entityName: "StressEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch latest stress entry
    static func fetchLatest() -> NSFetchRequest<StressEntity> {
        let request = NSFetchRequest<StressEntity>(entityName: "StressEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch stress entries for specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<StressEntity> {
        let request = NSFetchRequest<StressEntity>(entityName: "StressEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
}

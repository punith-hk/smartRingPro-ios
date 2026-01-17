import Foundation
import CoreData

/// Blood Oxygen Core Data entity extension
/// Provides helper methods and computed properties
extension BloodOxygenEntity {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new Blood Oxygen entry
    @discardableResult
    static func create(
        timestamp: Int64,
        oxygenValue: Int16,
        batchTime: Int64,
        in context: NSManagedObjectContext
    ) -> BloodOxygenEntity {
        let entity = BloodOxygenEntity(context: context)
        entity.id = UUID()
        entity.timestamp = timestamp
        entity.oxygenValue = oxygenValue
        entity.batchTime = batchTime
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch all blood oxygen values ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<BloodOxygenEntity> {
        let request = NSFetchRequest<BloodOxygenEntity>(entityName: "BloodOxygenEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch blood oxygen values for a specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<BloodOxygenEntity> {
        let request = NSFetchRequest<BloodOxygenEntity>(entityName: "BloodOxygenEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    /// Fetch latest entry
    static func fetchLatest() -> NSFetchRequest<BloodOxygenEntity> {
        let request = NSFetchRequest<BloodOxygenEntity>(entityName: "BloodOxygenEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch latest batch (by batchTime)
    static func fetchLatestBatch() -> NSFetchRequest<BloodOxygenEntity> {
        let request = NSFetchRequest<BloodOxygenEntity>(entityName: "BloodOxygenEntity")
        
        // First find max batchTime, then fetch all entries with that batchTime
        let subquery = "batchTime == (SELECT MAX(batchTime) FROM BloodOxygenEntity)"
        request.predicate = NSPredicate(format: "batchTime == %@", argumentArray: [NSExpression(forKeyPath: "batchTime").description])
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return request
    }
    
    /// Fetch all existing timestamps (for duplicate checking)
    static func fetchAllTimestamps() -> NSFetchRequest<BloodOxygenEntity> {
        let request = NSFetchRequest<BloodOxygenEntity>(entityName: "BloodOxygenEntity")
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
        return "BloodOxygen(timestamp: \(timestamp), oxygen: \(oxygenValue)%, date: \(formattedTimestamp))"
    }
}

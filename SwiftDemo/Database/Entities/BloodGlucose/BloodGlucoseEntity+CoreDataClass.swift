import Foundation
import CoreData

/// Blood Glucose Core Data entity extension
/// Provides helper methods and computed properties
extension BloodGlucoseEntity {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new Blood Glucose entry
    @discardableResult
    static func create(
        timestamp: Int64,
        glucoseValue: Double,
        batchTime: Int64,
        in context: NSManagedObjectContext
    ) -> BloodGlucoseEntity {
        let entity = BloodGlucoseEntity(context: context)
        entity.id = UUID()
        entity.timestamp = timestamp
        entity.glucoseValue = glucoseValue
        entity.batchTime = batchTime
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch all blood glucose values ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<BloodGlucoseEntity> {
        let request = NSFetchRequest<BloodGlucoseEntity>(entityName: "BloodGlucoseEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch blood glucose values for a specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<BloodGlucoseEntity> {
        let request = NSFetchRequest<BloodGlucoseEntity>(entityName: "BloodGlucoseEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    /// Fetch latest entry
    static func fetchLatest() -> NSFetchRequest<BloodGlucoseEntity> {
        let request = NSFetchRequest<BloodGlucoseEntity>(entityName: "BloodGlucoseEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch latest batch (by batchTime)
    static func fetchLatestBatch() -> NSFetchRequest<BloodGlucoseEntity> {
        let request = NSFetchRequest<BloodGlucoseEntity>(entityName: "BloodGlucoseEntity")
        
        // First find max batchTime, then fetch all entries with that batchTime
        let subquery = "batchTime == (SELECT MAX(batchTime) FROM BloodGlucoseEntity)"
        request.predicate = NSPredicate(format: "batchTime == %@", argumentArray: [NSExpression(forKeyPath: "batchTime").description])
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return request
    }
    
    /// Fetch all existing timestamps (for duplicate checking)
    static func fetchAllTimestamps() -> NSFetchRequest<BloodGlucoseEntity> {
        let request = NSFetchRequest<BloodGlucoseEntity>(entityName: "BloodGlucoseEntity")
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
        return "BloodGlucose(timestamp: \(timestamp), glucose: \(glucoseValue)mg/dL, date: \(formattedTimestamp))"
    }
}

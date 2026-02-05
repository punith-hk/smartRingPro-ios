import Foundation
import CoreData

/// Blood Pressure Core Data entity extension
/// Provides helper methods and computed properties
extension BloodPressureEntity {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new Blood Pressure entry
    @discardableResult
    static func create(
        timestamp: Int64,
        systolicValue: Int16,
        diastolicValue: Int16,
        batchTime: Int64,
        in context: NSManagedObjectContext
    ) -> BloodPressureEntity {
        let entity = BloodPressureEntity(context: context)
        entity.id = UUID()
        entity.timestamp = timestamp
        entity.systolicValue = systolicValue
        entity.diastolicValue = diastolicValue
        entity.batchTime = batchTime
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch all blood pressure values ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<BloodPressureEntity> {
        let request = NSFetchRequest<BloodPressureEntity>(entityName: "BloodPressureEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch blood pressure values for a specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<BloodPressureEntity> {
        let request = NSFetchRequest<BloodPressureEntity>(entityName: "BloodPressureEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    /// Fetch latest entry
    static func fetchLatest() -> NSFetchRequest<BloodPressureEntity> {
        let request = NSFetchRequest<BloodPressureEntity>(entityName: "BloodPressureEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch latest batch (by batchTime)
    static func fetchLatestBatch() -> NSFetchRequest<BloodPressureEntity> {
        let request = NSFetchRequest<BloodPressureEntity>(entityName: "BloodPressureEntity")
        
        // First find max batchTime, then fetch all entries with that batchTime
        let subquery = "batchTime == (SELECT MAX(batchTime) FROM BloodPressureEntity)"
        request.predicate = NSPredicate(format: "batchTime == %@", argumentArray: [NSExpression(forKeyPath: "batchTime").description])
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return request
    }
    
    /// Fetch all existing timestamps (for duplicate checking)
    static func fetchAllTimestamps() -> NSFetchRequest<BloodPressureEntity> {
        let request = NSFetchRequest<BloodPressureEntity>(entityName: "BloodPressureEntity")
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
        return "BloodPressure(timestamp: \(timestamp), bp: \(systolicValue)/\(diastolicValue)mmHg, date: \(formattedTimestamp))"
    }
}

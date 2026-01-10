import Foundation
import CoreData

/// HeartRate Core Data entity extension
/// Provides helper methods and computed properties
extension HeartRateEntity {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new HeartRate entry
    @discardableResult
    static func create(
        timestamp: Int64,
        bpm: Int16,
        batchTime: Int64,
        in context: NSManagedObjectContext
    ) -> HeartRateEntity {
        let entity = HeartRateEntity(context: context)
        entity.id = UUID()
        entity.timestamp = timestamp
        entity.bpm = bpm
        entity.batchTime = batchTime
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch all heart rates ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<HeartRateEntity> {
        let request = NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch heart rates for a specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<HeartRateEntity> {
        let request = NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    /// Fetch latest entry
    static func fetchLatest() -> NSFetchRequest<HeartRateEntity> {
        let request = NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch latest batch (by batchTime)
    static func fetchLatestBatch() -> NSFetchRequest<HeartRateEntity> {
        let request = NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
        
        // First find max batchTime, then fetch all entries with that batchTime
        let subquery = "batchTime == (SELECT MAX(batchTime) FROM HeartRateEntity)"
        request.predicate = NSPredicate(format: "batchTime == %@", argumentArray: [NSExpression(forKeyPath: "batchTime").description])
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return request
    }
    
    /// Fetch all existing timestamps (for duplicate checking)
    static func fetchAllTimestamps() -> NSFetchRequest<HeartRateEntity> {
        let request = NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
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
    var debugDescription: String {
        return "HeartRate(timestamp: \(timestamp), bpm: \(bpm), date: \(formattedTimestamp))"
    }
}

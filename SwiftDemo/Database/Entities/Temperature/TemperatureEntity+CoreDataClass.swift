import Foundation
import CoreData

/// Temperature Core Data entity extension
/// Provides helper methods and computed properties
extension TemperatureEntity {
    
    // MARK: - Convenience Initializer
    
    /// Creates a new Temperature entry
    @discardableResult
    static func create(
        timestamp: Int64,
        temperatureValue: Double,
        batchTime: Int64,
        in context: NSManagedObjectContext
    ) -> TemperatureEntity {
        let entity = TemperatureEntity(context: context)
        entity.id = UUID()
        entity.timestamp = timestamp
        entity.temperatureValue = temperatureValue
        entity.batchTime = batchTime
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch all temperature values ordered by timestamp descending
    static func fetchAll() -> NSFetchRequest<TemperatureEntity> {
        let request = NSFetchRequest<TemperatureEntity>(entityName: "TemperatureEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    /// Fetch temperature values for a specific date range
    static func fetchByDateRange(start: Int64, end: Int64) -> NSFetchRequest<TemperatureEntity> {
        let request = NSFetchRequest<TemperatureEntity>(entityName: "TemperatureEntity")
        request.predicate = NSPredicate(format: "timestamp >= %lld AND timestamp < %lld", start, end)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
    
    /// Fetch latest entry
    static func fetchLatest() -> NSFetchRequest<TemperatureEntity> {
        let request = NSFetchRequest<TemperatureEntity>(entityName: "TemperatureEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        return request
    }
    
    /// Fetch latest batch (by batchTime)
    static func fetchLatestBatch() -> NSFetchRequest<TemperatureEntity> {
        let request = NSFetchRequest<TemperatureEntity>(entityName: "TemperatureEntity")
        
        // First find max batchTime, then fetch all entries with that batchTime
        let subquery = "batchTime == (SELECT MAX(batchTime) FROM TemperatureEntity)"
        request.predicate = NSPredicate(format: "batchTime == %@", argumentArray: [NSExpression(forKeyPath: "batchTime").description])
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return request
    }
    
    /// Fetch all existing timestamps (for duplicate checking)
    static func fetchAllTimestamps() -> NSFetchRequest<TemperatureEntity> {
        let request = NSFetchRequest<TemperatureEntity>(entityName: "TemperatureEntity")
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
        return "Temperature(timestamp: \(timestamp), temp: \(temperatureValue)°C, date: \(formattedTimestamp))"
    }
}

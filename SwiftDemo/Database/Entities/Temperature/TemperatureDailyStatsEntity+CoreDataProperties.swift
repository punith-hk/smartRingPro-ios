import Foundation
import CoreData

extension TemperatureDailyStatsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TemperatureDailyStatsEntity> {
        return NSFetchRequest<TemperatureDailyStatsEntity>(entityName: "TemperatureDailyStatsEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: Int64
    @NSManaged public var date: String?
    @NSManaged public var value: String?
    @NSManaged public var diastolicValue: String?
    @NSManaged public var lastUpdated: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension TemperatureDailyStatsEntity : Identifiable {

}

// MARK: - Convenience Methods
extension TemperatureDailyStatsEntity {
    
    /// Fetch all daily stats for a user, ordered by date descending
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<TemperatureDailyStatsEntity> {
        let request = NSFetchRequest<TemperatureDailyStatsEntity>(entityName: "TemperatureDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch daily stats for specific user and date
    static func fetchByUserAndDate(userId: Int, date: String, in context: NSManagedObjectContext) -> NSFetchRequest<TemperatureDailyStatsEntity> {
        let request = NSFetchRequest<TemperatureDailyStatsEntity>(entityName: "TemperatureDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        return request
    }
}

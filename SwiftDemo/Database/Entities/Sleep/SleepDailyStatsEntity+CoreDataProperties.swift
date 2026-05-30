import Foundation
import CoreData

extension SleepDailyStatsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepDailyStatsEntity> {
        return NSFetchRequest<SleepDailyStatsEntity>(entityName: "SleepDailyStatsEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: Int64
    @NSManaged public var date: String?
    @NSManaged public var deepSleepMinutes: Int32
    @NSManaged public var lightSleepMinutes: Int32
    @NSManaged public var remSleepMinutes: Int32
    @NSManaged public var awakeMinutes: Int32
    @NSManaged public var totalSleepMinutes: Int32
    @NSManaged public var sessionCount: Int16
    @NSManaged public var lastUpdated: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension SleepDailyStatsEntity : Identifiable {

}

// MARK: - Convenience Methods
extension SleepDailyStatsEntity {
    
    /// Fetch all daily stats for a user, ordered by date descending
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<SleepDailyStatsEntity> {
        let request = NSFetchRequest<SleepDailyStatsEntity>(entityName: "SleepDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch daily stats for specific user and date
    static func fetchByUserAndDate(userId: Int, date: String, in context: NSManagedObjectContext) -> NSFetchRequest<SleepDailyStatsEntity> {
        let request = NSFetchRequest<SleepDailyStatsEntity>(entityName: "SleepDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        return request
    }
    
    /// Fetch daily stats for a date range
    static func fetchByDateRange(userId: Int, startDate: String, endDate: String) -> NSFetchRequest<SleepDailyStatsEntity> {
        let request = NSFetchRequest<SleepDailyStatsEntity>(entityName: "SleepDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date >= %@ AND date <= %@", userId, startDate, endDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return request
    }
}

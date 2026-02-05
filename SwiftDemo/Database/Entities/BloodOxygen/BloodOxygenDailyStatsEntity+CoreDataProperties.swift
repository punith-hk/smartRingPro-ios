import Foundation
import CoreData

extension BloodOxygenDailyStatsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloodOxygenDailyStatsEntity> {
        return NSFetchRequest<BloodOxygenDailyStatsEntity>(entityName: "BloodOxygenDailyStatsEntity")
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

extension BloodOxygenDailyStatsEntity : Identifiable {

}

// MARK: - Convenience Methods
extension BloodOxygenDailyStatsEntity {
    
    /// Fetch all daily stats for a user, ordered by date descending
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<BloodOxygenDailyStatsEntity> {
        let request = NSFetchRequest<BloodOxygenDailyStatsEntity>(entityName: "BloodOxygenDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch daily stats for specific user and date
    static func fetchByUserAndDate(userId: Int, date: String, in context: NSManagedObjectContext) -> NSFetchRequest<BloodOxygenDailyStatsEntity> {
        let request = NSFetchRequest<BloodOxygenDailyStatsEntity>(entityName: "BloodOxygenDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        return request
    }
}

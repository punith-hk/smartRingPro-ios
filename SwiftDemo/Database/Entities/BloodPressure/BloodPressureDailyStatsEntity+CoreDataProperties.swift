import Foundation
import CoreData

extension BloodPressureDailyStatsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloodPressureDailyStatsEntity> {
        return NSFetchRequest<BloodPressureDailyStatsEntity>(entityName: "BloodPressureDailyStatsEntity")
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

extension BloodPressureDailyStatsEntity : Identifiable {

}

// MARK: - Convenience Methods
extension BloodPressureDailyStatsEntity {
    
    /// Fetch all daily stats for a user, ordered by date descending
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<BloodPressureDailyStatsEntity> {
        let request = NSFetchRequest<BloodPressureDailyStatsEntity>(entityName: "BloodPressureDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch daily stats for specific user and date
    static func fetchByUserAndDate(userId: Int, date: String, in context: NSManagedObjectContext) -> NSFetchRequest<BloodPressureDailyStatsEntity> {
        let request = NSFetchRequest<BloodPressureDailyStatsEntity>(entityName: "BloodPressureDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        return request
    }
}

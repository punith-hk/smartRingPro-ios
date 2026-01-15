import Foundation
import CoreData

extension BloodGlucoseDailyStatsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloodGlucoseDailyStatsEntity> {
        return NSFetchRequest<BloodGlucoseDailyStatsEntity>(entityName: "BloodGlucoseDailyStatsEntity")
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

extension BloodGlucoseDailyStatsEntity : Identifiable {

}

// MARK: - Convenience Methods
extension BloodGlucoseDailyStatsEntity {
    
    /// Fetch all daily stats for a user, ordered by date descending
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<BloodGlucoseDailyStatsEntity> {
        let request = NSFetchRequest<BloodGlucoseDailyStatsEntity>(entityName: "BloodGlucoseDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch daily stats for specific user and date
    static func fetchByUserAndDate(userId: Int, date: String, in context: NSManagedObjectContext) -> NSFetchRequest<BloodGlucoseDailyStatsEntity> {
        let request = NSFetchRequest<BloodGlucoseDailyStatsEntity>(entityName: "BloodGlucoseDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        return request
    }
}

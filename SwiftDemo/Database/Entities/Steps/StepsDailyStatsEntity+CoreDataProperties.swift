import Foundation
import CoreData

extension StepsDailyStatsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StepsDailyStatsEntity> {
        return NSFetchRequest<StepsDailyStatsEntity>(entityName: "StepsDailyStatsEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: Int64
    @NSManaged public var date: String?           // Format: "M/d/yyyy"
    @NSManaged public var totalSteps: Int64       // Sum of all steps for the day
    @NSManaged public var totalDistance: Int64    // Sum of all distance (meters)
    @NSManaged public var totalCalories: Int64    // Sum of all calories (kcal)
    @NSManaged public var minCalories: Int16      // Min calories in a single reading
    @NSManaged public var maxCalories: Int16      // Max calories in a single reading
    @NSManaged public var avgCalories: Int16      // Average calories
    @NSManaged public var lastUpdated: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension StepsDailyStatsEntity : Identifiable {

}

// MARK: - Convenience Methods
extension StepsDailyStatsEntity {
    
    /// Fetch all daily stats for a user, ordered by date descending
    static func fetchAllForUser(userId: Int) -> NSFetchRequest<StepsDailyStatsEntity> {
        let request = NSFetchRequest<StepsDailyStatsEntity>(entityName: "StepsDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
    
    /// Fetch daily stats for specific user and date
    static func fetchByUserAndDate(userId: Int, date: String, in context: NSManagedObjectContext) -> NSFetchRequest<StepsDailyStatsEntity> {
        let request = NSFetchRequest<StepsDailyStatsEntity>(entityName: "StepsDailyStatsEntity")
        request.predicate = NSPredicate(format: "userId == %d AND date == %@", userId, date)
        return request
    }
}

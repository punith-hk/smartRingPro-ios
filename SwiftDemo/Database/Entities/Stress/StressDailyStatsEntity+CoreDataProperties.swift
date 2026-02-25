import Foundation
import CoreData

extension StressDailyStatsEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StressDailyStatsEntity> {
        return NSFetchRequest<StressDailyStatsEntity>(entityName: "StressDailyStatsEntity")
    }
    
    @NSManaged public var userId: Int32
    @NSManaged public var date: String?
    @NSManaged public var value: String?
}

extension StressDailyStatsEntity : Identifiable {
}

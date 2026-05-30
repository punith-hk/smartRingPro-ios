import Foundation
import CoreData

extension StressEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StressEntity> {
        return NSFetchRequest<StressEntity>(entityName: "StressEntity")
    }
    
    @NSManaged public var timestamp: Int64
    @NSManaged public var level: Int16
    @NSManaged public var batchTime: Int64
}

extension StressEntity : Identifiable {
}

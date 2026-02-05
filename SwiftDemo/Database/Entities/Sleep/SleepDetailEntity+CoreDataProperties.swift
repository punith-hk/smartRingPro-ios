import Foundation
import CoreData

extension SleepDetailEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepDetailEntity> {
        return NSFetchRequest<SleepDetailEntity>(entityName: "SleepDetailEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Int64
    @NSManaged public var endTime: Int64
    @NSManaged public var duration: Int32
    @NSManaged public var sleepType: Int16
    @NSManaged public var session: SleepSessionEntity?

}

extension SleepDetailEntity : Identifiable {

}

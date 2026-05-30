import Foundation
import CoreData

extension SleepSessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepSessionEntity> {
        return NSFetchRequest<SleepSessionEntity>(entityName: "SleepSessionEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var statisticTime: Int64
    @NSManaged public var startTime: Int64
    @NSManaged public var endTime: Int64
    @NSManaged public var totalTimes: Int32
    @NSManaged public var deepSleepTimes: Int32
    @NSManaged public var lightSleepTimes: Int32
    @NSManaged public var remSleepTimes: Int32
    @NSManaged public var wakeupTimes: Int32
    @NSManaged public var batchTime: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var details: NSSet?

}

// MARK: Generated accessors for details
extension SleepSessionEntity {

    @objc(addDetailsObject:)
    @NSManaged public func addToDetails(_ value: SleepDetailEntity)

    @objc(removeDetailsObject:)
    @NSManaged public func removeFromDetails(_ value: SleepDetailEntity)

    @objc(addDetails:)
    @NSManaged public func addToDetails(_ values: NSSet)

    @objc(removeDetails:)
    @NSManaged public func removeFromDetails(_ values: NSSet)

}

extension SleepSessionEntity : Identifiable {

}

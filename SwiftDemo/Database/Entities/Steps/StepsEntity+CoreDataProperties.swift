import Foundation
import CoreData

/// Steps Core Data properties
/// Stores step data synced from BLE device (YCHealthDataStep)
@objc(StepsEntity)
public class StepsEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (startTimeStamp from device)
    @NSManaged public var steps: Int16          // Number of steps
    @NSManaged public var distance: Int16       // Distance in meters
    @NSManaged public var calories: Int16       // Calories burned in kcal
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

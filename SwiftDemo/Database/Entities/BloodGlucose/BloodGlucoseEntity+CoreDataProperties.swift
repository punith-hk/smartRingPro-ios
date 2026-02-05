import Foundation
import CoreData

/// Blood Glucose Core Data properties
/// Auto-generated properties for the Core Data entity
@objc(BloodGlucoseEntity)
public class BloodGlucoseEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (unique)
    @NSManaged public var glucoseValue: Double  // Blood glucose value (mg/dL)
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

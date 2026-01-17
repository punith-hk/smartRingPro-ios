import Foundation
import CoreData

/// Blood Pressure Core Data properties
/// Auto-generated properties for the Core Data entity
@objc(BloodPressureEntity)
public class BloodPressureEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (unique)
    @NSManaged public var systolicValue: Int16  // Systolic blood pressure (mmHg)
    @NSManaged public var diastolicValue: Int16 // Diastolic blood pressure (mmHg)
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

import Foundation
import CoreData

/// Blood Oxygen Core Data properties
/// Auto-generated properties for the Core Data entity
@objc(BloodOxygenEntity)
public class BloodOxygenEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (unique)
    @NSManaged public var oxygenValue: Int16    // Blood oxygen value (%)
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

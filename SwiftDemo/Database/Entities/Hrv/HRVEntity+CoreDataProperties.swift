import Foundation
import CoreData

/// HRV Core Data properties
/// Auto-generated properties for the Core Data entity
@objc(HRVEntity)
public class HRVEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (unique)
    @NSManaged public var hrvValue: Int16       // HRV value (ms)
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

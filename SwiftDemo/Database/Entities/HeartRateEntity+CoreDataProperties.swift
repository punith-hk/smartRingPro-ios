import Foundation
import CoreData

/// HeartRate Core Data properties
/// Auto-generated properties for the Core Data entity
@objc(HeartRateEntity)
public class HeartRateEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (unique)
    @NSManaged public var bpm: Int16            // Heart rate value
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

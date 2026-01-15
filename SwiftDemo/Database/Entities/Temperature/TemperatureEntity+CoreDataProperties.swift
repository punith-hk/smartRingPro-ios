import Foundation
import CoreData

/// Temperature Core Data properties
/// Auto-generated properties for the Core Data entity
@objc(TemperatureEntity)
public class TemperatureEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Int64      // Unix timestamp (unique)
    @NSManaged public var temperatureValue: Double // Temperature value (°C)
    @NSManaged public var batchTime: Int64      // When this batch was synced from BLE
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

import Foundation
import CoreData

/// ECG Record Core Data properties
extension ECGRecordEntity {
    
    @NSManaged public var timestamp: String          // "yyyy-MM-dd HH:mm:ss" (Primary key)
    @NSManaged public var heartRate: Int16
    @NSManaged public var sbp: Int16                 // Systolic BP
    @NSManaged public var dbp: Int16                 // Diastolic BP
    @NSManaged public var hrv: Int16
    @NSManaged public var ecgList: Data?             // [Int] encoded as binary
    @NSManaged public var diagnoseType: Int16        // 0-7 (0 = failed, should never be saved)
    @NSManaged public var isAfib: Bool
    @NSManaged public var hrvIndex: Double
    @NSManaged public var loadIndex: Double
    @NSManaged public var pressureIndex: Double
    @NSManaged public var bodyIndex: Double
    @NSManaged public var bloodOxygen: Int16         // SpO2
    @NSManaged public var temperature: Double
    @NSManaged public var respiratoryRate: Double    // Always 0 (iOS doesn't have)
    @NSManaged public var symParaIndex: Double       // Always 0 (iOS doesn't have)
    @NSManaged public var flag: Int16                // Always 0 (iOS doesn't have)
    @NSManaged public var isSynced: Bool             // Upload status flag
    @NSManaged public var createdAt: Date
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ECGRecordEntity> {
        return NSFetchRequest<ECGRecordEntity>(entityName: "ECGRecordEntity")
    }
}

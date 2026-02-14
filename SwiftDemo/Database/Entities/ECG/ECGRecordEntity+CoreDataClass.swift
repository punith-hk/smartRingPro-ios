import Foundation
import CoreData

/// ECG Record Core Data entity
/// Stores complete ECG measurement with waveform and body indexes
@objc(ECGRecordEntity)
public class ECGRecordEntity: NSManagedObject {
    
    /// Create a new ECG record entity
    static func create(
        timestamp: String,
        heartRate: Int,
        sbp: Int,
        dbp: Int,
        hrv: Int,
        ecgList: [Int],
        diagnoseType: Int,
        isAfib: Bool,
        hrvIndex: Double,
        loadIndex: Double,
        pressureIndex: Double,
        bodyIndex: Double,
        bloodOxygen: Int,
        temperature: Double,
        in context: NSManagedObjectContext
    ) -> ECGRecordEntity {
        let entity = ECGRecordEntity(context: context)
        entity.timestamp = timestamp
        entity.heartRate = Int16(heartRate)
        entity.sbp = Int16(sbp)
        entity.dbp = Int16(dbp)
        entity.hrv = Int16(hrv)
        
        // Encode ecgList as Data
        if let encoded = try? JSONEncoder().encode(ecgList) {
            entity.ecgList = encoded
        }
        
        entity.diagnoseType = Int16(diagnoseType)
        entity.isAfib = isAfib
        entity.hrvIndex = hrvIndex
        entity.loadIndex = loadIndex
        entity.pressureIndex = pressureIndex
        entity.bodyIndex = bodyIndex
        entity.bloodOxygen = Int16(bloodOxygen)
        entity.temperature = temperature
        
        // Fields iOS doesn't have (always 0)
        entity.respiratoryRate = 0.0
        entity.symParaIndex = 0.0
        entity.flag = 0
        
        entity.isSynced = false
        entity.createdAt = Date()
        
        return entity
    }
    
    /// Decode ecgList from Data
    func getECGList() -> [Int] {
        guard let data = ecgList else { return [] }
        return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
    }
}

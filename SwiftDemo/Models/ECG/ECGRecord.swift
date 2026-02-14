import Foundation

/// ECG Record model for API and display
/// Matches Android's EcgRecord structure
struct ECGRecord: Codable {
    let timestamp: String              // "yyyy-MM-dd HH:mm:ss"
    let heartRate: Int
    let sbp: Int
    let dbp: Int
    let hrv: Int
    let ecgList: [Int]                // Processed/drawn samples
    let diagnoseType: Int              // 0-7
    let isAfib: Bool
    let hrvIndex: Double?
    let loadIndex: Double?
    let pressureIndex: Double?
    let bodyIndex: Double?
    let bloodOxygen: Int
    let temperature: Double
    let respiratoryRate: Double?      // Always 0 for iOS
    let symParaIndex: Double?         // Always 0 for iOS
    let flag: Int?                    // Always 0 for iOS
    let isSynced: Bool?
    
    /// Create from Core Data entity
    init(from entity: ECGRecordEntity) {
        self.timestamp = entity.timestamp
        self.heartRate = Int(entity.heartRate)
        self.sbp = Int(entity.sbp)
        self.dbp = Int(entity.dbp)
        self.hrv = Int(entity.hrv)
        self.ecgList = entity.getECGList()
        self.diagnoseType = Int(entity.diagnoseType)
        self.isAfib = entity.isAfib
        self.hrvIndex = entity.hrvIndex
        self.loadIndex = entity.loadIndex
        self.pressureIndex = entity.pressureIndex
        self.bodyIndex = entity.bodyIndex
        self.bloodOxygen = Int(entity.bloodOxygen)
        self.temperature = entity.temperature
        self.respiratoryRate = entity.respiratoryRate
        self.symParaIndex = entity.symParaIndex
        self.flag = Int(entity.flag)
        self.isSynced = entity.isSynced
    }
    
    /// Convert to API format
    func toAPIFormat() -> [String: Any] {
        return [
            "timestamp": timestamp,
            "ecgData": ecgList,
            "heartRate": heartRate,
            "sbp": sbp,
            "dbp": dbp,
            "hrv": Double(hrv),
            "diagnose_type": diagnoseType,
            "is_afib": isAfib ? 1 : 0,
            "hrv_index": hrvIndex ?? 0.0,
            "load_index": loadIndex ?? 0.0,
            "pressure_index": pressureIndex ?? 0.0,
            "body_index": bodyIndex ?? 0.0,
            "respiratory_index": respiratoryRate ?? 0.0,
            "sym_para_index": symParaIndex ?? 0.0,
            "flag": flag ?? 0
        ]
    }
}

import Foundation

// MARK: - ECG Upload Request (Batch)
struct ECGUploadRequest: Codable {
    let records: [ECGRecordUpload]
    let type: String               // "ECG"
    let userId: Int
    
    /// Create request for uploading ECG records
    init(userId: Int, records: [ECGRecordUpload]) {
        self.userId = userId
        self.records = records
        self.type = "ECG"
    }
}

// MARK: - Single ECG Record for Upload
struct ECGRecordUpload: Codable {
    let timestamp: String              // "yyyy-MM-dd HH:mm:ss"
    let ecgData: [Int]                // Processed/drawn samples
    let heartRate: Int
    let sbp: Int
    let dbp: Int
    let hrv: Double
    let diagnose_type: Int
    let is_afib: Int                  // 1 or 0
    let hrv_index: Double
    let load_index: Double
    let pressure_index: Double
    let body_index: Double
    let respiratory_index: Double
    let sym_para_index: Double
    let flag: Int
    
    /// Create from ECGRecord
    init(from record: ECGRecord) {
        self.timestamp = record.timestamp
        self.ecgData = record.ecgList
        self.heartRate = record.heartRate
        self.sbp = record.sbp
        self.dbp = record.dbp
        self.hrv = Double(record.hrv)
        self.diagnose_type = record.diagnoseType
        self.is_afib = record.isAfib ? 1 : 0
        self.hrv_index = record.hrvIndex ?? 0.0
        self.load_index = record.loadIndex ?? 0.0
        self.pressure_index = record.pressureIndex ?? 0.0
        self.body_index = record.bodyIndex ?? 0.0
        self.respiratory_index = record.respiratoryRate ?? 0.0
        self.sym_para_index = record.symParaIndex ?? 0.0
        self.flag = record.flag ?? 0
    }
}

// MARK: - ECG Upload Response
struct ECGUploadResponse: Codable {
    let code: Int?
    let message: String
    let data: ECGUploadData?
    
    struct ECGUploadData: Codable {
        let uploaded: Int?
        let serverIds: [String]?
    }
}

// MARK: - ECG Fetch Response (GET endpoint)
struct ECGFetchResponse: Codable {
    let code: Int?
    let message: String?
    let data: [ECGRecordDTO]?
    
    // Allow decoding from direct array OR wrapped object
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            // Wrapped format: {"code":0,"message":"","data":[...]}
            self.code = try? container.decode(Int.self, forKey: .code)
            self.message = try? container.decode(String.self, forKey: .message)
            self.data = try? container.decode([ECGRecordDTO].self, forKey: .data)
        } else if let array = try? decoder.singleValueContainer().decode([ECGRecordDTO].self) {
            // Direct array format: [...]
            self.code = nil
            self.message = nil
            self.data = array
        } else {
            // Empty or invalid response
            self.code = nil
            self.message = nil
            self.data = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case code, message, data
    }
}

// MARK: - ECG Record DTO (from server)
struct ECGRecordDTO: Codable {
    // Server's primary fields
    let id: Int?
    let userId: Int?
    let recordTimestamp: String       // ISO8601: "2026-02-14T19:50:28.000000Z"
    let ecgData: [Int]
    let heartRate: Int?
    let sbp: Int?
    let dbp: Int?
    let hrv: Double?
    let diagnoseType: Int?
    let isAfib: Bool?                 // Boolean from server
    let hrvIndex: Double?
    let loadIndex: Double?
    let pressureIndex: Double?
    let bodyIndex: Double?
    let respiratoryIndex: Int?        // Server returns Int
    let symParaIndex: Double?
    let flag: Int?
    
    // Server metadata
    let createdAt: String?
    let updatedAt: String?
    
    // Map Swift property names to server's snake_case JSON keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recordTimestamp = "record_timestamp"
        case ecgData = "ecg_data"
        case heartRate = "heart_rate"
        case sbp
        case dbp
        case hrv
        case diagnoseType = "diagnose_type"
        case isAfib = "is_afib"
        case hrvIndex = "hrv_index"
        case loadIndex = "load_index"
        case pressureIndex = "pressure_index"
        case bodyIndex = "body_index"
        case respiratoryIndex = "respiratory_index"
        case symParaIndex = "sym_para_index"
        case flag
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

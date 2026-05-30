import Foundation

// MARK: - Ring Value Entry
struct RingValueEntry: Codable {
    let value: String
    let timestamp: Int64
}

// MARK: - Create Ring Values Request
struct CreateRingValuesRequest: Codable {
    let user_id: Int
    let type: String
    let values: [RingValueEntry]
}

// MARK: - Add User Health Data Response
struct AddUserHealthDataResponse: Codable {
    let message: String
    let data: AddHealthData
    
    struct AddHealthData: Codable {
        let user_id: String
        let type: String
        let value: String
        let updated_at: String
        let created_at: String
        let id: Int
    }
}

// MARK: - Batch Upload Response (simple message only)
struct BatchUploadResponse: Codable {
    let message: String
}

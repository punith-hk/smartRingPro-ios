import Foundation

struct GetRingDataByTypeResponse: Codable {

    let message: String
    let data: [RingData]

    struct RingData: Codable {
        let id: Int
        let user_id: Int
        let type: String
        let value: String
        let timestamp: Int
        let created_at: String
        let updated_at: String
    }
}

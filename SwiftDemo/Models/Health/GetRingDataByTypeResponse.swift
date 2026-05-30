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

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id         = try c.decode(Int.self,    forKey: .id)
            user_id    = try c.decode(Int.self,    forKey: .user_id)
            type       = try c.decode(String.self, forKey: .type)
            timestamp  = try c.decode(Int.self,    forKey: .timestamp)
            created_at = try c.decode(String.self, forKey: .created_at)
            updated_at = try c.decode(String.self, forKey: .updated_at)
            // value can arrive as a JSON string ("98") or a JSON number (97.34)
            if let str = try? c.decode(String.self, forKey: .value) {
                value = str
            } else {
                let num = try c.decode(Double.self, forKey: .value)
                value = String(num)
            }
        }
    }
}

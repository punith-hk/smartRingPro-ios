import Foundation

// MARK: - Linked Account Info
struct LinkedAccountInfo: Codable {
    let id: Int
    let name: String
    let phone_number: String
    let relation: String?
}

// MARK: - Add Linked Account Response
struct AddLinkedAccountResponse: Codable {
    let receiver_id: Int?
    let message: String
}

// MARK: - Verify OTP Response
struct CaretakerVerifyOtpResponse: Codable {
    let message: String
}

// MARK: - Request Bodies
struct CaretakerRequestBody: Codable {
    let user_id: Int
    let phone_number: String
}

struct CaretakerVerifyOtpRequestBody: Codable {
    let user_id: Int
    let receiver_id: Int
    let otp: Int
    let relation: String
}

// MARK: - Last Ring Data
struct LastRingDataResponse: Codable {
    let message: String
    let data: [RingDataItem]
    let location: LocationData?
}

struct RingDataItem: Codable {
    let type: String
    let value: String
    let symptom: String?
    let message: String?
    let predictionKey: String?

    enum CodingKeys: String, CodingKey {
        case type, value, symptom, message, predictionKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(String.self, forKey: .type)
        symptom = try? container.decode(String.self, forKey: .symptom)
        message = try? container.decode(String.self, forKey: .message)
        predictionKey = try? container.decode(String.self, forKey: .predictionKey)

        // 🔥 HANDLE MIXED TYPES SAFELY
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .value) {
            value = "\(intValue)"
        } else if let doubleValue = try? container.decode(Double.self, forKey: .value) {
            value = String(format: "%.2f", doubleValue)
        } else {
            value = "-"
        }
    }
}


struct LocationData: Codable {
    let id: Int
    let user_id: Int
    let os: Int?
    let version: String?
    let app_version: String?
    let firmware_version: String?
    let location: Int?
    let bluetooth: Int?
    let ring: Int?
    let status: String?
    let battery: Int?
    let latitude: String?
    let longitude: String?
    let created_at: String?
    let updated_at: String?
}

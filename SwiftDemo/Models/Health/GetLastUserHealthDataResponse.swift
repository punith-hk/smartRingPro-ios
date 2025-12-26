import Foundation

struct GetLastUserHealthDataResponse: Codable {

    let message: String
    let data: [HealthData]
    let location: LocationData?

    struct HealthData: Codable {

        let type: String
        let value: String
        let symptom: String?
        let message: String?
        let predictionKey: String?
        let alertMessage: AlertMessage?

        enum CodingKeys: String, CodingKey {
            case type, value, symptom, message, predictionKey, alertMessage
        }

        init(from decoder: Decoder) throws {

            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(String.self, forKey: .type)
            symptom = try container.decodeIfPresent(String.self, forKey: .symptom)
            message = try container.decodeIfPresent(String.self, forKey: .message)
            predictionKey = try container.decodeIfPresent(String.self, forKey: .predictionKey)
            alertMessage = try container.decodeIfPresent(AlertMessage.self, forKey: .alertMessage)

            // ✅ HANDLE STRING / INT / DOUBLE SAFELY
            if let stringValue = try? container.decode(String.self, forKey: .value) {
                value = stringValue
            } else if let intValue = try? container.decode(Int.self, forKey: .value) {
                value = "\(intValue)"
            } else if let doubleValue = try? container.decode(Double.self, forKey: .value) {
                value = "\(doubleValue)"
            } else {
                value = ""
            }
        }
    }


    struct AlertMessage: Codable {
        let title: String?
        let message: String?
    }

    struct LocationData: Codable {
        let id: Int
        let user_id: Int
        let os: Int
        let version: String?
        let app_version: String?
        let firmware_version: String?
        let location: Int
        let bluetooth: Int
        let ring: Int
        let status: String?
        let battery: Int
        let latitude: String?
        let longitude: String?
        let created_at: String?
        let updated_at: String?
    }
}

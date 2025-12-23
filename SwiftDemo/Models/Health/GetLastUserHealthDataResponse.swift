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

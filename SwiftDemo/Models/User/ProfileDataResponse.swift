import Foundation

struct ProfileDataResponse: Codable {

    let response: Int
    let data: ProfileData

    struct ProfileData: Codable {

        let id: Int
        let user_id: Int

        let first_name: String?
        let last_name: String?
        let dob: String?
        let gender: String?

        let address: String?
        let city: String?
        let state: String?
        let country: String?
        let pincode: String?

        let phone_number: String
        let emergency_phone: String?
        let email: String?

        let blood_group: String?
        let allergy: Int

        let filepath: String?
        let status: Int

        let height: String?
        let weight: String?

        let existing_diseases: String?
        let existing_medications: String?

        let patient_name: String
        let patient_code: String
        let age: Int

        let patient_image_url: String?
    }
}

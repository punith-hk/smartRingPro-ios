import Foundation

// MARK: - Dependents List Response
struct DependentsResponse: Codable {
    let response: Int
    let data: [FamilyMember]
}

// MARK: - Family Member Model
struct FamilyMember: Codable {

    let id: Int
    let patient_id: Int

    let name: String
    let relation: String
    let gender: String

    let blood_group: String?
    let allergy: Int?

    let image: String?
    let dependent_image_url: String?

    let dob: String
    let age: Int

    let status: Int

    let emergency_phone: String?

    let existing_diseases: String?
    let existing_medications: String?
}

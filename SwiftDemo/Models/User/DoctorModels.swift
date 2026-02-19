import Foundation

// MARK: - Doctor Response (wraps DepartmentsData)
struct DoctorResponse: Codable {
    let response: Int
    let data: DepartmentsData
}

// MARK: - Departments Data
struct DepartmentsData: Codable {
    let department_id: Int
    let id: Int
    let description: String
    let doctors: [Doctor]
}

// MARK: - Doctor
struct Doctor: Codable {
    let id: Int
    let user_id: Int?
    let first_name: String?
    let last_name: String?
    let specialization_id: Int?
    let department_id: Int?
    let phone_number: String?
    let email: String?
    let gender: String?
    let dob: String?
    let about_me: String?
    let address_line_1: String?
    let address_line_2: String?
    let city: String?
    let state: String?
    let country: String?
    let pincode: String?
    let filepath: String?
    let filename: String?
    let status: Int?
    let education: String?
    let created_at: String?
    let updated_at: String?
    let deleted_at: String?
    let doctor_name: String?
    let doctor_department: String?
    let doctor_specialization: String?
    let doctor_image_url: String?
    let department: DoctorDepartment?
    let specialization: DoctorSpecialization?
    
    var displayName: String {
        if let name = doctor_name, !name.isEmpty {
            return name
        }
        let firstName = first_name ?? ""
        let lastName = last_name ?? ""
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var qualificationsText: String {
        education ?? ""
    }
    
    var profileImageURL: URL? {
        guard let imageURL = doctor_image_url else { return nil }
        return URL(string: imageURL)
    }
    
    var specializationText: String {
        if let spec = doctor_specialization, !spec.isEmpty {
            return spec
        }
        return doctor_department ?? ""
    }
}

// MARK: - Department (nested in Doctor response)
struct DoctorDepartment: Codable {
    let id: Int
    let description: String?
    let created_at: String?
    let updated_at: String?
    let deleted_at: String?
}

// MARK: - Specialization (nested in Doctor response)
struct DoctorSpecialization: Codable {
}



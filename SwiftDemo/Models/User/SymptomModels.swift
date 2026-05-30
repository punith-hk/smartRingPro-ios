import Foundation

// MARK: - Symptom API Response
struct SymptomResponse: Codable {
    let response: String
    let data: SymptomData
}

struct SymptomData: Codable {
    let male: [String: [Symptom]]
    let female: [String: [Symptom]]
}

struct Symptom: Codable {
    let id: Int
    let title: String
    let questionId: String
    let bodyPart: String
    let gender: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case questionId = "question_id"
        case bodyPart = "body_part"
        case gender
        case createdAt = "created_at"
    }
}

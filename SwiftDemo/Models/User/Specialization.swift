import Foundation

// MARK: - Specialization Model
struct Specialization {
    let id: Int
    let name: String
    let description: String
    let imageName: String
    
    init(id: Int, name: String, description: String, imageName: String = "") {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
    }
}

// MARK: - Mock Data (matches Android implementation)
extension Specialization {
    static let mockSpecialists: [Specialization] = [
        Specialization(id: 1, name: "General Physician", description: "Specialists in general physician", imageName: "gd"),
        Specialization(id: 3, name: "Cardiology", description: "Specialists in cardiology", imageName: "cardio"),
        Specialization(id: 4, name: "Pediatrician", description: "Specialists in pediatrician", imageName: "pedes"),
        Specialization(id: 5, name: "Dermatology", description: "Specialists in dermatology", imageName: "demi"),
        Specialization(id: 6, name: "Psychiatrist", description: "Specialists in psychiatrist", imageName: "psyhc"),
        Specialization(id: 7, name: "Others", description: "Specialists in others", imageName: "other")
    ]
}

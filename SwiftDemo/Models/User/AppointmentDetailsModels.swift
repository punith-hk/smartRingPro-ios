import Foundation

// MARK: - Appointment Details Response
struct AppointmentDetailsResponse: Codable {
    let id: Int
    let apptDate: String
    let apptTime: String
    let patientId: Int
    let doctorId: Int
    let purpose: String
    let dependentId: Int
    let slot: Int?
    let remarks: String?
    let diseaseName: String?
    let patientName: String
    let patientCode: String
    let patientType: String
    let patientImageUrl: String?
    let patientStatus: Int
    let doctorName: String
    let doctorDepartment: String
    let doctorSpecialization: String?
    let doctorImageUrl: String?
    let vittals: [Vittal]
    let diseases: [SymptomQuestion]
    let prescriptions: [Prescription]
    
    enum CodingKeys: String, CodingKey {
        case id
        case apptDate = "appt_date"
        case apptTime = "appt_time"
        case patientId = "patient_id"
        case doctorId = "doctor_id"
        case purpose
        case dependentId = "dependent_id"
        case slot
        case remarks
        case diseaseName = "disease_name"
        case patientName = "patient_name"
        case patientCode = "patient_code"
        case patientType = "patient_type"
        case patientImageUrl = "patient_image_url"
        case patientStatus = "patient_status"
        case doctorName = "doctor_name"
        case doctorDepartment = "doctor_department"
        case doctorSpecialization = "doctor_specialization"
        case doctorImageUrl = "doctor_image_url"
        case vittals
        case diseases
        case prescriptions
    }
}

// MARK: - Vittal
struct Vittal: Codable {
    let id: Int
    let appointmentId: Int
    let questionVittalId: Int
    let value: String
    let vittalQuestion: String
    let lowValue: String
    let highValue: String
    let normalValue: String
    let unit: String
    let questionvittal: QuestionVittal?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case questionVittalId = "question_vittal_id"
        case value
        case vittalQuestion = "vittal_question"
        case lowValue = "low_value"
        case highValue = "high_value"
        case normalValue = "normal_value"
        case unit
        case questionvittal
    }
    
    // Helper to format display
    var displayText: String {
        return "\(value) \(unit)"
    }
}

// MARK: - Question Vittal Detail
struct QuestionVittal: Codable {
    let id: Int
    let question: String
    let lowValue: String?
    let highValue: String?
    let normalValue: String?
    let unit: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case lowValue = "low_value"
        case highValue = "high_value"
        case normalValue = "normal_value"
        case unit
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Symptom Question
struct SymptomQuestion: Codable {
    let id: Int
    let appointmentId: Int
    let questionDiseaseId: Int?
    let question: String
    let answer: Int
    let diseaseQuestion: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case questionDiseaseId = "question_disease_id"
        case question
        case answer
        case diseaseQuestion = "disease_question"
    }
    
    // Helper to check if answered yes
    var isYes: Bool {
        return answer == 1
    }
}

// MARK: - Prescription
struct Prescription: Codable {
    let id: Int
    let appointmentId: Int
    let medicine: String
    let notes: String?
    let duration: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case medicine
        case notes
        case duration
    }
}

// MARK: - Helper Extensions
extension AppointmentDetailsResponse {
    // Get unique vitals by question (latest only)
    var uniqueVitals: [Vittal] {
        var uniqueDict: [Int: Vittal] = [:]
        for vittal in vittals {
            // Keep the latest entry for each question_vittal_id
            if let existing = uniqueDict[vittal.questionVittalId] {
                // Compare by id (higher id = more recent)
                if vittal.id > existing.id {
                    uniqueDict[vittal.questionVittalId] = vittal
                }
            } else {
                uniqueDict[vittal.questionVittalId] = vittal
            }
        }
        return Array(uniqueDict.values).sorted { $0.questionVittalId < $1.questionVittalId }
    }
    
    // Get unique symptom questions (remove duplicates)
    var uniqueSymptoms: [SymptomQuestion] {
        var seen = Set<String>()
        var unique: [SymptomQuestion] = []
        
        for question in diseases where question.isYes {
            if !seen.contains(question.diseaseQuestion) {
                seen.insert(question.diseaseQuestion)
                unique.append(question)
            }
        }
        return unique
    }
    
    // Format date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: apptDate) else { return apptDate }
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Format time
    var formattedTime: String {
        let components = apptTime.split(separator: ":")
        if components.count >= 2 {
            return "\(components[0]):\(components[1]):00"
        }
        return apptTime
    }
}

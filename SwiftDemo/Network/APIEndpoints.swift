import Foundation

enum APIEndpoints {

    // MARK: - Base
    static let baseURL = "https://webapi.mannaheal.com/api/"

    // MARK: - Auth
    static let login = "login"
    static let register = "register"
    static let verifyOtp = "verifyotp"

    // MARK: - Health
    static func lastHealthData(userId: Int) -> String {
        return "getLastRingData?user_id=\(userId)"
    }

    // MARK: - Doctors / Departments
    static let departments = "departments"
    static func doctors(id: Int) -> String {
        return "departments/\(id)"
    }
    static func schedules(id: Int) -> String {
        return "doctors/\(id)/schedules"
    }

    // MARK: - Profile
    static func patientProfile(id: Int) -> String {
        return "patients/\(id)"
    }

    // MARK: - Appointments
    static let getAppointments = "patients/myappointments"
    static let getDoctorAppointments = "doctors/myappointments"
    static let bookAppointment = "appointments"

    static func getPrescription(appointmentId: Int) -> String {
        return "appointments/\(appointmentId)/answers"
    }

    // MARK: - Family / Dependents
    static func getDependents(userId: Int) -> String {
        return "patients/\(userId)/dependents"
    }

    static func updateFamilyMember(
        userId: Int,
        dependentId: Int
    ) -> String {
        return "patients/\(userId)/dependents/\(dependentId)"
    }

    // MARK: - Symptoms
    static let getAllSymptoms = "getAllSymptoms"

    static func saveSymptoms(userId: Int) -> String {
        return "patients/\(userId)/symptoms"
    }

    // MARK: - Diseases
    static let getDiseaseList = "diseases/list"

    // MARK: - Firebase
    static let fcmToken = "user/fcm-token"
}

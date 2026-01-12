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
    
    // Linked accounts
        static func getLinkedAccounts(userId: Int) -> String {
            return "caretaker/\(userId)"
        }

        static let addLinkedAccount = "caretaker/request"
        static let verifyCaretakerOtp = "caretaker/verify"

        static let getLastRingData = "getLastRingData"

    // MARK: - Symptoms
    static let getAllSymptoms = "getAllSymptoms"

    static func saveSymptoms(userId: Int) -> String {
        return "patients/\(userId)/symptoms"
    }
    
    // MARK: - Ring Data (History)
    static func getRingDataByType(
        userId: Int,
        type: String,
        selectedDate: String
    ) -> String {
        return "getRingDataByType?user_id=\(userId)&type=\(type)&selectedDate=\(selectedDate)"
    }

    /// Get day-wise ring data for a user and type
    /// Example: getRingDataByDay?user_id=2&type=heart_rate
    static func getRingDataByDay(
        userId: Int,
        type: String
    ) -> String {
        return "getRingDataByDay?user_id=\(userId)&type=\(type)"
    }
    
    // MARK: - Create/Upload Ring Data
    static let createRingValues = "CreateRingValues"
    
    /// Upload single ring value
    static func createRingValue(
        userId: Int,
        type: String,
        value: String,
        timestamp: Int64
    ) -> String {
        return "CreateRingValue?user_id=\(userId)&type=\(type)&value=\(value)&timestamp=\(timestamp)"
    }

    // MARK: - Diseases
    static let getDiseaseList = "diseases/list"

    // MARK: - Firebase
    static let fcmToken = "user/fcm-token"
}

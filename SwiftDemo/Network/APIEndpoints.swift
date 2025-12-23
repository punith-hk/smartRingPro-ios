import Foundation

enum APIEndpoints {
    static let baseURL = "https://webapi.mannaheal.com/api/"

    static let login = "login"
    static let register = "register"
    static let verifyOtp = "verifyotp"
    
    static func lastHealthData(userId: Int) -> String {
            return "getLastRingData?user_id=\(userId)"
        }

    static let departments = "departments"
    static func doctors(id: Int) -> String { "departments/\(id)" }
    static func schedules(id: Int) -> String { "doctors/\(id)/schedules" }

    static func patientProfile(id: Int) -> String { "patients/\(id)" }

    static let myAppointments = "patients/myappointments"
    static let bookAppointment = "appointments"
}

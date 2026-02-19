import Foundation

final class AppointmentService {
    
    static let shared = AppointmentService()
    private init() {}
    
    /// Fetch doctor's weekly schedule
    /// - Parameters:
    ///   - doctorId: Doctor ID
    ///   - completion: Callback with result
    func getDoctorSchedules(
        doctorId: Int,
        completion: @escaping (Result<ScheduleResponse, NetworkError>) -> Void
    ) {
        print("[AppointmentService] 📅 Fetching schedules for doctor: \(doctorId)")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getDoctorSchedules(doctorId: doctorId),
            responseType: ScheduleResponse.self,
            completion: completion
        )
    }
    
    /// Fetch doctor's existing appointments
    /// - Parameters:
    ///   - doctorId: Doctor ID
    ///   - completion: Callback with result
    func getDoctorAppointments(
        doctorId: Int,
        completion: @escaping (Result<DoctorAppointmentsResponse, NetworkError>) -> Void
    ) {
        print("[AppointmentService] 📋 Fetching appointments for doctor: \(doctorId)")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getDoctorAppointments(doctorId: doctorId),
            responseType: DoctorAppointmentsResponse.self,
            completion: completion
        )
    }
    
    /// Fetch patient's appointments
    /// - Parameters:
    ///   - patientId: Patient ID
    ///   - completion: Callback with result
    func getMyAppointments(
        patientId: Int,
        completion: @escaping (Result<MyAppointmentsResponse, NetworkError>) -> Void
    ) {
        print("[AppointmentService] 📅 Fetching appointments for patient: \(patientId)")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getMyAppointments(patientId: patientId),
            responseType: MyAppointmentsResponse.self,
            completion: completion
        )
    }
    
    /// Book an appointment with a doctor
    /// - Parameters:
    ///   - appointmentDate: Date in "yyyy-MM-dd" format
    ///   - appointmentTime: Time in "HH:mm:ss" format
    ///   - doctorId: Doctor ID
    ///   - patientId: Patient ID
    ///   - purpose: Purpose of appointment (comma-separated symptoms)
    ///   - status: Appointment status (1=upcoming, 2=completed, 3=cancelled)
    ///   - dependentId: Dependent ID (0 for self)
    ///   - type: Appointment type
    ///   - completion: Callback with result
    func bookAppointment(
        appointmentDate: String,
        appointmentTime: String,
        doctorId: Int,
        patientId: Int,
        purpose: String,
        status: Int = 1,
        dependentId: Int = 0,
        type: Int = 2,
        completion: @escaping (Result<BookAppointmentResponse, NetworkError>) -> Void
    ) {
        print("[AppointmentService] 📝 Booking appointment - Date: \(appointmentDate), Time: \(appointmentTime)")
        
        let body: [String: Any] = [
            "appointment_date": appointmentDate,
            "appointment_time": appointmentTime,
            "doctor_id": doctorId,
            "patient_id": patientId,
            "purpose": purpose,
            "status": status,
            "dependent_id": dependentId,
            "type": type
        ]
        
        APIClient.shared.post(
            endpoint: APIEndpoints.bookAppointment,
            body: body,
            responseType: BookAppointmentResponse.self,
            completion: completion
        )
    }
    
    /// Submit symptoms for a patient
    /// - Parameters:
    ///   - patientId: Patient ID
    ///   - dependentId: Dependent ID (0 for self)
    ///   - apptTime: Appointment date and time in "yyyy-MM-dd HH:mm:ss" format
    ///   - symptomJson: JSON string of symptoms (e.g., {"Chest":["Pain"]})
    ///   - completion: Callback with result
    func submitSymptoms(
        patientId: Int,
        dependentId: Int = 0,
        apptTime: String,
        symptomJson: String,
        completion: @escaping (Result<SubmitSymptomsResponse, NetworkError>) -> Void
    ) {
        print("[AppointmentService] 💊 Submitting symptoms for patient: \(patientId)")
        
let body: [String: Any] = [
            "dependent_id": dependentId,
            "appt_time": apptTime,
            "symptom": symptomJson
        ]
        
        APIClient.shared.post(
            endpoint: APIEndpoints.saveSymptoms(userId: patientId),
            body: body,
            responseType: SubmitSymptomsResponse.self,
            completion: completion
        )
    }
    
    /// Fetch appointment details including vitals, symptoms, and prescriptions
    /// - Parameters:
    ///   - appointmentId: Appointment ID
    ///   - completion: Callback with result
    func getAppointmentDetails(
        appointmentId: Int,
        completion: @escaping (Result<[AppointmentDetailsResponse], NetworkError>) -> Void
    ) {
        print("[AppointmentService] 📋 Fetching details for appointment: \(appointmentId)")
        
        APIClient.shared.get(
            endpoint: APIEndpoints.getAppointmentDetails(appointmentId: appointmentId),
            responseType: [AppointmentDetailsResponse].self,
            completion: completion
        )
    }
}

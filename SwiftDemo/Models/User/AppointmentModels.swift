import Foundation

// MARK: - Doctor Schedules Response
struct ScheduleResponse: Codable {
    let response: Int
    let data: [DaySchedule]
    let leaves: [String]
}

struct DaySchedule: Codable {
    let doctorId: Int
    let day: String
    let timeSlots: [String]
    let doctorName: String
    
    enum CodingKeys: String, CodingKey {
        case doctorId = "doctor_id"
        case day
        case timeSlots = "time_slots"
        case doctorName = "doctor_name"
    }
}

// MARK: - Doctor Appointments Response
struct DoctorAppointmentsResponse: Codable {
    let response: Int
    let data: [DoctorAppointment]
}

struct DoctorAppointment: Codable {
    let apptId: Int
    let apptDate: String
    let apptTime: String
    let patientId: Int
    let purpose: String
    let appointmentStatus: Int
    
    enum CodingKeys: String, CodingKey {
        case apptId = "appt_id"
        case apptDate = "appt_date"
        case apptTime = "appt_time"
        case patientId = "patient_id"
        case purpose
        case appointmentStatus = "appointment_status"
    }
}

// MARK: - Date Schedule (for UI)
struct DateSchedule {
    let date: Date
    let dayShort: String      // "Thu"
    let dateFormatted: String // "19 Feb"
    let monthYear: String     // "Feb 2026"
    let dateString: String    // "2026-02-19" for API
    let availableSlots: [Int] // [1, 2, 3, 4, 5, 6...]
    let bookedSlots: [Int]    // [3, 5] - slots already booked
    var timeSlots: [TimeSlot] // Time slot buttons to display
}

// MARK: - Time Slot
struct TimeSlot {
    let slotId: Int
    let time: String           // "09:00 AM"
    let time24: String         // "09:00:00" for API
    var state: SlotState
}

enum SlotState {
    case available
    case booked
    case selected
}

// MARK: - Book Appointment Response
struct BookAppointmentResponse: Codable {
    let message: String
}

// MARK: - Submit Symptoms Response
struct SubmitSymptomsResponse: Codable {
    let response: String
    let message: String
    let data: SymptomSubmissionData?
}

struct SymptomSubmissionData: Codable {
    let symptom: String
}

// MARK: - My Appointments Response
struct MyAppointmentsResponse: Codable {
    let response: Int
    let data: [PatientAppointment]
}

struct PatientAppointment: Codable {
    let apptId: Int
    let apptDate: String
    let apptTime: String
    let doctorId: Int
    let patientId: Int
    let dependentId: Int
    let purpose: String
    let status: Int // 1=Confirmed, 2=Canceled, 3=Completed
    let doctorName: String
    let doctorDepartment: String
    let doctorImageUrl: String?
    let patientName: String
    let patientCode: String
    let patientType: String
    let patientImageUrl: String?
    let patientStatus: Int
    let patientPhone: String
    
    enum CodingKeys: String, CodingKey {
        case apptId = "appt_id"
        case apptDate = "appt_date"
        case apptTime = "appt_time"
        case doctorId = "doctor_id"
        case patientId = "patient_id"
        case dependentId = "dependent_id"
        case purpose
        case status
        case doctorName = "doctor_name"
        case doctorDepartment = "doctor_department"
        case doctorImageUrl = "doctor_image_url"
        case patientName = "patient_name"
        case patientCode = "patient_code"
        case patientType = "patient_type"
        case patientImageUrl = "patient_image_url"
        case patientStatus = "patient_status"
        case patientPhone = "patient_phone"
    }
    
    var statusText: String {
        switch status {
        case 1: return "Confirmed"
        case 2: return "Canceled"
        case 3: return "Completed"
        default: return "Unknown"
        }
    }
    
    var statusColor: UIColor {
        switch status {
        case 1: return UIColor.systemGreen
        case 2: return UIColor.systemRed
        case 3: return UIColor.systemBlue
        default: return UIColor.gray
        }
    }
    
    var isCompleted: Bool {
        return status == 3
    }
}

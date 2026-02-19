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

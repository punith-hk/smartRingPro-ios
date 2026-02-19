import Foundation

final class AppointmentHelper {
    
    /// Generate time slot mapping (9:00 AM = 1, 9:30 AM = 2, etc.)
    /// Slots from 09:00 to 21:00 in 30-minute intervals
    static func getTimeSlotMapping() -> [Int: (time12: String, time24: String)] {
        var mapping: [Int: (String, String)] = [:]
        var slotId = 1
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        
        guard let startTime = calendar.date(from: components) else { return [:] }
        
        let formatter12 = DateFormatter()
        formatter12.dateFormat = "hh:mm a"
        
        let formatter24 = DateFormatter()
        formatter24.dateFormat = "HH:mm:ss"
        
        var currentTime = startTime
        let endHour = 21 // 9:00 PM
        
        while calendar.component(.hour, from: currentTime) <= endHour {
            let time12 = formatter12.string(from: currentTime)
            let time24 = formatter24.string(from: currentTime)
            
            mapping[slotId] = (time12, time24)
            
            // Stop after 21:00
            if calendar.component(.hour, from: currentTime) == endHour && 
               calendar.component(.minute, from: currentTime) == 0 {
                break
            }
            
            currentTime = calendar.date(byAdding: .minute, value: 30, to: currentTime)!
            slotId += 1
        }
        
        return mapping
    }
    
    /// Generate next 15 days with schedules, filtering out leaves
    /// - Parameters:
    ///   - weeklySchedules: Doctor's weekly availability
    ///   - leaves: Doctor's leave dates in "dd-MM-yyyy" format
    ///   - appointments: Booked appointments
    /// - Returns: Array of DateSchedule for next 15 days
    static func generateNext15Days(
        weeklySchedules: [DaySchedule],
        leaves: [String],
        appointments: [DoctorAppointment]
    ) -> [DateSchedule] {
        
        let calendar = Calendar.current
        let today = Date()
        var dateSchedules: [DateSchedule] = []
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"  // "Thu"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM"  // "19 Feb"
        
        let monthYearFormatter = DateFormatter()
        monthYearFormatter.dateFormat = "MMM yyyy"  // "Feb 2026"
        
        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"  // "2026-02-19"
        
        let leaveDateFormatter = DateFormatter()
        leaveDateFormatter.dateFormat = "dd-MM-yyyy"  // "25-10-2023"
        
        let fullDayFormatter = DateFormatter()
        fullDayFormatter.dateFormat = "EEEE"  // "Thursday"
        
        for dayOffset in 0..<15 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let dayShort = dayFormatter.string(from: date)
            let dateFormatted = dateFormatter.string(from: date)
            let monthYear = monthYearFormatter.string(from: date)
            let dateString = apiDateFormatter.string(from: date)
            let leaveDate = leaveDateFormatter.string(from: date)
            let fullDayName = fullDayFormatter.string(from: date)
            
            // Check if date is in leaves
            if leaves.contains(leaveDate) {
                let schedule = DateSchedule(
                    date: date,
                    dayShort: dayShort,
                    dateFormatted: dateFormatted,
                    monthYear: monthYear,
                    dateString: dateString,
                    availableSlots: [],
                    bookedSlots: [],
                    timeSlots: []
                )
                dateSchedules.append(schedule)
                continue
            }
            
            // Find schedule for this day of week
            if let daySchedule = weeklySchedules.first(where: { $0.day == fullDayName }) {
                let availableSlots = daySchedule.timeSlots.compactMap { Int($0) }
                let bookedSlots = getBookedSlotsForDate(dateString: dateString, appointments: appointments)
                let timeSlots = generateTimeSlots(availableSlots: availableSlots, bookedSlots: bookedSlots)
                
                let schedule = DateSchedule(
                    date: date,
                    dayShort: dayShort,
                    dateFormatted: dateFormatted,
                    monthYear: monthYear,
                    dateString: dateString,
                    availableSlots: availableSlots,
                    bookedSlots: bookedSlots,
                    timeSlots: timeSlots
                )
                dateSchedules.append(schedule)
            } else {
                // No schedule for this day
                let schedule = DateSchedule(
                    date: date,
                    dayShort: dayShort,
                    dateFormatted: dateFormatted,
                    monthYear: monthYear,
                    dateString: dateString,
                    availableSlots: [],
                    bookedSlots: [],
                    timeSlots: []
                )
                dateSchedules.append(schedule)
            }
        }
        
        return dateSchedules
    }
    
    /// Get booked slot IDs for a specific date
    private static func getBookedSlotsForDate(
        dateString: String,
        appointments: [DoctorAppointment]
    ) -> [Int] {
        let timeMapping = getTimeSlotMapping()
        var bookedSlots: [Int] = []
        
        // Filter appointments for this date with status 1 (upcoming)
        let dateAppointments = appointments.filter {
            $0.apptDate == dateString && $0.appointmentStatus == 1
        }
        
        for appointment in dateAppointments {
            // Find slot ID for this time
            for (slotId, times) in timeMapping {
                if times.time24 == appointment.apptTime {
                    bookedSlots.append(slotId)
                    break
                }
            }
        }
        
        return bookedSlots
    }
    
    /// Generate TimeSlot objects from available and booked slot IDs
    private static func generateTimeSlots(availableSlots: [Int], bookedSlots: [Int]) -> [TimeSlot] {
        let timeMapping = getTimeSlotMapping()
        var timeSlots: [TimeSlot] = []
        
        for slotId in availableSlots {
            guard let times = timeMapping[slotId] else { continue }
            
            let state: SlotState = bookedSlots.contains(slotId) ? .booked : .available
            let slot = TimeSlot(
                slotId: slotId,
                time: times.time12,
                time24: times.time24,
                state: state
            )
            timeSlots.append(slot)
        }
        
        return timeSlots
    }
}

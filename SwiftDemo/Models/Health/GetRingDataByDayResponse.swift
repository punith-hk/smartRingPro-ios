import Foundation

struct GetRingDataByDayResponse: Codable {
    let message: String
    let data: [DayData]

    struct DayData: Codable {
        let vDate: String
        let value: String
        let diastolicValue: String
    }
}

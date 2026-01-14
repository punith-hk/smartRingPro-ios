import UIKit

// MARK: - Vital Type
enum VitalType {
    case heartRate
    case bloodGlucose
    case temperature
    case bloodOxygen
    case hrv
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .bloodGlucose: return "Blood Glucose"
        case .temperature: return "Temperature"
        case .bloodOxygen: return "Blood Oxygen"
        case .hrv: return "HRV"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate: return "times/min"
        case .bloodGlucose: return "mg/dL"
        case .temperature: return "°C"
        case .bloodOxygen: return "%"
        case .hrv: return "ms"
        }
    }
    
    var color: UIColor {
        switch self {
        case .heartRate: return .systemRed
        case .bloodGlucose: return .systemPurple
        case .temperature: return .systemOrange
        case .bloodOxygen: return .systemBlue
        case .hrv: return .systemGreen
        }
    }
    
    var yAxisPadding: Double {
        switch self {
        case .heartRate: return 30
        case .bloodGlucose: return 20
        case .temperature: return 2
        case .bloodOxygen: return 10
        case .hrv: return 10
        }
    }
}

// MARK: - Chart Range
enum VitalChartRange {
    case day
    case week
    case month
    
    var segmentIndex: Int {
        switch self {
        case .day: return 0
        case .week: return 1
        case .month: return 2
        }
    }
}

// MARK: - Chart Data Point
struct VitalDataPoint {
    let timestamp: Int64
    let value: Double
}

// MARK: - Data Source Protocol
protocol VitalChartDataSource: AnyObject {
    func fetchChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void)
}

// MARK: - Delegate Protocol
protocol VitalChartDelegate: AnyObject {
    /// Called when chart needs to update value labels
    func chartShouldUpdateLabels(time: String, value: String)
}

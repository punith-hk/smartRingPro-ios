import UIKit

// MARK: - Vital Type
enum VitalType {
    case heartRate
    case bloodPressure
    case bloodGlucose
    case temperature
    case bloodOxygen
    case hrv
    case calories
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .bloodPressure: return "Blood Pressure"
        case .bloodGlucose: return "Blood Glucose"
        case .temperature: return "Temperature"
        case .bloodOxygen: return "Blood Oxygen"
        case .hrv: return "HRV"
        case .calories: return "Calories"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate: return "times/min"
        case .bloodPressure: return "mmHg"
        case .bloodGlucose: return "mg/dL"
        case .temperature: return "°C"
        case .bloodOxygen: return "%"
        case .hrv: return "ms"
        case .calories: return "kcal"
        }
    }
    
    var color: UIColor {
        switch self {
        case .heartRate: return .systemRed
        case .bloodPressure: return .systemIndigo
        case .bloodGlucose: return .systemPurple
        case .temperature: return .systemOrange
        case .bloodOxygen: return .systemBlue
        case .hrv: return .systemGreen
        case .calories: return .systemYellow
        }
    }
    
    var yAxisPadding: Double {
        switch self {
        case .heartRate: return 20
        case .bloodPressure: return 20
        case .bloodGlucose: return 20
        case .temperature: return 20
        case .bloodOxygen: return 30
        case .hrv: return 20
        case .calories: return 5
        }
    }
    
    var useBarChart: Bool {
        switch self {
        case .calories:
            return true
        default:
            return false
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
    
    /// Optional: For BP, fetch secondary data (diastolic) to show dual lines
    func fetchSecondaryChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void)
}

// Default implementation for optional method
extension VitalChartDataSource {
    func fetchSecondaryChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        completion([])
    }
}

// MARK: - Delegate Protocol
protocol VitalChartDelegate: AnyObject {
    /// Called when chart needs to update value labels
    func chartShouldUpdateLabels(time: String, value: String)
    
    /// Called to get custom formatted value for display (optional, for BP dual values)
    func chartCustomValueFormat(for timestamp: Int64) -> String?
}

// Default implementation for optional method
extension VitalChartDelegate {
    func chartCustomValueFormat(for timestamp: Int64) -> String? {
        return nil
    }
}

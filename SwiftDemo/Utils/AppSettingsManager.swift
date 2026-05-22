import Foundation

final class AppSettingsManager {

    static let shared = AppSettingsManager()
    private init() {}

    private let tempUnitKey = "temperatureUnit"
    private let intervalKey = "healthInterval"

    enum TemperatureUnit: String {
        case celsius = "Celsius (°C)"
        case fahrenheit = "Fahrenheit (°F)"
    }

    enum HealthInterval: String {
        case min15 = "15 min"
        case min30 = "30 min"
        case min45 = "45 min"
        case min60 = "60 min"
    }

    // MARK: - Temperature
    func setTemperatureUnit(_ unit: TemperatureUnit) {
        UserDefaults.standard.set(unit.rawValue, forKey: tempUnitKey)
    }

    func getTemperatureUnit() -> TemperatureUnit {
        let value = UserDefaults.standard.string(forKey: tempUnitKey)
        return TemperatureUnit(rawValue: value ?? "") ?? .celsius
    }

    // MARK: - Interval
    func setHealthInterval(_ interval: HealthInterval) {
        UserDefaults.standard.set(interval.rawValue, forKey: intervalKey)
    }

    func getHealthInterval() -> HealthInterval {
        let value = UserDefaults.standard.string(forKey: intervalKey)
        return HealthInterval(rawValue: value ?? "") ?? .min15
    }

    // MARK: - Steps Target
    private let stepsKey = "stepsTarget"

    func setStepsTarget(_ steps: Int) {
        UserDefaults.standard.set(steps, forKey: stepsKey)
    }

    func getStepsTarget() -> Int {
        let value = UserDefaults.standard.integer(forKey: stepsKey)
        return value == 0 ? 10_000 : value
    }

    // MARK: - Sleep Target
    private let sleepKey = "sleepTargetMinutes"

    func setSleepTargetMinutes(_ minutes: Int) {
        UserDefaults.standard.set(minutes, forKey: sleepKey)
    }

    func getSleepTargetMinutes() -> Int {
        let value = UserDefaults.standard.integer(forKey: sleepKey)
        return value == 0 ? 480 : value
    }
}

enum TemperatureUnit {
    case celsius
    case fahrenheit
}

struct TemperatureConverter {

    static func celsiusToFahrenheit(_ c: Double) -> Double {
        return (c * 9 / 5) + 32
    }

    static func fahrenheitToCelsius(_ f: Double) -> Double {
        return (f - 32) * 5 / 9
    }
}


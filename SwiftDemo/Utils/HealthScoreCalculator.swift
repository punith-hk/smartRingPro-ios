import UIKit

// MARK: - Result

struct HealthScoreResult {
    let score: Int           // 0–100
    let statusLabel: String  // "Excellent" / "Good" / "Fair" / "Poor"
    let statusColor: UIColor
    let yesterdayScore: Int  // from UserDefaults, 0 if no previous day
}

// MARK: - Calculator

enum HealthScoreCalculator {

    // MARK: - ECG Score (0–20) from ring body-index data

    /// Computes the ECG ring score stored on an ECGRecord.
    /// Formula from §6 of DASHBOARD_SCREEN_DESIGN_AND_LOGIC.md.
    static func ecgScore(from record: ECGRecord) -> Int {
        // Use stored tores if already calculated (non-zero means it was set at measurement time)
        if record.tores > 0 { return record.tores }

        if record.isAfib { return 3 }
        if record.diagnoseType == 5 || record.diagnoseType == 9 { return 5 }

        let candidates: [Double?] = [record.loadIndex, record.hrvIndex, record.pressureIndex, record.bodyIndex, record.symParaIndex]
        let nonZero = candidates.compactMap { $0 }.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return 0 }
        let avg = nonZero.reduce(0, +) / Double(nonZero.count)
        return min(20, max(0, Int(avg * 2.0)))
    }

    // MARK: - ECG Status Text

    /// Derives a human-readable ECG condition label from ring data.
    static func ecgStatusText(isAfib: Bool, diagnoseType: Int,
                              heartRate: Int, hrv: Int) -> String {
        if isAfib || diagnoseType == 1 { return "Atrial Fibrillation" }
        if diagnoseType == 2            { return "Ventricular Premature" }
        if diagnoseType == 3            { return "Atrial Premature" }
        if diagnoseType == 4 || heartRate <= 50  { return "Bradycardia" }
        if diagnoseType == 5 || heartRate >= 120 { return "Tachycardia" }
        if diagnoseType == 6 || hrv >= 125       { return "Sinus Arrhythmia" }
        return "Normal ECG"
    }

    // MARK: - Health Score (0–100)

    /// Calculates the composite health score.
    ///
    /// - Parameters:
    ///   - heartRate: BPM (0 = no data)
    ///   - hrv:       ms  (0 = no data)
    ///   - systolic:  mmHg (0 = no data)
    ///   - diastolic: mmHg (0 = no data)
    ///   - spo2:      % (0 = no data)
    ///   - ecgScore:  ring ECG score 0–20 (0 = no data)
    ///   - calories:  kcal (0 = no data)
    static func calculate(heartRate: Int,
                          hrv: Int,
                          systolic: Int,
                          diastolic: Int,
                          spo2: Int,
                          ecgScore: Int,
                          calories: Int) -> HealthScoreResult {
        var total = 0

        // Heart Rate — max 20 pts
        if heartRate > 0 {
            if heartRate >= 60 && heartRate <= 100 { total += 20 }
            else if heartRate >= 50 && heartRate <= 110 { total += 15 }
            else if heartRate >= 40 && heartRate <= 120 { total += 10 }
            else { total += 5 }
        }

        // HRV — max 20 pts
        if hrv > 0 {
            if hrv >= 50 { total += 20 }
            else if hrv >= 30 { total += 15 }
            else if hrv >= 20 { total += 10 }
            else { total += 5 }
        }

        // Blood Pressure — max 15 pts
        if systolic > 0 && diastolic > 0 {
            let systolicNormal  = systolic  >= 90  && systolic  <= 120
            let diastolicNormal = diastolic >= 60  && diastolic <= 80
            let elevated        = (systolic >= 121 && systolic  <= 139) ||
                                  (diastolic >= 81 && diastolic <= 89)
            if systolicNormal && diastolicNormal { total += 15 }
            else if elevated                      { total += 10 }
            else                                  { total += 5  }
        }

        // SpO2 — max 15 pts
        if spo2 > 0 {
            if spo2 >= 95 { total += 15 }
            else if spo2 >= 90 { total += 10 }
            else { total += 5 }
        }

        // ECG Score — max 15 pts
        if ecgScore > 0 {
            if ecgScore >= 15 { total += 15 }
            else if ecgScore >= 10 { total += 10 }
            else { total += 5 }
        }

        // Calories / Activity — max 15 pts
        if calories > 0 {
            if calories >= 2000 { total += 15 }
            else if calories >= 1500 { total += 10 }
            else { total += 5 }
        }

        let score = min(100, max(0, total))
        let (label, color) = statusInfo(for: score)
        let yesterday = persistAndReturnYesterdayScore(todayScore: score)

        return HealthScoreResult(score: score,
                                 statusLabel: label,
                                 statusColor: color,
                                 yesterdayScore: yesterday)
    }

    // MARK: - Status Badge

    static func statusInfo(for score: Int) -> (String, UIColor) {
        switch score {
        case 85...: return ("Excellent", UIColor(red: 0/255,   green: 88/255,  blue: 9/255,   alpha: 1))
        case 70...: return ("Good",      UIColor(red: 255/255, green: 143/255, blue: 0/255,   alpha: 1))
        case 50...: return ("Fair",      UIColor(red: 245/255, green: 124/255, blue: 0/255,   alpha: 1))
        default:    return ("Poor",      UIColor(red: 198/255, green: 40/255,  blue: 40/255,  alpha: 1))
        }
    }

    // MARK: - Yesterday Comparison (UserDefaults)

    /// Persists today's score and returns yesterday's score for the comparison arrow.
    /// Keys: hs_last_saved_date, hs_today_score, hs_yesterday_score.
    private static func persistAndReturnYesterdayScore(todayScore: Int) -> Int {
        let defaults = UserDefaults.standard
        let todayStr = todayDateString()

        if defaults.string(forKey: "hs_last_saved_date") != todayStr {
            // New calendar day — archive previous today as yesterday
            let previousToday = defaults.integer(forKey: "hs_today_score")
            if previousToday > 0 {
                defaults.set(previousToday, forKey: "hs_yesterday_score")
            }
            defaults.set(todayStr, forKey: "hs_last_saved_date")
        }
        defaults.set(todayScore, forKey: "hs_today_score")
        return defaults.integer(forKey: "hs_yesterday_score")
    }

    private static func todayDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}

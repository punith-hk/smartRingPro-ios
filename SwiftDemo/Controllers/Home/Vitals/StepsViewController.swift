import UIKit
import YCProductSDK

/// Steps ViewController — bar chart of daily steps + distance tracking.
/// Data: BLE ring (YCHealthDataStep) → StepsRepository → bar chart
final class StepsViewController: AppBaseViewController {

    // MARK: - Constants
    private let stepGoal = 10_000
    private let greenColor = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1) // #4CAF50

    // MARK: - Properties
    private let userId = UserDefaultsManager.shared.userId

    // MARK: - Chart
    private lazy var chartView: VitalChartView = {
        let chart = VitalChartView(vitalType: .steps)
        chart.dataSource = self
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()

    // MARK: - State
    private var dayDataCompletion: (([VitalDataPoint]) -> Void)?
    private var currentRange: VitalChartRange = .day
    private var currentDate: Date = Date()
    private var apiDataFetched = false

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Range Summary Card (Week / Month only)
    private let rangeCard             = UIView()
    private let rangeTitleLabel       = UILabel()
    private let rangeStepsValueLabel  = UILabel()  // 24pt bold
    private let rangeStepsUnitLabel   = UILabel()  // 18pt, baseline-aligned
    private let rangeDivider          = UIView()
    private let rangeDistLabel        = UILabel()  // "Distance Covered"
    private let rangeDistValueLabel   = UILabel()  // 22pt bold
    private let rangeDistUnitLabel    = UILabel()  // "KM", 14pt gray
    private let rangeIconBg           = UIView()   // 50×50 green circle
    private let rangeIcon             = UIImageView()

    // MARK: - Today's Steps Card (always visible)
    private let stepsCard             = UIView()
    private let stepsConsumptionLabel = UILabel()  // "Today's Steps" / "2nd Jan Steps"
    private let stepsValueLabel       = UILabel()  // 28pt bold
    private let stepsTargetLabel      = UILabel()  // "/ 10000 target", 14pt gray
    private let stepsIconLabel        = UILabel()  // 🏃 emoji
    private let progressTrack         = UIView()   // gray background bar
    private let progressFill          = UIView()   // green fill bar
    private var progressFillWidth: NSLayoutConstraint?
    private let stepsDivider          = UIView()
    private let distanceLabel         = UILabel()  // "Distance Covered"
    private let distanceValueLabel    = UILabel()  // 22pt bold
    private let distanceUnitLabel     = UILabel()  // "KM", 14pt gray

    // MARK: - Layout Constraints
    private var rangeCardHeightZero: NSLayoutConstraint?  // active in day mode → collapses card
    private var stepsCardTopToChart: NSLayoutConstraint?  // active in day mode
    private var stepsCardTopToRange: NSLayoutConstraint?  // active in week/month mode

    // MARK: - Sync Helpers
    private var stepsSyncHelper: StepsSyncHelper?
    private var stepsDailySyncHelper: StepsDailySyncHelper?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Steps")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        setupUI()
        setupSyncHelpers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startBLESync()
        chartView.reloadData()
    }

    // MARK: - Setup
    private func setupSyncHelpers() {
        stepsSyncHelper = StepsSyncHelper(listener: self)
        stepsDailySyncHelper = StepsDailySyncHelper(listener: self)
    }

    private func startBLESync() {
        guard BLEStateManager.shared.hasConnectedDevice() else { return }
        stepsSyncHelper?.startSync()
    }

    // MARK: - UI Setup
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        contentView.addSubview(chartView)
        setupRangeCard()
        setupStepsCard()

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            rangeCard.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 12),
            rangeCard.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            rangeCard.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),

            stepsCard.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            stepsCard.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            stepsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        // Dynamic constraints: collapse rangeCard in day mode
        rangeCardHeightZero = rangeCard.heightAnchor.constraint(equalToConstant: 0)
        rangeCardHeightZero?.isActive = true  // start collapsed (day is default)

        stepsCardTopToChart = stepsCard.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 12)
        stepsCardTopToRange = stepsCard.topAnchor.constraint(equalTo: rangeCard.bottomAnchor, constant: 12)

        stepsCardTopToChart?.isActive = true   // day mode default
        stepsCardTopToRange?.isActive = false
    }

    // MARK: - Range Summary Card

    private func setupRangeCard() {
        rangeCard.backgroundColor = .white
        rangeCard.layer.cornerRadius = 24
        rangeCard.layer.shadowColor = UIColor.black.cgColor
        rangeCard.layer.shadowOpacity = 0.08
        rangeCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        rangeCard.layer.shadowRadius = 6
        rangeCard.clipsToBounds = true
        rangeCard.isHidden = true
        rangeCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rangeCard)

        // Title (e.g., "03-09 Mar\nSteps")
        rangeTitleLabel.font = .systemFont(ofSize: 15)
        rangeTitleLabel.textColor = .black
        rangeTitleLabel.numberOfLines = 2
        rangeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeTitleLabel)

        // Steps value (24pt bold)
        rangeStepsValueLabel.font = .boldSystemFont(ofSize: 24)
        rangeStepsValueLabel.textColor = .black
        rangeStepsValueLabel.text = "0"
        rangeStepsValueLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeStepsValueLabel)

        // "steps" unit (18pt)
        rangeStepsUnitLabel.font = .systemFont(ofSize: 18)
        rangeStepsUnitLabel.textColor = .black
        rangeStepsUnitLabel.text = "steps"
        rangeStepsUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeStepsUnitLabel)

        // Divider
        rangeDivider.backgroundColor = UIColor(white: 0.88, alpha: 1)
        rangeDivider.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeDivider)

        // "Distance Covered" label
        rangeDistLabel.text = "Distance Covered"
        rangeDistLabel.font = .systemFont(ofSize: 13)
        rangeDistLabel.textColor = UIColor(white: 0.53, alpha: 1)
        rangeDistLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeDistLabel)

        // Distance value (22pt bold)
        rangeDistValueLabel.font = .boldSystemFont(ofSize: 22)
        rangeDistValueLabel.textColor = .black
        rangeDistValueLabel.text = "0.00"
        rangeDistValueLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeDistValueLabel)

        // "KM" unit (14pt gray)
        rangeDistUnitLabel.text = "KM"
        rangeDistUnitLabel.font = .systemFont(ofSize: 14)
        rangeDistUnitLabel.textColor = UIColor(white: 0.53, alpha: 1)
        rangeDistUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeDistUnitLabel)

        // Icon: 50×50 green circle with walking figure
        rangeIconBg.backgroundColor = greenColor
        rangeIconBg.layer.cornerRadius = 25
        rangeIconBg.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeIconBg)

        rangeIcon.image = UIImage(systemName: "figure.walk")
        rangeIcon.tintColor = .white
        rangeIcon.contentMode = .scaleAspectFit
        rangeIcon.translatesAutoresizingMaskIntoConstraints = false
        rangeIconBg.addSubview(rangeIcon)

        NSLayoutConstraint.activate([
            rangeTitleLabel.topAnchor.constraint(equalTo: rangeCard.topAnchor, constant: 16),
            rangeTitleLabel.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),
            rangeTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rangeIconBg.leadingAnchor, constant: -12),

            rangeStepsValueLabel.topAnchor.constraint(equalTo: rangeTitleLabel.bottomAnchor, constant: 8),
            rangeStepsValueLabel.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),

            rangeStepsUnitLabel.firstBaselineAnchor.constraint(equalTo: rangeStepsValueLabel.firstBaselineAnchor),
            rangeStepsUnitLabel.leadingAnchor.constraint(equalTo: rangeStepsValueLabel.trailingAnchor, constant: 4),

            rangeIconBg.trailingAnchor.constraint(equalTo: rangeCard.trailingAnchor, constant: -20),
            rangeIconBg.topAnchor.constraint(equalTo: rangeCard.topAnchor, constant: 16),
            rangeIconBg.widthAnchor.constraint(equalToConstant: 50),
            rangeIconBg.heightAnchor.constraint(equalToConstant: 50),

            rangeIcon.centerXAnchor.constraint(equalTo: rangeIconBg.centerXAnchor),
            rangeIcon.centerYAnchor.constraint(equalTo: rangeIconBg.centerYAnchor),
            rangeIcon.widthAnchor.constraint(equalToConstant: 26),
            rangeIcon.heightAnchor.constraint(equalToConstant: 26),

            rangeDivider.topAnchor.constraint(equalTo: rangeStepsValueLabel.bottomAnchor, constant: 10),
            rangeDivider.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),
            rangeDivider.trailingAnchor.constraint(equalTo: rangeCard.trailingAnchor, constant: -24),
            rangeDivider.heightAnchor.constraint(equalToConstant: 1),

            rangeDistLabel.topAnchor.constraint(equalTo: rangeDivider.bottomAnchor, constant: 8),
            rangeDistLabel.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),

            rangeDistValueLabel.topAnchor.constraint(equalTo: rangeDistLabel.bottomAnchor, constant: 4),
            rangeDistValueLabel.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),
        ])
        let rangeBottom = rangeDistValueLabel.bottomAnchor.constraint(equalTo: rangeCard.bottomAnchor, constant: -16)
        rangeBottom.priority = .defaultHigh
        rangeBottom.isActive = true
        NSLayoutConstraint.activate([
            rangeDistUnitLabel.firstBaselineAnchor.constraint(equalTo: rangeDistValueLabel.firstBaselineAnchor),
            rangeDistUnitLabel.leadingAnchor.constraint(equalTo: rangeDistValueLabel.trailingAnchor, constant: 4),
        ])
    }

    // MARK: - Today's Steps Card

    private func setupStepsCard() {
        stepsCard.backgroundColor = .white
        stepsCard.layer.cornerRadius = 24
        stepsCard.layer.shadowColor = UIColor.black.cgColor
        stepsCard.layer.shadowOpacity = 0.08
        stepsCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        stepsCard.layer.shadowRadius = 6
        stepsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepsCard)

        // Title label
        stepsConsumptionLabel.text = "Today's Steps"
        stepsConsumptionLabel.font = .systemFont(ofSize: 18)
        stepsConsumptionLabel.textColor = .black
        stepsConsumptionLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsConsumptionLabel)

        // Steps value (28pt bold)
        stepsValueLabel.text = "0"
        stepsValueLabel.font = .boldSystemFont(ofSize: 28)
        stepsValueLabel.textColor = .black
        stepsValueLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsValueLabel)

        // "/ 10000 target" (14pt gray, baseline-aligned)
        stepsTargetLabel.text = "/ \(stepGoal) target"
        stepsTargetLabel.font = .systemFont(ofSize: 14)
        stepsTargetLabel.textColor = UIColor(white: 0.53, alpha: 1)
        stepsTargetLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsTargetLabel)

        // 🏃 emoji icon (44pt, right-aligned)
        stepsIconLabel.text = "🏃"
        stepsIconLabel.font = .systemFont(ofSize: 44)
        stepsIconLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsIconLabel)

        // Progress bar track (gray background)
        progressTrack.backgroundColor = UIColor(white: 0.88, alpha: 1)
        progressTrack.layer.cornerRadius = 5
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(progressTrack)

        // Progress bar fill (green)
        progressFill.backgroundColor = greenColor
        progressFill.layer.cornerRadius = 5
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        // Divider
        stepsDivider.backgroundColor = UIColor(white: 0.88, alpha: 1)
        stepsDivider.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsDivider)

        // "Distance Covered" label
        distanceLabel.text = "Distance Covered"
        distanceLabel.font = .systemFont(ofSize: 13)
        distanceLabel.textColor = UIColor(white: 0.53, alpha: 1)
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(distanceLabel)

        // Distance value (22pt bold)
        distanceValueLabel.text = "0.00"
        distanceValueLabel.font = .boldSystemFont(ofSize: 22)
        distanceValueLabel.textColor = .black
        distanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(distanceValueLabel)

        // "KM" unit (14pt gray)
        distanceUnitLabel.text = "KM"
        distanceUnitLabel.font = .systemFont(ofSize: 14)
        distanceUnitLabel.textColor = UIColor(white: 0.53, alpha: 1)
        distanceUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(distanceUnitLabel)

        // Progress fill width constraint (0 initially, updated dynamically)
        let fillWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)
        progressFillWidth = fillWidth

        NSLayoutConstraint.activate([
            stepsConsumptionLabel.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 16),
            stepsConsumptionLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 24),

            stepsValueLabel.topAnchor.constraint(equalTo: stepsConsumptionLabel.bottomAnchor, constant: 8),
            stepsValueLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 24),

            stepsTargetLabel.firstBaselineAnchor.constraint(equalTo: stepsValueLabel.firstBaselineAnchor),
            stepsTargetLabel.leadingAnchor.constraint(equalTo: stepsValueLabel.trailingAnchor, constant: 6),

            stepsIconLabel.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -20),
            stepsIconLabel.centerYAnchor.constraint(equalTo: stepsValueLabel.centerYAnchor),

            progressTrack.topAnchor.constraint(equalTo: stepsValueLabel.bottomAnchor, constant: 12),
            progressTrack.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 24),
            progressTrack.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -24),
            progressTrack.heightAnchor.constraint(equalToConstant: 10),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            fillWidth,

            stepsDivider.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 12),
            stepsDivider.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 24),
            stepsDivider.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -24),
            stepsDivider.heightAnchor.constraint(equalToConstant: 1),

            distanceLabel.topAnchor.constraint(equalTo: stepsDivider.bottomAnchor, constant: 10),
            distanceLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 24),

            distanceValueLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 4),
            distanceValueLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 24),
            distanceValueLabel.bottomAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: -16),

            distanceUnitLabel.firstBaselineAnchor.constraint(equalTo: distanceValueLabel.firstBaselineAnchor),
            distanceUnitLabel.leadingAnchor.constraint(equalTo: distanceValueLabel.trailingAnchor, constant: 4),
        ])
    }

    // MARK: - Stats Update

    private func updateStepsCard(steps: Int, distanceMeters: Int, date: Date) {
        stepsValueLabel.text = "\(steps)"
        stepsConsumptionLabel.attributedText = stepsCardTitle(for: date)

        let km = Double(distanceMeters) / 1000.0
        distanceValueLabel.text = String(format: "%.2f", km)

        let progress = min(CGFloat(steps) / CGFloat(stepGoal), 1.0)
        progressTrack.layoutIfNeeded()
        let trackWidth = progressTrack.bounds.width
        let fillPx = trackWidth > 0 ? trackWidth * progress : 0

        progressFillWidth?.constant = fillPx
        UIView.animate(withDuration: 0.3) { self.progressTrack.layoutIfNeeded() }
    }

    private func updateRangeCard(steps: Int, distanceMeters: Int, range: VitalChartRange, date: Date) {
        let isDay = (range == .day)
        rangeCard.isHidden = isDay
        rangeCardHeightZero?.isActive = isDay
        stepsCardTopToChart?.isActive = isDay
        stepsCardTopToRange?.isActive = !isDay
        guard !isDay else { return }

        rangeStepsValueLabel.text = "\(steps)"
        let km = Double(distanceMeters) / 1000.0
        rangeDistValueLabel.text = String(format: "%.2f", km)

        let df = DateFormatter()
        let cal = Calendar.current
        switch range {
        case .week:
            let weekday = cal.component(.weekday, from: date)
            let daysToMon = (weekday == 1) ? -6 : -(weekday - 2)
            let mon = cal.date(byAdding: .day, value: daysToMon, to: date)!
            let sun = cal.date(byAdding: .day, value: 6, to: mon)!
            df.dateFormat = "dd MMM"
            rangeTitleLabel.text = "\(df.string(from: mon)) – \(df.string(from: sun))\nSteps"
        case .month:
            df.dateFormat = "MMM yyyy"
            rangeTitleLabel.text = "\(df.string(from: date)) Steps"
        case .day:
            break
        }
    }

    /// Returns attributed title: "Today's Steps" or "2nd Jan Steps" with superscript suffix
    private func stepsCardTitle(for date: Date) -> NSAttributedString {
        if Calendar.current.isDateInToday(date) {
            return NSAttributedString(string: "Today's Steps",
                                      attributes: [.font: UIFont.systemFont(ofSize: 18)])
        }
        let cal = Calendar.current
        let day = cal.component(.day, from: date)
        let suffix = ordinalSuffix(day)
        let df = DateFormatter()
        df.dateFormat = "MMM"
        let str = "\(day)\(suffix) \(df.string(from: date)) Steps"
        let full = NSMutableAttributedString(string: str,
                                             attributes: [.font: UIFont.systemFont(ofSize: 18)])
        let nsStr = str as NSString
        let suffixRange = nsStr.range(of: suffix)
        if suffixRange.location != NSNotFound {
            full.addAttribute(.baselineOffset, value: 6, range: suffixRange)
            full.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: suffixRange)
        }
        return full
    }

    private func ordinalSuffix(_ day: Int) -> String {
        switch day {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }

    /// Reads today's total steps + distance from local DB (used when showing Week/Month tab)
    private func todayDataFromDB() -> (steps: Int, distanceMeters: Int) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let entries = StepsRepository().getByDateRange(start: start, end: end)
        let steps = entries.reduce(0) { $0 + Int($1.steps) }
        let distance = entries.reduce(0) { $0 + Int($1.distance) }
        return (steps, distance)
    }
}

// MARK: - VitalChartDataSource
extension StepsViewController: VitalChartDataSource {
    func fetchChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        guard userId > 0 else { completion([]); return }

        currentRange = range
        currentDate = date
        apiDataFetched = false

        switch range {
        case .day:
            dayDataCompletion = completion
            stepsSyncHelper?.fetchDataForDate(userId: userId, date: date)

        case .week, .month:
            stepsDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints, totals in
                guard let self = self else { return }
                completion(dataPoints)

                DispatchQueue.main.async {
                    // Range card: period total with actual DB distance
                    self.updateRangeCard(steps: totals.totalSteps, distanceMeters: totals.totalDistance, range: range, date: date)
                    // Today's card: always today's actual BLE data from DB
                    let today = self.todayDataFromDB()
                    self.updateStepsCard(steps: today.steps, distanceMeters: today.distanceMeters, date: Date())

                    if !self.apiDataFetched {
                        self.apiDataFetched = true
                        self.stepsDailySyncHelper?.fetchAPIAndMerge(
                            userId: self.userId,
                            range: range,
                            selectedDate: date,
                            localPoints: dataPoints
                        ) { [weak self] mergedPoints, mergedSteps in
                            guard let self = self else { return }
                            if mergedPoints.count > dataPoints.count {
                                completion(mergedPoints)
                                // Distance stays from local DB totals (no distance in API-only entries)
                                self.updateRangeCard(steps: mergedSteps, distanceMeters: totals.totalDistance, range: range, date: date)
                            }
                        }
                    }
                }
            }
        }
    }

    func fetchSecondaryChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        completion([])
    }
}

// MARK: - StepsSyncListener
extension StepsViewController: StepsSyncHelper.StepsSyncListener {
    func onStepsDataFetched(_ data: [YCHealthDataStep]) {
        print("✅ [Steps] Received \(data.count) entries from ring")
        chartView.reloadData()
    }

    func onLocalDataFetched(_ data: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Chart: one bar per entry (steps value)
            let dataPoints = data.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.steps)) }
            let totalSteps = data.reduce(0) { $0 + $1.steps }
            let totalDistance = data.reduce(0) { $0 + $1.distance }  // meters from BLE ring

            self.updateStepsCard(steps: totalSteps, distanceMeters: totalDistance, date: self.currentDate)
            self.updateRangeCard(steps: 0, distanceMeters: 0, range: .day, date: self.currentDate)

            self.dayDataCompletion?(dataPoints)
            self.dayDataCompletion = nil
        }
    }

    func onSyncFailed(error: String) {
        print("❌ [Steps] Sync failed: \(error)")
    }

    func onUpToDate() {
        print("[StepsVC] ✅ Steps data is up to date")
        let next = SyncFreshnessChecker.nextSyncMessage(for: SyncFreshnessChecker.SyncTimeKey.steps)
        let msg = next.isEmpty ? "Steps data is up to date" : "Steps data is up to date. \(next)"
        Toast.show(message: msg, in: view)
    }
}

// MARK: - StepsDailySyncListener
extension StepsViewController: StepsDailySyncHelper.StepsDailySyncListener {
    func onLocalDailyDataFetched(_ data: [VitalDataPoint]) {
        // Not used directly — data comes via completion closure
    }

    func onDailySyncFailed(error: String) {
        print("❌ [Steps Daily] Sync failed: \(error)")
    }
}

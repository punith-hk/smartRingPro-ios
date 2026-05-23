import UIKit
import YCProductSDK

/// Calories ViewController showing bar chart of calories burned
/// Data source: YCHealthDataStep (BLE) → StepsRepository (local DB) → Bar chart
final class CaloriesViewController: AppBaseViewController {

    // MARK: - Properties
    private let userId = UserDefaultsManager.shared.userId

    // MARK: - Chart
    private lazy var chartView: VitalChartView = {
        let chart = VitalChartView(vitalType: .calories)
        chart.dataSource = self
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()

    // MARK: - State
    private var dayDataCompletion: (([VitalDataPoint]) -> Void)?
    private var currentRange: VitalChartRange = .day
    private var currentDate: Date = Date()
    private var apiDataFetched = false   // prevents infinite API refetch loop

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Consumption Card (always visible)
    private let consumptionCard       = UIView()
    private let consumptionTitleLabel = UILabel()
    private let consumptionValueLabel = UILabel()
    private let consumptionUnitLabel  = UILabel()
    private let consumptionIconBg     = UIView()
    private let consumptionIcon       = UIImageView()

    // MARK: - Range Summary Card (Week / Month only)
    private let rangeCard       = UIView()
    private let rangeTitleLabel = UILabel()
    private let rangeValueLabel = UILabel()
    private let rangeUnitLabel  = UILabel()
    private let rangeIconBg     = UIView()
    private let rangeIcon       = UIImageView()

    // MARK: - Sync Helpers
    private var calSyncHelper: CaloriesSyncHelper?
    private var calDailySyncHelper: CaloriesDailySyncHelper?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Calories")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

        setupUI()
        setupSyncHelpers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Trigger BLE sync to fetch fresh data from ring
        startBLESync()
        
        chartView.reloadData()
    }

    // MARK: - Setup
    private func setupSyncHelpers() {
        calSyncHelper = CaloriesSyncHelper(listener: self)
        calDailySyncHelper = CaloriesDailySyncHelper()
    }
    
    // MARK: - BLE Sync
    private func startBLESync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            print("⚠️ [Calories] No device connected")
            return
        }
        
        print("🔄 [Calories] Starting BLE sync for calorie data...")
        calSyncHelper?.startSync()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Scroll
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

        // Chart
        contentView.addSubview(chartView)

        // Cards
        setupConsumptionCard()
        setupRangeCard()

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            consumptionCard.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 12),
            consumptionCard.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            consumptionCard.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            consumptionCard.heightAnchor.constraint(equalToConstant: 88),

            rangeCard.topAnchor.constraint(equalTo: consumptionCard.bottomAnchor, constant: 12),
            rangeCard.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            rangeCard.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            rangeCard.heightAnchor.constraint(equalToConstant: 100),
            rangeCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupConsumptionCard() {
        // Card
        consumptionCard.backgroundColor = .white
        consumptionCard.layer.cornerRadius = 24
        consumptionCard.layer.shadowColor = UIColor.black.cgColor
        consumptionCard.layer.shadowOpacity = 0.08
        consumptionCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        consumptionCard.layer.shadowRadius = 6
        consumptionCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(consumptionCard)

        // Title label (18pt, black)
        consumptionTitleLabel.text = "Today's Consumption"
        consumptionTitleLabel.font = .systemFont(ofSize: 18)
        consumptionTitleLabel.textColor = .black
        consumptionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionTitleLabel)

        // Value label (24pt bold, black)
        consumptionValueLabel.text = "0"
        consumptionValueLabel.font = .boldSystemFont(ofSize: 24)
        consumptionValueLabel.textColor = .black
        consumptionValueLabel.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionValueLabel)

        // Unit label (18pt, black, baseline-aligned)
        consumptionUnitLabel.text = "kcal"
        consumptionUnitLabel.font = .systemFont(ofSize: 18)
        consumptionUnitLabel.textColor = .black
        consumptionUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionUnitLabel)

        // Icon: 50×50 red circle with white flame
        consumptionIconBg.backgroundColor = UIColor(red: 235/255, green: 50/255, blue: 35/255, alpha: 1)
        consumptionIconBg.layer.cornerRadius = 25
        consumptionIconBg.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionIconBg)

        consumptionIcon.image = UIImage(systemName: "flame.fill")
        consumptionIcon.tintColor = .white
        consumptionIcon.contentMode = .scaleAspectFit
        consumptionIcon.translatesAutoresizingMaskIntoConstraints = false
        consumptionIconBg.addSubview(consumptionIcon)

        NSLayoutConstraint.activate([
            consumptionTitleLabel.topAnchor.constraint(equalTo: consumptionCard.topAnchor, constant: 16),
            consumptionTitleLabel.leadingAnchor.constraint(equalTo: consumptionCard.leadingAnchor, constant: 24),
            consumptionTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: consumptionIconBg.leadingAnchor, constant: -12),

            consumptionValueLabel.topAnchor.constraint(equalTo: consumptionTitleLabel.bottomAnchor, constant: 8),
            consumptionValueLabel.leadingAnchor.constraint(equalTo: consumptionCard.leadingAnchor, constant: 24),

            consumptionUnitLabel.firstBaselineAnchor.constraint(equalTo: consumptionValueLabel.firstBaselineAnchor),
            consumptionUnitLabel.leadingAnchor.constraint(equalTo: consumptionValueLabel.trailingAnchor, constant: 4),

            consumptionIconBg.trailingAnchor.constraint(equalTo: consumptionCard.trailingAnchor, constant: -20),
            consumptionIconBg.centerYAnchor.constraint(equalTo: consumptionCard.centerYAnchor),
            consumptionIconBg.widthAnchor.constraint(equalToConstant: 50),
            consumptionIconBg.heightAnchor.constraint(equalToConstant: 50),

            consumptionIcon.centerXAnchor.constraint(equalTo: consumptionIconBg.centerXAnchor),
            consumptionIcon.centerYAnchor.constraint(equalTo: consumptionIconBg.centerYAnchor),
            consumptionIcon.widthAnchor.constraint(equalToConstant: 26),
            consumptionIcon.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    private func setupRangeCard() {
        // Card — hidden in Day mode
        rangeCard.backgroundColor = .white
        rangeCard.layer.cornerRadius = 24
        rangeCard.layer.shadowColor = UIColor.black.cgColor
        rangeCard.layer.shadowOpacity = 0.08
        rangeCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        rangeCard.layer.shadowRadius = 6
        rangeCard.isHidden = true
        rangeCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rangeCard)

        // Title label (15pt, black, 2 lines)
        rangeTitleLabel.text = "Consumption"
        rangeTitleLabel.font = .systemFont(ofSize: 15)
        rangeTitleLabel.textColor = .black
        rangeTitleLabel.numberOfLines = 2
        rangeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeTitleLabel)

        // Value label (24pt bold, black)
        rangeValueLabel.text = "0"
        rangeValueLabel.font = .boldSystemFont(ofSize: 24)
        rangeValueLabel.textColor = .black
        rangeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeValueLabel)

        // Unit label (18pt, black, baseline-aligned)
        rangeUnitLabel.text = "kcal"
        rangeUnitLabel.font = .systemFont(ofSize: 18)
        rangeUnitLabel.textColor = .black
        rangeUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeUnitLabel)

        // Icon: 50×50 orange circle with white flame
        rangeIconBg.backgroundColor = UIColor(red: 255/255, green: 140/255, blue: 0/255, alpha: 1)
        rangeIconBg.layer.cornerRadius = 25
        rangeIconBg.translatesAutoresizingMaskIntoConstraints = false
        rangeCard.addSubview(rangeIconBg)

        rangeIcon.image = UIImage(systemName: "flame.fill")
        rangeIcon.tintColor = .white
        rangeIcon.contentMode = .scaleAspectFit
        rangeIcon.translatesAutoresizingMaskIntoConstraints = false
        rangeIconBg.addSubview(rangeIcon)

        NSLayoutConstraint.activate([
            rangeTitleLabel.topAnchor.constraint(equalTo: rangeCard.topAnchor, constant: 16),
            rangeTitleLabel.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),
            rangeTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rangeIconBg.leadingAnchor, constant: -12),

            rangeValueLabel.topAnchor.constraint(equalTo: rangeTitleLabel.bottomAnchor, constant: 8),
            rangeValueLabel.leadingAnchor.constraint(equalTo: rangeCard.leadingAnchor, constant: 24),

            rangeUnitLabel.firstBaselineAnchor.constraint(equalTo: rangeValueLabel.firstBaselineAnchor),
            rangeUnitLabel.leadingAnchor.constraint(equalTo: rangeValueLabel.trailingAnchor, constant: 4),

            rangeIconBg.trailingAnchor.constraint(equalTo: rangeCard.trailingAnchor, constant: -20),
            rangeIconBg.centerYAnchor.constraint(equalTo: rangeCard.centerYAnchor),
            rangeIconBg.widthAnchor.constraint(equalToConstant: 50),
            rangeIconBg.heightAnchor.constraint(equalToConstant: 50),

            rangeIcon.centerXAnchor.constraint(equalTo: rangeIconBg.centerXAnchor),
            rangeIcon.centerYAnchor.constraint(equalTo: rangeIconBg.centerYAnchor),
            rangeIcon.widthAnchor.constraint(equalToConstant: 26),
            rangeIcon.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    // MARK: - Stats Update

    private func updateConsumptionCard(calories: Int, range: VitalChartRange, date: Date) {
        consumptionValueLabel.text = "\(calories)"
        consumptionTitleLabel.attributedText = consumptionTitle(for: range, date: date)
    }

    private func updateRangeCard(calories: Int, range: VitalChartRange, date: Date) {
        rangeCard.isHidden = (range == .day)
        guard range != .day else { return }

        rangeValueLabel.text = "\(calories)"

        let df = DateFormatter()
        let cal = Calendar.current
        switch range {
        case .week:
            // Mon–Sun of the selected week
            let weekday = cal.component(.weekday, from: date)
            let daysToMon = (weekday == 1) ? -6 : -(weekday - 2)
            let mon = cal.date(byAdding: .day, value: daysToMon, to: date)!
            let sun = cal.date(byAdding: .day, value: 6, to: mon)!
            df.dateFormat = "dd MMM"
            rangeTitleLabel.text = "\(df.string(from: mon)) – \(df.string(from: sun))\nConsumption"
        case .month:
            df.dateFormat = "MMM yyyy"
            rangeTitleLabel.text = "\(df.string(from: date)) Consumption"
        case .day:
            break
        }
    }

    private func resetCards(range: VitalChartRange, date: Date) {
        consumptionValueLabel.text = "0"
        consumptionTitleLabel.attributedText = consumptionTitle(for: range, date: date)
        rangeCard.isHidden = (range == .day)
        rangeValueLabel.text = "0"
    }

    /// Reads today's total calories synchronously from local DB.
    private func todayCaloriesFromDB() -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let entries = StepsRepository().getByDateRange(start: start, end: end)
        return entries.reduce(0) { $0 + Int($1.calories) }
    }

    // Returns attributed title with ordinal superscript for past days
    private func consumptionTitle(for range: VitalChartRange, date: Date) -> NSAttributedString {
        let str: String
        if range != .day {
            str = "Today's Consumption"
        } else if Calendar.current.isDateInToday(date) {
            str = "Today's Consumption"
        } else {
            let cal = Calendar.current
            let day = cal.component(.day, from: date)
            let suffix = ordinalSuffix(day)
            let df = DateFormatter()
            df.dateFormat = "MMM"
            str = "\(day)\(suffix) \(df.string(from: date)) Consumption"
            // Apply superscript to the suffix
            let full = NSMutableAttributedString(string: str, attributes: [.font: UIFont.systemFont(ofSize: 18)])
            let nsStr = str as NSString
            let suffixRange = nsStr.range(of: suffix)
            if suffixRange.location != NSNotFound {
                full.addAttribute(.baselineOffset, value: 6, range: suffixRange)
                full.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: suffixRange)
            }
            return full
        }
        return NSAttributedString(string: str, attributes: [.font: UIFont.systemFont(ofSize: 18)])
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
}

// MARK: - VitalChartDataSource
extension CaloriesViewController: VitalChartDataSource {
    func fetchChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        guard userId > 0 else {
            completion([])
            return
        }

        currentRange = range
        currentDate = date
        apiDataFetched = false   // reset so API is re-fetched on each navigation

        print("📊 Fetching Calories data for \(range)")

        switch range {
        case .day:
            dayDataCompletion = completion
            calSyncHelper?.fetchDataForDate(userId: userId, date: date)

        case .week, .month:
            calDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints, totals in
                guard let self = self else { return }

                completion(dataPoints)

                DispatchQueue.main.async {
                    // Top card always shows today's calories
                    let todayCalories = self.todayCaloriesFromDB()
                    self.updateConsumptionCard(calories: todayCalories, range: range, date: date)
                    self.updateRangeCard(calories: totals.totalCalories, range: range, date: date)

                    // Fetch API daily aggregates in background and merge if they have
                    // data not present locally (e.g. from another device)
                    if !self.apiDataFetched {
                        self.apiDataFetched = true
                        self.calDailySyncHelper?.fetchAPIAndMerge(
                            userId: self.userId,
                            range: range,
                            selectedDate: date,
                            localPoints: dataPoints
                        ) { [weak self] mergedPoints, mergedCalories in
                            guard let self = self else { return }
                            // Only redraw range card if API added new dates
                            if mergedPoints.count > dataPoints.count {
                                completion(mergedPoints)
                                self.updateRangeCard(calories: mergedCalories, range: range, date: date)
                            }
                        }
                    }
                }
            }
        }
    }

    func fetchSecondaryChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        // Calories doesn't have secondary data
        completion([])
    }
}

// MARK: - CaloriesSyncListener
extension CaloriesViewController: CaloriesSyncHelper.CaloriesSyncListener {
    func onCaloriesDataFetched(_ data: [YCHealthDataStep]) {
        print("✅ Received \(data.count) entries from ring")
        chartView.reloadData()
    }

    func onLocalCaloriesDataFetched(_ data: [(timestamp: Int64, calories: Int)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let dataPoints = data.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.calories)) }
            let totalCalories = data.reduce(0) { $0 + $1.calories }

            self.updateConsumptionCard(calories: totalCalories, range: self.currentRange, date: self.currentDate)
            self.updateRangeCard(calories: totalCalories, range: self.currentRange, date: self.currentDate)

            self.dayDataCompletion?(dataPoints)
            self.dayDataCompletion = nil
        }
    }

    func onCaloriesSyncFailed(error: String) {
        print("❌ [Calories] Sync failed: \(error)")
    }
}



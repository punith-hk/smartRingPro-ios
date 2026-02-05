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
    
    // Store current range data for cards
    private var currentStepsData: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)] = []
    private var currentRange: VitalChartRange = .day
    private var currentDate: Date = Date()

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Custom Stats Cards
    private let consumptionCard = UIView()
    private let consumptionTitleLabel = UILabel()
    private let consumptionValueLabel = UILabel()
    private let consumptionIcon = UIImageView()
    
    private let stepsCard = UIView()
    private let stepsTitleLabel = UILabel()
    private let stepsValueLabel = UILabel()
    private let distanceValueLabel = UILabel()
    private let stepsIcon = UIImageView()

    // MARK: - Sync Helpers
    private var stepsSyncHelper: StepsSyncHelper?
    private var stepsDailySyncHelper: StepsDailySyncHelper?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Calories")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)

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
        stepsSyncHelper = StepsSyncHelper(listener: self)
        stepsDailySyncHelper = StepsDailySyncHelper(listener: self)
    }
    
    // MARK: - BLE Sync
    private func startBLESync() {
        guard BLEStateManager.shared.hasConnectedDevice() else {
            print("⚠️ [Calories] No device connected")
            return
        }
        
        print("🔄 [Calories] Starting BLE sync for step data...")
        stepsSyncHelper?.startSync()
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
        
        // Setup custom cards
        setupConsumptionCard()
        setupStepsCard()

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            consumptionCard.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            consumptionCard.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            consumptionCard.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            consumptionCard.heightAnchor.constraint(equalToConstant: 80),
            
            stepsCard.topAnchor.constraint(equalTo: consumptionCard.bottomAnchor, constant: 12),
            stepsCard.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            stepsCard.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            stepsCard.heightAnchor.constraint(equalToConstant: 80),
            stepsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupConsumptionCard() {
        consumptionCard.backgroundColor = .white
        consumptionCard.layer.cornerRadius = 12
        consumptionCard.layer.shadowColor = UIColor.black.cgColor
        consumptionCard.layer.shadowOpacity = 0.1
        consumptionCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        consumptionCard.layer.shadowRadius = 4
        consumptionCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(consumptionCard)
        
        // Icon
        consumptionIcon.image = UIImage(systemName: "flame.fill")
        consumptionIcon.tintColor = .systemRed
        consumptionIcon.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionIcon)
        
        // Title
        consumptionTitleLabel.text = "Today's Consumption"
        consumptionTitleLabel.font = .systemFont(ofSize: 14)
        consumptionTitleLabel.textColor = .darkGray
        consumptionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionTitleLabel)
        
        // Value
        consumptionValueLabel.text = "0 kcal"
        consumptionValueLabel.font = .boldSystemFont(ofSize: 20)
        consumptionValueLabel.textColor = .black
        consumptionValueLabel.translatesAutoresizingMaskIntoConstraints = false
        consumptionCard.addSubview(consumptionValueLabel)
        
        NSLayoutConstraint.activate([
            consumptionTitleLabel.topAnchor.constraint(equalTo: consumptionCard.topAnchor, constant: 12),
            consumptionTitleLabel.leadingAnchor.constraint(equalTo: consumptionCard.leadingAnchor, constant: 16),
            
            consumptionValueLabel.topAnchor.constraint(equalTo: consumptionTitleLabel.bottomAnchor, constant: 12),
            consumptionValueLabel.leadingAnchor.constraint(equalTo: consumptionCard.leadingAnchor, constant: 16),
            
            consumptionIcon.trailingAnchor.constraint(equalTo: consumptionCard.trailingAnchor, constant: -20),
            consumptionIcon.centerYAnchor.constraint(equalTo: consumptionCard.centerYAnchor),
            consumptionIcon.widthAnchor.constraint(equalToConstant: 40),
            consumptionIcon.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupStepsCard() {
        stepsCard.backgroundColor = .white
        stepsCard.layer.cornerRadius = 12
        stepsCard.layer.shadowColor = UIColor.black.cgColor
        stepsCard.layer.shadowOpacity = 0.1
        stepsCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        stepsCard.layer.shadowRadius = 4
        stepsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepsCard)
        
        // Icon
        stepsIcon.image = UIImage(systemName: "figure.walk")
        stepsIcon.tintColor = .systemBlue
        stepsIcon.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsIcon)
        
        // Title
        stepsTitleLabel.text = "Today's Steps"
        stepsTitleLabel.font = .systemFont(ofSize: 14)
        stepsTitleLabel.textColor = .darkGray
        stepsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsTitleLabel)
        
        // Steps value
        stepsValueLabel.text = "0 Steps"
        stepsValueLabel.font = .boldSystemFont(ofSize: 20)
        stepsValueLabel.textColor = .black
        stepsValueLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(stepsValueLabel)
        
        // Distance value
        distanceValueLabel.text = "0.00 KM"
        distanceValueLabel.font = .systemFont(ofSize: 16)
        distanceValueLabel.textColor = .black
        distanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsCard.addSubview(distanceValueLabel)
        
        NSLayoutConstraint.activate([
            stepsTitleLabel.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 12),
            stepsTitleLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 16),
            
            stepsValueLabel.topAnchor.constraint(equalTo: stepsTitleLabel.bottomAnchor, constant: 12),
            stepsValueLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 16),
            
            distanceValueLabel.centerYAnchor.constraint(equalTo: stepsValueLabel.centerYAnchor),
            distanceValueLabel.leadingAnchor.constraint(equalTo: stepsValueLabel.trailingAnchor, constant: 12),
            
            stepsIcon.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -20),
            stepsIcon.centerYAnchor.constraint(equalTo: stepsCard.centerYAnchor),
            stepsIcon.widthAnchor.constraint(equalToConstant: 40),
            stepsIcon.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Stats Update
    private func updateStatsCards(with data: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)], range: VitalChartRange, date: Date) {
        guard !data.isEmpty else {
            resetStatsCards(range: range, date: date)
            return
        }
        
        // Calculate totals
        let totalCalories = data.reduce(0) { $0 + $1.calories }
        let totalSteps = data.reduce(0) { $0 + $1.steps }
        let totalDistance = data.reduce(0) { $0 + $1.distance }
        let distanceKm = Double(totalDistance) / 1000.0
        
        // Update consumption card with attributed text (smaller unit)
        let caloriesText = NSMutableAttributedString(string: "\(totalCalories) ", attributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
        caloriesText.append(NSAttributedString(string: "kcal", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        consumptionValueLabel.attributedText = caloriesText
        
        // Update steps card with attributed text (smaller unit)
        let stepsText = NSMutableAttributedString(string: "\(totalSteps) ", attributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
        stepsText.append(NSAttributedString(string: "Steps", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        stepsValueLabel.attributedText = stepsText
        
        let distanceText = NSMutableAttributedString(string: String(format: "%.2f ", distanceKm), attributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
        distanceText.append(NSAttributedString(string: "KM", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        distanceValueLabel.attributedText = distanceText
        
        // Update card titles based on range
        let dateFormatter = DateFormatter()
        switch range {
        case .day:
            if Calendar.current.isDateInToday(date) {
                consumptionTitleLabel.text = "Today's Consumption"
                stepsTitleLabel.text = "Today's Steps"
            } else {
                dateFormatter.dateFormat = "d MMM"
                let dateStr = dateFormatter.string(from: date)
                consumptionTitleLabel.text = "\(dateStr) Consumption"
                stepsTitleLabel.text = "\(dateStr) Steps"
            }
            
        case .week:
            consumptionTitleLabel.text = "Week Consumption"
            stepsTitleLabel.text = "Week Steps"
            
        case .month:
            dateFormatter.dateFormat = "MMMM yyyy"
            let monthStr = dateFormatter.string(from: date)
            consumptionTitleLabel.text = "\(monthStr) Consumption"
            stepsTitleLabel.text = "\(monthStr) Steps"
        }
    }
    
    private func resetStatsCards(range: VitalChartRange, date: Date) {
        // Set empty values with attributed text (smaller units)
        let caloriesText = NSMutableAttributedString(string: "0 ", attributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
        caloriesText.append(NSAttributedString(string: "kcal", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        consumptionValueLabel.attributedText = caloriesText
        
        let stepsText = NSMutableAttributedString(string: "0 ", attributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
        stepsText.append(NSAttributedString(string: "Steps", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        stepsValueLabel.attributedText = stepsText
        
        let distanceText = NSMutableAttributedString(string: "0.00 ", attributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
        distanceText.append(NSAttributedString(string: "KM", attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        distanceValueLabel.attributedText = distanceText
        
        // Update titles based on range
        let dateFormatter = DateFormatter()
        switch range {
        case .day:
            if Calendar.current.isDateInToday(date) {
                consumptionTitleLabel.text = "Today's Consumption"
                stepsTitleLabel.text = "Today's Steps"
            } else {
                dateFormatter.dateFormat = "d MMM"
                let dateStr = dateFormatter.string(from: date)
                consumptionTitleLabel.text = "\(dateStr) Consumption"
                stepsTitleLabel.text = "\(dateStr) Steps"
            }
            
        case .week:
            consumptionTitleLabel.text = "Week Consumption"
            stepsTitleLabel.text = "Week Steps"
            
        case .month:
            dateFormatter.dateFormat = "MMMM yyyy"
            let monthStr = dateFormatter.string(from: date)
            consumptionTitleLabel.text = "\(monthStr) Consumption"
            stepsTitleLabel.text = "\(monthStr) Steps"
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

        print("📊 Fetching Calories data for \(range)")

        switch range {
        case .day:
            dayDataCompletion = completion
            stepsSyncHelper?.fetchDataForDate(userId: userId, date: date)

        case .week, .month:
            stepsDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints, totals in
                guard let self = self else { return }
                
                completion(dataPoints)
                
                // Use real cumulative totals from helper for cards
                let dataForCards = [(
                    timestamp: Int64(date.timeIntervalSince1970),
                    steps: totals.totalSteps,
                    distance: totals.totalDistance,
                    calories: totals.totalCalories
                )]
                self.updateStatsCards(with: dataForCards, range: range, date: date)
            }
        }
    }

    func fetchSecondaryChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        // Calories doesn't have secondary data
        completion([])
    }
}

// MARK: - StepsSyncListener
extension CaloriesViewController: StepsSyncHelper.StepsSyncListener {
    func onStepsDataFetched(_ data: [YCHealthDataStep]) {
        print("✅ Received \(data.count) step entries from ring")
        chartView.reloadData()
    }

    func onLocalDataFetched(_ data: [(timestamp: Int64, steps: Int, distance: Int, calories: Int)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            print("📊 [Calories] Processing \(data.count) local entries")
            
            // Store current data
            self.currentStepsData = data

            // Convert to VitalDataPoint (using calories only)
            let dataPoints = data.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.calories)) }
            
            print("📊 [Calories] Created \(dataPoints.count) data points for chart")
            if let first = dataPoints.first {
                print("   First point: timestamp=\(first.timestamp), calories=\(first.value)kcal")
            }

            // Update stats cards with full data
            self.updateStatsCards(with: data, range: self.currentRange, date: self.currentDate)

            // Call chart completion
            self.dayDataCompletion?(dataPoints)
            self.dayDataCompletion = nil
        }
    }

    func onSyncFailed(error: String) {
        print("❌ [Calories] Sync failed: \(error)")
    }
}

// MARK: - StepsDailySyncListener
extension CaloriesViewController: StepsDailySyncHelper.StepsDailySyncListener {
    func onLocalDailyDataFetched(_ data: [VitalDataPoint]) {
        // Not used currently - data loaded directly via completion
    }

    func onDailySyncFailed(error: String) {
        print("❌ [Calories Daily] Sync failed: \(error)")
    }
}



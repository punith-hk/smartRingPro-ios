import UIKit
import YCProductSDK

final class SleepViewController: AppBaseViewController {

    private let userId = UserDefaultsManager.shared.userId

    // MARK: - Range Selection
    private enum SleepRange {
        case day, week, month
    }
    private var currentRange: SleepRange = .day
    private var currentDate = Date()

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Tab Selection
    private let segmentedControl = UISegmentedControl(items: ["Day", "Week", "Month"])

    // MARK: - Chart Card
    private let chartCard = UIView()
    private let chartDateLabel = UILabel()
    private let chartTimeLabel = UILabel()
    private let chartSubtitleLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let sleepChartView = SleepChartView()
    private let chartPlaceholder = UILabel()

    // MARK: - Stat Cards (5 cards)
    private let statsStack = UIStackView()
    private let deepSleepCard = SleepStatCard(icon: "moon.fill", title: "Deep sleep duration", color: .systemPurple)
    private let lightSleepCard = SleepStatCard(icon: "moon", title: "Light sleep duration", color: .systemTeal)
    private let remSleepCard = SleepStatCard(icon: "sparkles", title: "REM duration", color: .systemBlue)
    private let awakeDurationCard = SleepStatCard(icon: "sun.max.fill", title: "Awakening duration", color: .systemGreen)
    private let totalSleepCard = SleepStatCard(icon: "clock.fill", title: "Sleep duration", color: .systemOrange)

    // MARK: - Sleep Quality Score Card
    private let sleepQualityCard = UIView()
    private let qualityTitleLabel = UILabel()
    private let qualityScoreLabel = UILabel()
    private let qualityGradientBar = UIView()
    private let qualityGradientLayer = CAGradientLayer()
    private let qualityDescriptionLabel = UILabel()

    // MARK: - Sleep Efficiency Card
    private let sleepEfficiencyCard = UIView()
    private let efficiencyIconLabel = UILabel()
    private let efficiencyTitleLabel = UILabel()
    private let efficiencyValueLabel = UILabel()
    private let efficiencyDescriptionLabel = UILabel()

    // MARK: - Sync Helper
    private var sleepSyncHelper: SleepSyncHelper?
    private let sleepRepository = SleepRepository()
    private let sleepDailyStatsRepository = SleepDailyStatsRepository.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Sleep")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient bar frame
        qualityGradientLayer.frame = qualityGradientBar.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initialize sync helper
        sleepSyncHelper = SleepSyncHelper(listener: self)
        
        // Start BLE sync if connected
        if DeviceSessionManager.shared.isDeviceConnected() {
            sleepSyncHelper?.startSync()
        } else {
            print("❌ SleepVC - No device connected")
        }
        
        // Load current day data if in day tab
        if currentRange == .day {
            loadSleepDataForCurrentDate()
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Scroll view
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

        setupSegmentedControl()
        setupChartCard()
        setupStatCards()
        setupSleepQualityCard()
        setupSleepEfficiencyCard()
    }

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(rangeChanged), for: .valueChanged)
        contentView.addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setupChartCard() {
        chartCard.backgroundColor = .white
        chartCard.layer.cornerRadius = 16
        chartCard.layer.shadowColor = UIColor.black.cgColor
        chartCard.layer.shadowOpacity = 0.1
        chartCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        chartCard.layer.shadowRadius = 8
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartCard)

        // Date navigation header
        previousButton.setTitle("‹", for: .normal)
        previousButton.titleLabel?.font = .boldSystemFont(ofSize: 32)
        previousButton.setTitleColor(.systemBlue, for: .normal)
        previousButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        previousButton.addTarget(self, action: #selector(previousDateTapped), for: .touchUpInside)
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(previousButton)

        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .boldSystemFont(ofSize: 32)
        nextButton.setTitleColor(.systemBlue, for: .normal)
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nextButton.addTarget(self, action: #selector(nextDateTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(nextButton)

        chartDateLabel.text = "2026.01.18"
        chartDateLabel.font = .boldSystemFont(ofSize: 16)
        chartDateLabel.textAlignment = .center
        chartDateLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(chartDateLabel)

        chartTimeLabel.text = "--:--"
        chartTimeLabel.font = .systemFont(ofSize: 13)
        chartTimeLabel.textColor = .gray
        chartTimeLabel.textAlignment = .center
        chartTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(chartTimeLabel)

        chartSubtitleLabel.text = "--"
        chartSubtitleLabel.font = .systemFont(ofSize: 13)
        chartSubtitleLabel.textColor = .gray
        chartSubtitleLabel.textAlignment = .center
        chartSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(chartSubtitleLabel)

        // Sleep Chart View
        sleepChartView.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(sleepChartView)
        
        // Set up chart tap callback
        sleepChartView.onSleepSegmentSelected = { [weak self] time, sleepType in
            self?.updateChartLabelsForSelection(time: time, sleepType: sleepType)
        }

        // Chart placeholder (show when no data)
        chartPlaceholder.text = "No sleep data for this date"
        chartPlaceholder.font = .systemFont(ofSize: 14)
        chartPlaceholder.textColor = .lightGray
        chartPlaceholder.textAlignment = .center
        chartPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        chartPlaceholder.isHidden = true
        chartCard.addSubview(chartPlaceholder)

        NSLayoutConstraint.activate([
            chartCard.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            chartCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartCard.heightAnchor.constraint(equalToConstant: 280),

            chartDateLabel.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 12),
            chartDateLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),

            previousButton.centerYAnchor.constraint(equalTo: chartDateLabel.centerYAnchor),
            previousButton.trailingAnchor.constraint(equalTo: chartDateLabel.leadingAnchor, constant: -12),

            nextButton.centerYAnchor.constraint(equalTo: chartDateLabel.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: chartDateLabel.trailingAnchor, constant: 12),

            chartTimeLabel.topAnchor.constraint(equalTo: chartDateLabel.bottomAnchor, constant: 2),
            chartTimeLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),

            chartSubtitleLabel.topAnchor.constraint(equalTo: chartTimeLabel.bottomAnchor, constant: 2),
            chartSubtitleLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
            
            sleepChartView.topAnchor.constraint(equalTo: chartSubtitleLabel.bottomAnchor, constant: -12),
            sleepChartView.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 8),
            sleepChartView.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -8),
            sleepChartView.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -12),

            chartPlaceholder.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
            chartPlaceholder.centerYAnchor.constraint(equalTo: sleepChartView.centerYAnchor)
        ])

        updateDateLabel()
    }

    private func setupStatCards() {
        statsStack.axis = .vertical
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsStack)

        // First row: Deep, Light, REM (3 cards)
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually
        [deepSleepCard, lightSleepCard, remSleepCard].forEach { topRow.addArrangedSubview($0) }

        // Second row: Awake, Total (2 cards)
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 12
        bottomRow.distribution = .fillEqually
        [awakeDurationCard, totalSleepCard].forEach { bottomRow.addArrangedSubview($0) }

        [topRow, bottomRow].forEach { statsStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsStack.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Set initial values
        resetStatCards()
    }

    private func setupSleepQualityCard() {
        sleepQualityCard.backgroundColor = .white
        sleepQualityCard.layer.cornerRadius = 16
        sleepQualityCard.layer.shadowColor = UIColor.black.cgColor
        sleepQualityCard.layer.shadowOpacity = 0.1
        sleepQualityCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        sleepQualityCard.layer.shadowRadius = 8
        sleepQualityCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sleepQualityCard)

        qualityTitleLabel.text = "Sleep quality score"
        qualityTitleLabel.font = .systemFont(ofSize: 14)
        qualityTitleLabel.textColor = .darkGray
        qualityTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepQualityCard.addSubview(qualityTitleLabel)

        qualityScoreLabel.text = "-- Fraction"
        qualityScoreLabel.font = .boldSystemFont(ofSize: 28)
        qualityScoreLabel.textAlignment = .center
        qualityScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepQualityCard.addSubview(qualityScoreLabel)
        
        // Gradient bar
        qualityGradientBar.layer.cornerRadius = 8
        qualityGradientBar.clipsToBounds = true
        qualityGradientBar.translatesAutoresizingMaskIntoConstraints = false
        sleepQualityCard.addSubview(qualityGradientBar)
        
        // Setup gradient colors (orange -> purple -> blue)
        qualityGradientLayer.colors = [
            UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1).cgColor,  // Orange
            UIColor(red: 0.85, green: 0.55, blue: 0.48, alpha: 1).cgColor,  // Brown-red
            UIColor(red: 0.60, green: 0.45, blue: 0.70, alpha: 1).cgColor,  // Purple
            UIColor(red: 0.20, green: 0.40, blue: 0.90, alpha: 1).cgColor   // Blue
        ]
        qualityGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        qualityGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        qualityGradientBar.layer.addSublayer(qualityGradientLayer)

        qualityDescriptionLabel.text = "The sleep quality score is based on the basic principles of the pittsburgh sleep Quality Index. The ring evaluates and scores sleep quality through factors such as sleep quality, sleep onset time, sleep duration, sleep efficiency, number of awakenings at night, and awakening time. 0-60 points indicate very poor sleep quality; 60-69 points indicate poor sleep quality; 70-79 points indicate average sleep quality; 80-89 points indicate good sleep quality; 90-100 points indicate excellent sleep quality."
        qualityDescriptionLabel.font = .systemFont(ofSize: 12)
        qualityDescriptionLabel.textColor = UIColor(red: 0.4, green: 0.5, blue: 0.8, alpha: 1)
        qualityDescriptionLabel.numberOfLines = 0
        qualityDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepQualityCard.addSubview(qualityDescriptionLabel)

        NSLayoutConstraint.activate([
            sleepQualityCard.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 16),
            sleepQualityCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sleepQualityCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sleepQualityCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 230),

            qualityTitleLabel.topAnchor.constraint(equalTo: sleepQualityCard.topAnchor, constant: 16),
            qualityTitleLabel.leadingAnchor.constraint(equalTo: sleepQualityCard.leadingAnchor, constant: 16),

            qualityScoreLabel.topAnchor.constraint(equalTo: qualityTitleLabel.bottomAnchor, constant: 16),
            qualityScoreLabel.centerXAnchor.constraint(equalTo: sleepQualityCard.centerXAnchor),
            
            qualityGradientBar.topAnchor.constraint(equalTo: qualityScoreLabel.bottomAnchor, constant: 12),
            qualityGradientBar.leadingAnchor.constraint(equalTo: sleepQualityCard.leadingAnchor, constant: 16),
            qualityGradientBar.trailingAnchor.constraint(equalTo: sleepQualityCard.trailingAnchor, constant: -16),
            qualityGradientBar.heightAnchor.constraint(equalToConstant: 16),

            qualityDescriptionLabel.topAnchor.constraint(equalTo: qualityGradientBar.bottomAnchor, constant: 12),
            qualityDescriptionLabel.leadingAnchor.constraint(equalTo: sleepQualityCard.leadingAnchor, constant: 16),
            qualityDescriptionLabel.trailingAnchor.constraint(equalTo: sleepQualityCard.trailingAnchor, constant: -16),
            qualityDescriptionLabel.bottomAnchor.constraint(equalTo: sleepQualityCard.bottomAnchor, constant: -16)
        ])
    }

    private func setupSleepEfficiencyCard() {
        sleepEfficiencyCard.backgroundColor = .white
        sleepEfficiencyCard.layer.cornerRadius = 16
        sleepEfficiencyCard.layer.shadowColor = UIColor.black.cgColor
        sleepEfficiencyCard.layer.shadowOpacity = 0.1
        sleepEfficiencyCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        sleepEfficiencyCard.layer.shadowRadius = 8
        sleepEfficiencyCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sleepEfficiencyCard)

        efficiencyTitleLabel.text = "Analyse of falling asleep speed"
        efficiencyTitleLabel.font = .systemFont(ofSize: 14)
        efficiencyTitleLabel.textColor = .darkGray
        efficiencyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepEfficiencyCard.addSubview(efficiencyTitleLabel)
        
        // Icon with percentage
        efficiencyIconLabel.text = "📈"
        efficiencyIconLabel.font = .systemFont(ofSize: 24)
        efficiencyIconLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepEfficiencyCard.addSubview(efficiencyIconLabel)

        efficiencyValueLabel.text = "99%"
        efficiencyValueLabel.font = .boldSystemFont(ofSize: 36)
        efficiencyValueLabel.textColor = .systemBlue
        efficiencyValueLabel.textAlignment = .right
        efficiencyValueLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepEfficiencyCard.addSubview(efficiencyValueLabel)

        efficiencyDescriptionLabel.text = "Sleep efficiency is a way to quantify how fast you fall asleep. A sleep efficiency of 85% or more usually means that your sleep speed is relatively stable. When the sleep efficiency is between 70% and 84%, your sleep quality may be slightly poor, and you may have difficulty falling asleep or waking up easily at night. A sleep efficiency below 70% indicates poor sleep quantity."
        efficiencyDescriptionLabel.font = .systemFont(ofSize: 12)
        efficiencyDescriptionLabel.textColor = .gray
        efficiencyDescriptionLabel.numberOfLines = 0
        efficiencyDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepEfficiencyCard.addSubview(efficiencyDescriptionLabel)

        NSLayoutConstraint.activate([
            sleepEfficiencyCard.topAnchor.constraint(equalTo: sleepQualityCard.bottomAnchor, constant: 16),
            sleepEfficiencyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sleepEfficiencyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sleepEfficiencyCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
            sleepEfficiencyCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            efficiencyTitleLabel.topAnchor.constraint(equalTo: sleepEfficiencyCard.topAnchor, constant: 16),
            efficiencyTitleLabel.leadingAnchor.constraint(equalTo: sleepEfficiencyCard.leadingAnchor, constant: 16),
            
            efficiencyIconLabel.topAnchor.constraint(equalTo: efficiencyTitleLabel.bottomAnchor, constant: 16),
            efficiencyIconLabel.leadingAnchor.constraint(equalTo: sleepEfficiencyCard.leadingAnchor, constant: 16),

            efficiencyValueLabel.centerYAnchor.constraint(equalTo: efficiencyIconLabel.centerYAnchor),
            efficiencyValueLabel.trailingAnchor.constraint(equalTo: sleepEfficiencyCard.trailingAnchor, constant: -16),

            efficiencyDescriptionLabel.topAnchor.constraint(equalTo: efficiencyValueLabel.bottomAnchor, constant: 16),
            efficiencyDescriptionLabel.leadingAnchor.constraint(equalTo: sleepEfficiencyCard.leadingAnchor, constant: 16),
            efficiencyDescriptionLabel.trailingAnchor.constraint(equalTo: sleepEfficiencyCard.trailingAnchor, constant: -16),
            efficiencyDescriptionLabel.bottomAnchor.constraint(equalTo: sleepEfficiencyCard.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Range Selection
    @objc private func rangeChanged() {
        // Reset to current date when switching tabs
        currentDate = Date()
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            currentRange = .day
            updateDateLabel()
            loadSleepDataForCurrentDate()
        case 1:
            currentRange = .week
            updateDateLabel()
            // Ensure chart is visible for week view
            sleepChartView.isHidden = false
            chartPlaceholder.isHidden = true
            // Reset labels to default
            chartTimeLabel.text = "--"
            chartSubtitleLabel.text = "--"
            loadAndDisplayWeeklyChart()  // Load from local DB immediately
            loadWeeklySleepData()  // Then refresh from API
        case 2:
            currentRange = .month
            updateDateLabel()
            // Ensure chart is visible for month view
            sleepChartView.isHidden = false
            chartPlaceholder.isHidden = true
            // Reset labels to default
            chartTimeLabel.text = "--"
            chartSubtitleLabel.text = "--"
            loadAndDisplayMonthlyChart()  // Load from local DB immediately
            loadMonthlySleepData()  // Then refresh from API
        default:
            break
        }
    }

    // MARK: - Date Navigation
    @objc private func previousDateTapped() {
        switch currentRange {
        case .day:
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            loadSleepDataForCurrentDate()
        case .week:
            currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
            updateDateLabel()
            loadAndDisplayWeeklyChart()
            loadWeeklySleepData()
        case .month:
            currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
            updateDateLabel()
            loadAndDisplayMonthlyChart()
            loadMonthlySleepData()
        }
        updateDateLabel()
    }

    @objc private func nextDateTapped() {
        // Prevent navigation to future dates
        guard nextButton.isEnabled else { return }
        
        switch currentRange {
        case .day:
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            loadSleepDataForCurrentDate()
        case .week:
            currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            updateDateLabel()
            loadAndDisplayWeeklyChart()
            loadWeeklySleepData()
        case .month:
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            updateDateLabel()
            loadAndDisplayMonthlyChart()
            loadMonthlySleepData()
        }
        updateDateLabel()
    }

    private func updateDateLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        let calendar = Calendar.current
        let today = Date()
        
        switch currentRange {
        case .day:
            chartDateLabel.text = formatter.string(from: currentDate)
            chartTimeLabel.text = "--:--"
            chartSubtitleLabel.text = "--"
            // Enable next button only if selected date is before today
            nextButton.isEnabled = !calendar.isDate(currentDate, inSameDayAs: today)
            
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            chartDateLabel.text = "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
            chartTimeLabel.text = "--:--"
            chartSubtitleLabel.text = "--"
            // Enable next button only if week end is before today
            nextButton.isEnabled = calendar.compare(weekEnd, to: today, toGranularity: .day) == .orderedAscending
            
        case .month:
            formatter.dateFormat = "yyyy.MM.01 - yyyy.MM.31"
            let components = Calendar.current.dateComponents([.year, .month], from: currentDate)
            let monthStart = Calendar.current.date(from: components)!
            let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            let startFormatter = DateFormatter()
            startFormatter.dateFormat = "yyyy.MM.dd"
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "yyyy.MM.dd"
            chartDateLabel.text = "\(startFormatter.string(from: monthStart)) - \(endFormatter.string(from: monthEnd))"
            // Enable next button only if month end is before today
            nextButton.isEnabled = calendar.compare(monthEnd, to: today, toGranularity: .day) == .orderedAscending
        }
        
        // Update button appearance based on enabled state
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.3
    }

    private func resetStatCards() {
        deepSleepCard.updateValue("-- min")
        lightSleepCard.updateValue("-- min")
        remSleepCard.updateValue("-- min")
        awakeDurationCard.updateValue("-- min")
        totalSleepCard.updateValue("-- min")
        
        qualityScoreLabel.text = "-- Fraction"
        efficiencyValueLabel.text = "--%"
    }
    
    private func updateChartLabelsForSelection(time: Date, sleepType: String) {
        if currentRange == .day {
            // Day view: show time (HH:mm)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let timeString = timeFormatter.string(from: time)
            chartTimeLabel.text = timeString
        } else {
            // Week/Month view: show date (yyyy-MM-dd)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: time)
            chartTimeLabel.text = dateString
        }
        
        chartSubtitleLabel.text = sleepType
    }
    
    private func calculateSleepScore(totalSleepMinutes: Int) -> Int {
        // Calculate score based on 480 minutes (8 hours) as ideal
        let score = Int((Double(totalSleepMinutes) / 480.0) * 100.0)
        
        // Clamp between 12 and 100
        if score > 100 {
            return 100
        } else if score < 12 {
            return 12
        } else {
            return score
        }
    }
    
    private func calculateSleepEfficiency(totalSleepMinutes: Int, totalAwakeMinutes: Int) -> Int {
        let totalTimeInBed = totalSleepMinutes + totalAwakeMinutes
        
        guard totalTimeInBed > 0 else {
            return 0
        }
        
        let efficiency = (Double(totalSleepMinutes) / Double(totalTimeInBed)) * 100.0
        return Int(efficiency)
    }
    
    private func getSleepTypeName(_ type: Int) -> String {
        switch type {
        case 1: return "Deep sleep"
        case 2: return "Light sleep"
        case 3: return "REM"
        case 4: return "Awake"
        default: return "Unknown"
        }
    }
    
    private func formatDuration(minutes: Int) -> String {
        if minutes <= 59 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) h \(remainingMinutes) min"
        }
    }
    
    // MARK: - Load Sleep Data for Current Date
    private func loadSleepDataForCurrentDate() {
        guard currentRange == .day else { return }
        sleepSyncHelper?.syncDayData(for: currentDate)
    }
}

// MARK: - SleepSyncListener
extension SleepViewController: SleepSyncListener {
    func onSleepDataFetched(sessions: [YCHealthDataSleep]) {
        print("✅ [SleepVC] Received \(sessions.count) sleep sessions from BLE")
    }
    
    func onLocalDataSaved(count: Int) {
        print("✅ [SleepVC] Saved \(count) new sessions to local database")
        // Reload current day if in day tab
        if currentRange == .day {
            loadSleepDataForCurrentDate()
        }
    }
    
    func onSyncFailed(error: String) {
        print("❌ [SleepVC] Sync failed: \(error)")
    }
    
    func onDayDataLoaded(sessions: [SleepSessionEntity]) {
        guard !sessions.isEmpty else {
            print("ℹ️ [SleepVC] No data for selected date")
            DispatchQueue.main.async {
                self.resetStatCards()
                self.sleepChartView.clearChart()
                self.sleepChartView.isHidden = true
                self.chartPlaceholder.isHidden = false
                // Reset labels to show no data
                self.chartTimeLabel.text = "--:--"
                self.chartSubtitleLabel.text = "--"
            }
            return
        }
        
        // Aggregate all sessions for the day
        var totalDeepMinutes = 0
        var totalLightMinutes = 0
        var totalRemMinutes = 0
        var totalAwakeMinutes = 0
        
        for session in sessions {
            totalDeepMinutes += Int(session.deepSleepTimes) / 60
            totalLightMinutes += Int(session.lightSleepTimes) / 60
            totalRemMinutes += Int(session.remSleepTimes) / 60
            totalAwakeMinutes += Int(session.wakeupTimes) / 60
        }
        
        // Calculate gaps between sessions and add to awake time
        if sessions.count > 1 {
            // Sort sessions by start time
            let sortedSessions = sessions.sorted { $0.startTime < $1.startTime }
            
            for i in 0..<(sortedSessions.count - 1) {
                let currentSession = sortedSessions[i]
                let nextSession = sortedSessions[i + 1]
                
                let gapSeconds = nextSession.startTime - currentSession.endTime
                let gapMinutes = Int(gapSeconds) / 60
                
                // Only add gaps of 1 minute or more
                if gapMinutes >= 1 {
                    totalAwakeMinutes += gapMinutes
                    print("📊 [SleepVC] Gap between sessions: \(gapMinutes) min")
                }
            }
        }
        
        // Calculate total sleep duration (Deep + Light + REM only, NOT awake)
        let totalMinutes = totalDeepMinutes + totalLightMinutes + totalRemMinutes
        
        print("📊 [SleepVC] Displaying \(sessions.count) session(s) - Total: \(totalMinutes) min")
        
        // Find the last (most recent) sleep segment across all sessions
        var lastSegmentTime: Date?
        var lastSegmentType: Int16 = 0
        
        for session in sessions {
            if let details = session.details?.allObjects as? [SleepDetailEntity] {
                for detail in details {
                    let detailEndTime = Date(timeIntervalSince1970: TimeInterval(detail.endTime))
                    if lastSegmentTime == nil || detailEndTime > lastSegmentTime! {
                        lastSegmentTime = detailEndTime
                        lastSegmentType = detail.sleepType
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            // Update stat cards with aggregated data (formatted)
            self.deepSleepCard.updateValue(self.formatDuration(minutes: totalDeepMinutes))
            self.lightSleepCard.updateValue(self.formatDuration(minutes: totalLightMinutes))
            self.remSleepCard.updateValue(self.formatDuration(minutes: totalRemMinutes))
            self.awakeDurationCard.updateValue(self.formatDuration(minutes: totalAwakeMinutes))
            self.totalSleepCard.updateValue(self.formatDuration(minutes: totalMinutes))
            
            // Calculate and update sleep score
            let sleepScore = self.calculateSleepScore(totalSleepMinutes: totalMinutes)
            self.qualityScoreLabel.text = "\(sleepScore) Fraction"
            print("💤 [SleepVC] Sleep score: \(sleepScore)")
            
            // Calculate and update sleep efficiency
            let sleepEfficiency = self.calculateSleepEfficiency(totalSleepMinutes: totalMinutes, totalAwakeMinutes: totalAwakeMinutes)
            self.efficiencyValueLabel.text = "\(sleepEfficiency)%"
            print("💤 [SleepVC] Sleep efficiency: \(sleepEfficiency)%")
            
            // Update labels with last segment info
            if let lastTime = lastSegmentTime {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                self.chartTimeLabel.text = timeFormatter.string(from: lastTime)
                
                let sleepTypeName = self.getSleepTypeName(Int(lastSegmentType))
                self.chartSubtitleLabel.text = sleepTypeName
            } else {
                self.chartTimeLabel.text = "--:--"
                self.chartSubtitleLabel.text = "--"
            }
            
            // Load all sessions in chart with date filtering
            self.sleepChartView.loadSleepSessions(sessions: sessions, forDate: self.currentDate)
            self.sleepChartView.isHidden = false
            self.chartPlaceholder.isHidden = true
        }
    }
}

// MARK: - Custom Stat Card
class SleepStatCard: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    init(icon: String, title: String, color: UIColor) {
        super.init(frame: .zero)
        
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .darkGray
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.text = "-- min"
        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            valueLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}

// MARK: - Weekly/Monthly Data Loading
extension SleepViewController {
    
    private func loadWeeklySleepData() {
        guard userId > 0 else {
            print("⚠️ [SleepVC] No valid user ID")
            resetStatCards()
            return
        }
        
        let calendar = Calendar.current
        
        // Get week start (Sunday) and end (Saturday)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        
        // Format dates for API (MM/dd/yyyy)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let startDateString = dateFormatter.string(from: weekStart)
        let endDateString = dateFormatter.string(from: weekEnd)
        
        print("📊 [SleepVC] Loading weekly data: \(startDateString) - \(endDateString)")
        
        // Call API
        HealthService.shared.getSleepDataByDateRange(
            userId: userId,
            startDate: startDateString,
            endDate: endDateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let sessions = response.data, !sessions.isEmpty {
                        print("✅ [SleepVC] Got \(sessions.count) session(s) for week")
                        self.processWeeklySessions(sessions)
                    } else {
                        print("ℹ️ [SleepVC] No data for this week")
                        self.resetStatCards()
                    }
                    
                case .failure(let error):
                    print("❌ [SleepVC] Failed to load weekly data: \(error.localizedDescription)")
                    self.resetStatCards()
                }
            }
        }
    }
    
    private func loadMonthlySleepData() {
        guard userId > 0 else {
            print("⚠️ [SleepVC] No valid user ID")
            resetStatCards()
            return
        }
        
        let calendar = Calendar.current
        
        // Get month start and end
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        
        // Format dates for API (MM/dd/yyyy)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let startDateString = dateFormatter.string(from: monthStart)
        let endDateString = dateFormatter.string(from: monthEnd)
        
        print("📊 [SleepVC] Loading monthly data: \(startDateString) - \(endDateString)")
        
        // Call API
        HealthService.shared.getSleepDataByDateRange(
            userId: userId,
            startDate: startDateString,
            endDate: endDateString
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let sessions = response.data, !sessions.isEmpty {
                        print("✅ [SleepVC] Got \(sessions.count) session(s) for month")
                        self.processMonthlySessions(sessions)
                    } else {
                        print("ℹ️ [SleepVC] No data for this month")
                        self.resetStatCards()
                    }
                    
                case .failure(let error):
                    print("❌ [SleepVC] Failed to load monthly data: \(error.localizedDescription)")
                    self.resetStatCards()
                }
            }
        }
    }
    
    private func processWeeklySessions(_ sessions: [SleepBeanResponse]) {
        // Group sessions by date and aggregate
        var dailyStats: [String: (deep: Int, light: Int, rem: Int, awake: Int, sessionCount: Int)] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for session in sessions {
            // Get date from statisticTime
            let sessionDate = Date(timeIntervalSince1970: TimeInterval(session.statisticTime))
            let dateKey = dateFormatter.string(from: sessionDate)
            
            // Calculate values in minutes
            let deep = session.deepSleepTimes / 60
            let light = session.lightSleepTimes / 60
            let awake = session.wakeupTimes / 60
            
            // Calculate REM from sleep_details
            let rem = session.sleep_details
                .filter { $0.sleepType == 4 }  // REM type
                .reduce(0) { $0 + Int(($1.endTime - $1.startTime) / 60) }
            
            // Aggregate by date
            if var existing = dailyStats[dateKey] {
                existing.deep += deep
                existing.light += light
                existing.rem += rem
                existing.awake += awake
                existing.sessionCount += 1
                dailyStats[dateKey] = existing
            } else {
                dailyStats[dateKey] = (deep: deep, light: light, rem: rem, awake: awake, sessionCount: 1)
            }
        }
        
        // Save to local DB
        let statsArray = dailyStats.map { (date: $0.key, deep: $0.value.deep, light: $0.value.light, rem: $0.value.rem, awake: $0.value.awake, sessionCount: $0.value.sessionCount) }
        
        sleepDailyStatsRepository.saveBatch(userId: userId, stats: statsArray) { [weak self] success, savedCount in
            if success {
                print("💾 [SleepVC] Saved \(savedCount) daily stats to local DB")
                
                // Load from DB and update chart
                self?.loadAndDisplayWeeklyChart()
            }
        }
        
        // Calculate totals for UI
        var totalDeep = 0
        var totalLight = 0
        var totalRem = 0
        var totalAwake = 0
        
        for stat in dailyStats.values {
            totalDeep += stat.deep
            totalLight += stat.light
            totalRem += stat.rem
            totalAwake += stat.awake
        }
        
        let totalSleep = totalDeep + totalLight + totalRem
        
        print("📊 [SleepVC] Weekly totals: Deep=\(totalDeep)min, Light=\(totalLight)min, REM=\(totalRem)min, Awake=\(totalAwake)min")
        
        // Update stat cards
        deepSleepCard.updateValue(formatDuration(minutes: totalDeep))
        lightSleepCard.updateValue(formatDuration(minutes: totalLight))
        remSleepCard.updateValue(formatDuration(minutes: totalRem))
        awakeDurationCard.updateValue(formatDuration(minutes: totalAwake))
        totalSleepCard.updateValue(formatDuration(minutes: totalSleep))
    }
    
    private func processMonthlySessions(_ sessions: [SleepBeanResponse]) {
        // Group sessions by date and aggregate
        var dailyStats: [String: (deep: Int, light: Int, rem: Int, awake: Int, sessionCount: Int)] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for session in sessions {
            // Get date from statisticTime
            let sessionDate = Date(timeIntervalSince1970: TimeInterval(session.statisticTime))
            let dateKey = dateFormatter.string(from: sessionDate)
            
            // Calculate values in minutes
            let deep = session.deepSleepTimes / 60
            let light = session.lightSleepTimes / 60
            let awake = session.wakeupTimes / 60
            
            // Calculate REM from sleep_details
            let rem = session.sleep_details
                .filter { $0.sleepType == 4 }  // REM type
                .reduce(0) { $0 + Int(($1.endTime - $1.startTime) / 60) }
            
            // Aggregate by date
            if var existing = dailyStats[dateKey] {
                existing.deep += deep
                existing.light += light
                existing.rem += rem
                existing.awake += awake
                existing.sessionCount += 1
                dailyStats[dateKey] = existing
            } else {
                dailyStats[dateKey] = (deep: deep, light: light, rem: rem, awake: awake, sessionCount: 1)
            }
        }
        
        // Save to local DB
        let statsArray = dailyStats.map { (date: $0.key, deep: $0.value.deep, light: $0.value.light, rem: $0.value.rem, awake: $0.value.awake, sessionCount: $0.value.sessionCount) }
        
        sleepDailyStatsRepository.saveBatch(userId: userId, stats: statsArray) { [weak self] success, savedCount in
            if success {
                print("💾 [SleepVC] Saved \(savedCount) daily stats to local DB")
                
                // Load from DB and update chart
                self?.loadAndDisplayMonthlyChart()
            }
        }
        
        // Calculate totals for UI
        var totalDeep = 0
        var totalLight = 0
        var totalRem = 0
        var totalAwake = 0
        
        for stat in dailyStats.values {
            totalDeep += stat.deep
            totalLight += stat.light
            totalRem += stat.rem
            totalAwake += stat.awake
        }
        
        let totalSleep = totalDeep + totalLight + totalRem
        
        print("📊 [SleepVC] Monthly totals: Deep=\(totalDeep)min, Light=\(totalLight)min, REM=\(totalRem)min, Awake=\(totalAwake)min")
        
        // Update stat cards
        deepSleepCard.updateValue(formatDuration(minutes: totalDeep))
        lightSleepCard.updateValue(formatDuration(minutes: totalLight))
        remSleepCard.updateValue(formatDuration(minutes: totalRem))
        awakeDurationCard.updateValue(formatDuration(minutes: totalAwake))
        totalSleepCard.updateValue(formatDuration(minutes: totalSleep))
    }
    
    // MARK: - Chart Update Methods
    
    private func loadAndDisplayWeeklyChart() {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: weekStart)
        let endDateString = dateFormatter.string(from: weekEnd)
        
        print("📊 [SleepVC] Loading weekly chart data: \(startDateString) - \(endDateString)")
        
        let stats = sleepDailyStatsRepository.getDateRange(userId: userId, startDate: startDateString, endDate: endDateString)
        
        var dailyStats: [(date: String, deep: Int, light: Int, rem: Int, awake: Int)] = []
        for stat in stats {
            let entry = (date: stat.date ?? "", 
                        deep: Int(stat.deepSleepMinutes), 
                        light: Int(stat.lightSleepMinutes), 
                        rem: Int(stat.remSleepMinutes), 
                        awake: Int(stat.awakeMinutes))
            dailyStats.append(entry)
        }
        
        print("📊 [SleepVC] Loaded \(dailyStats.count) days from local DB for chart")
        sleepChartView.updateWithWeeklyStats(weekStartDate: weekStart, dailyStats: dailyStats)
    }
    
    private func loadAndDisplayMonthlyChart() {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: monthStart)
        let endDateString = dateFormatter.string(from: monthEnd)
        
        print("📊 [SleepVC] Loading monthly chart data: \(startDateString) - \(endDateString)")
        
        let stats = sleepDailyStatsRepository.getDateRange(userId: userId, startDate: startDateString, endDate: endDateString)
        
        var dailyStats: [(date: String, deep: Int, light: Int, rem: Int, awake: Int)] = []
        for stat in stats {
            let entry = (date: stat.date ?? "", 
                        deep: Int(stat.deepSleepMinutes), 
                        light: Int(stat.lightSleepMinutes), 
                        rem: Int(stat.remSleepMinutes), 
                        awake: Int(stat.awakeMinutes))
            dailyStats.append(entry)
        }
        
        print("📊 [SleepVC] Loaded \(dailyStats.count) days from local DB for chart")
        sleepChartView.updateWithMonthlyStats(monthStartDate: monthStart, dailyStats: dailyStats)
    }
}

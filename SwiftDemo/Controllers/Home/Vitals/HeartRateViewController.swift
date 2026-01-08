import UIKit

enum HeartRateRange {
    case day
    case week
    case month
}

final class HeartRateViewController: AppBaseViewController {

    private let userId = UserDefaultsManager.shared.userId
    
    private var selectedRange: HeartRateRange = .day

    // MARK: - State
    private var isMeasuring = false
    private var remainingSeconds = 60
    private var timer: Timer?

    // MARK: - Date State
    private var selectedDate = Date()
    
    private var weekStartDate: Date?
    private var weekEndDate: Date?

    private var monthStartDate: Date?
    private var monthEndDate: Date?


    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - UI
    private let segmentedControl = UISegmentedControl(items: ["Day", "Week", "Month"])

    private let chartCard = UIView()

    // Date header UI
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let valueLabel = UILabel()

    private let statsStack = UIStackView()

    private let minCard = VitalStatView(title: "Minimum", value: "--", color: .systemRed)
    private let maxCard = VitalStatView(title: "Maximum", value: "--", color: .systemGreen)
    private let avgCard = VitalStatView(title: "Average", value: "--", color: .systemYellow)

    private let actionButton = UIButton(type: .system)
    private let heartRateTestValue = UILabel()
    private let countdownLabel = UILabel()

    // MARK: - Data
    private var heartRateValues: [Int] = []
    // Store all day-wise data for week/month
    private var heartRateDayData: [GetRingDataByDayResponse.DayData] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Heart Rate")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)

        setupUI()
        updateDateUI()
        updateActionUI()
        fetchHeartRateData()
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

        // Segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentedControl)
        segmentedControl.addTarget(
            self,
            action: #selector(rangeChanged(_:)),
            for: .valueChanged
        )


        // Chart card
        chartCard.backgroundColor = .white
        chartCard.layer.cornerRadius = 18
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartCard)

        setupDateHeader()

        // Stats stack
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        [minCard, maxCard, avgCard].forEach { statsStack.addArrangedSubview($0) }
        contentView.addSubview(statsStack)

        // Action button
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        actionButton.backgroundColor = .systemRed
        actionButton.layer.cornerRadius = 46
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        contentView.addSubview(actionButton)

        // Heart rate label
        heartRateTestValue.font = .boldSystemFont(ofSize: 24)
        heartRateTestValue.textColor = .white
        heartRateTestValue.textAlignment = .center
        heartRateTestValue.text = "-- times/min"
        heartRateTestValue.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heartRateTestValue)

        // Countdown
        countdownLabel.font = .systemFont(ofSize: 13)
        countdownLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        countdownLabel.textAlignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countdownLabel)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36),
            

            chartCard.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            chartCard.leadingAnchor.constraint(equalTo: segmentedControl.leadingAnchor),
            chartCard.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor),
            chartCard.heightAnchor.constraint(equalToConstant: 220),

            statsStack.topAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor),
            statsStack.heightAnchor.constraint(equalToConstant: 90),

            actionButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 24),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 100),
            actionButton.heightAnchor.constraint(equalToConstant: 100),

            heartRateTestValue.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            heartRateTestValue.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            countdownLabel.topAnchor.constraint(equalTo: heartRateTestValue.bottomAnchor, constant: 6),
            countdownLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countdownLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Date Header
    private func setupDateHeader() {

        prevButton.setTitle("‹", for: .normal)
        prevButton.titleLabel?.font = .boldSystemFont(ofSize: 32)
        prevButton.addTarget(self, action: #selector(prevDateTapped), for: .touchUpInside)

        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .boldSystemFont(ofSize: 32)
        nextButton.addTarget(self, action: #selector(nextDateTapped), for: .touchUpInside)
        
        prevButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        dateLabel.font = .boldSystemFont(ofSize: 16)
        dateLabel.textAlignment = .center

        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .gray
        timeLabel.textAlignment = .center
        timeLabel.text = "--:--"

        valueLabel.font = .systemFont(ofSize: 13)
        valueLabel.textColor = .gray
        valueLabel.textAlignment = .center
        valueLabel.text = "-- times/min"

        [prevButton, nextButton, dateLabel, timeLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            chartCard.addSubview($0)
        }

        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 12),
            dateLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),

            prevButton.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            prevButton.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -12),

            nextButton.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 12),

            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 6),
            timeLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),

            valueLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            valueLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor)
        ])

    }
    
    @objc private func rangeChanged(_ sender: UISegmentedControl) {

        switch sender.selectedSegmentIndex {

        case 0:
            selectedRange = .day

        case 1:
            selectedRange = .week

        case 2:
            selectedRange = .month

        default:
            selectedRange = .day
        }

        // 🔥 Reset base date when switching tabs
        selectedDate = Date()

        // 🔥 Recalculate header + arrows
        updateDateUI()

        // 🔥 Reload data for selected range
        fetchHeartRateData()
    }

    
    private func updateRangeUI() {

        switch selectedRange {

        case .day:
            prevButton.isHidden = false
            nextButton.isHidden = false
            timeLabel.isHidden = false
            valueLabel.isHidden = false

        case .week:
            prevButton.isHidden = false
            nextButton.isHidden = false
            timeLabel.isHidden = true
            valueLabel.text = "-- times/min"

        case .month:
            prevButton.isHidden = false
            nextButton.isHidden = false
            timeLabel.isHidden = true
            valueLabel.text = "-- times/min"
        }
    }
    
    private func updateDateUI() {

        switch selectedRange {

        case .day:
            dateLabel.text = headerFormatter.string(from: selectedDate)
            timeLabel.text = "--:--"
            valueLabel.text = "-- times/min"
            nextButton.isEnabled = !isToday(selectedDate)

        case .week:
            calculateWeekRange(from: selectedDate)

            guard let start = weekStartDate, let end = weekEndDate else { return }

            dateLabel.text =
            "\(headerFormatter.string(from: start)) - \(headerFormatter.string(from: end))"

            timeLabel.text = weekdayFormatter.string(from: start)
            valueLabel.text = "-- times/min"

            nextButton.isEnabled = !isFuture(end)

        case .month:
            calculateMonthRange(from: selectedDate)

            guard let start = monthStartDate, let end = monthEndDate else { return }

            dateLabel.text =
            "\(headerFormatter.string(from: start)) - \(headerFormatter.string(from: end))"

            timeLabel.text = weekdayFormatter.string(from: start)
            valueLabel.text = "-- times/min"

            nextButton.isEnabled = !isFuture(end)
        }

        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.3
    }
    
    @objc private func prevDateTapped() {
        switch selectedRange {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
            fetchHeartRateData()
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
            updateDateUI()
            processHeartRateDayData()
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
            updateDateUI()
            processHeartRateDayData()
        }
        if selectedRange == .day {
            updateDateUI()
        }
    }
    
    @objc private func nextDateTapped() {
        switch selectedRange {
        case .day:
            guard !isToday(selectedDate) else { return }
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate)!
            fetchHeartRateData()
        case .week:
            guard let end = weekEndDate, !isFuture(end) else { return }
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
            updateDateUI()
            processHeartRateDayData()
        case .month:
            guard let end = monthEndDate, !isFuture(end) else { return }
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
            updateDateUI()
            processHeartRateDayData()
        }
        if selectedRange == .day {
            updateDateUI()
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isFuture(_ date: Date) -> Bool {
        date > Date()
    }


//    private func isToday(_ date: Date) -> Bool {
//        Calendar.current.isDateInToday(date)
//    }

    private func selectedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    private func calculateWeekRange(from date: Date) {

        let start = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        )!

        let end = calendar.date(byAdding: .day, value: 6, to: start)!

        weekStartDate = start
        weekEndDate = end
    }
    
    private func calculateMonthRange(from date: Date) {

        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components)!

        let range = calendar.range(of: .day, in: .month, for: start)!
        let end = calendar.date(byAdding: .day, value: range.count - 1, to: start)!

        monthStartDate = start
        monthEndDate = end
    }
    
    
    
    private let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, yyyy-MM-dd"
        return f
    }()
    

    // MARK: - Measurement
    @objc private func actionTapped() {
        isMeasuring ? stopMeasurement() : startMeasurement()
    }

    private func startMeasurement() {
        isMeasuring = true
        remainingSeconds = 60
        updateActionUI()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopMeasurement() {
        isMeasuring = false
        timer?.invalidate()
        timer = nil
        updateActionUI()
    }

    private func tick() {
        remainingSeconds -= 1
        countdownLabel.text = "Remaining \(remainingSeconds) s"
        if remainingSeconds <= 0 { stopMeasurement() }
    }

    private func updateActionUI() {
        actionButton.setTitle(isMeasuring ? "Stop" : "Start", for: .normal)
        countdownLabel.text = isMeasuring ? "Remaining \(remainingSeconds) s" : "Remaining 0 s"
    }

    // MARK: - API

    private func fetchHeartRateData() {
        guard userId > 0 else { return }

        switch selectedRange {
        case .day:
            HealthService.shared.getRingDataByType(
                userId: userId,
                type: "heart_rate",
                selectedDate: selectedDateString()
            ) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if case .success(let response) = result {
                        self.processHeartRateData(response.data)
                    } else {
                        self.resetHeartRateUI()
                    }
                }
            }
        case .week, .month:
            HealthService.shared.getRingDataByDay(
                userId: userId,
                type: "heart_rate"
            ) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if case .success(let response) = result {
                        self.heartRateDayData = response.data
                        self.processHeartRateDayData()
                    } else {
                        self.heartRateDayData = []
                        self.resetHeartRateUI()
                    }
                }
            }
        }
    }

    // Filter and process day-wise data for week/month
    private func processHeartRateDayData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // vDate format

        var startDate: Date?
        var endDate: Date?

        switch selectedRange {
        case .week:
            startDate = weekStartDate
            endDate = weekEndDate
        case .month:
            startDate = monthStartDate
            endDate = monthEndDate
        default:
            return
        }

        guard let start = startDate, let end = endDate else {
            resetHeartRateUI()
            return
        }

        // Filter data within range
        let filtered = heartRateDayData.compactMap { dayData -> Int? in
            guard let date = dateFormatter.date(from: dayData.vDate) else { return nil }
            if date >= start && date <= end {
                return Int(dayData.value)
            }
            return nil
        }

        guard !filtered.isEmpty else {
            resetHeartRateUI()
            return
        }

        minCard.updateValue("\(filtered.min()!)")
        maxCard.updateValue("\(filtered.max()!)")
        avgCard.updateValue("\(filtered.reduce(0, +) / filtered.count)")

        // Show latest (most recent in range)
        if let latest = filtered.last {
            valueLabel.text = "\(latest) times/min"
        }
    }

    private func processHeartRateData(_ data: [GetRingDataByTypeResponse.RingData]) {

        let values = data.compactMap { Int($0.value) }
        guard !values.isEmpty else { resetHeartRateUI(); return }

        minCard.updateValue("\(values.min()!)")
        maxCard.updateValue("\(values.max()!)")
        avgCard.updateValue("\(values.reduce(0, +) / values.count)")

        if let latest = values.first {
            valueLabel.text = "\(latest) times/min"
        }
    }

    private func resetHeartRateUI() {
        minCard.updateValue("--")
        maxCard.updateValue("--")
        avgCard.updateValue("--")
        heartRateTestValue.text = "-- times/min"
        valueLabel.text = "-- times/min"
    }
}

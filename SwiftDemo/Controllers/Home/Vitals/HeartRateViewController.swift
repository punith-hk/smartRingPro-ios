import UIKit
import Charts
import YCProductSDK

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
    private let healthDataChart = LineChartView()

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
    
    // MARK: - BLE Sync
    private var syncHelper: HeartRateSyncHelper?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Heart Rate")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)

        setupUI()
        setupDailyChart()
        updateDateUI()
        updateActionUI()
        
        print("🟡 HeartRateVC - viewDidLoad")
//       fetchHeartRateData() // Removed: Will be called in viewWillAppear after syncHelper is created
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("🟡 HeartRateVC - viewWillAppear")
        
        // Always create syncHelper and fetch from local DB (works offline)
        syncHelper = HeartRateSyncHelper(listener: self)
        fetchHeartRateData() // Load from local DB
        
        // Check if device is connected before running BLE sync logic
        if DeviceSessionManager.shared.isDeviceConnected() {
            print("✅ HeartRateVC - Device connected, syncing from BLE")
            print(BLEStateManager.shared.debugInfo())
            
            // Check initial BLE connection state
            checkInitialBLEConnection()
            
            // Auto-sync heart rate data from ring when tab opens
            syncHelper?.startSync()
            
            // Listen for BLE state changes
            BLEStateManager.shared.onStateChanged = { [weak self] state in
                print("🔵 HeartRateVC received state change: \(state)")
                self?.handleBLEStateChange(state)
            }
        } else {
            print("❌ HeartRateVC - No device connected, showing local data only")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clear the state change listener
        BLEStateManager.shared.onStateChanged = nil
    }

    // MARK: - BLE Connection Check
    private func checkInitialBLEConnection() {
        print("🟡 HeartRateVC - Checking initial BLE connection")
        
        let hasPeripheral = BLEStateManager.shared.hasConnectedDevice()
        let isConnected = BLEStateManager.shared.isConnected
        let currentState = BLEStateManager.shared.currentState
        
        print("  - BLEStateManager current state: \(currentState)")
        print("  - Has peripheral: \(hasPeripheral)")
        print("  - Is connected: \(isConnected)")
        print("  - YCProduct.currentPeripheral: \(YCProduct.shared.currentPeripheral != nil ? "EXISTS" : "NIL")")
        
        if !isConnected {
            print("🔴 Device NOT connected - Showing toast")
            showDeviceNotConnectedToast()
        } else {
            print("✅ Device IS connected")
        }
    }
    
    private func handleBLEStateChange(_ state: YCProductState) {
        print("🟡 HeartRateVC - Handling BLE state change: \(state)")
        
        switch state {
        case .disconnected, .connectedFailed:
            print("❌ Device disconnected/failed - Showing toast")
            showDeviceNotConnectedToast()
        case .connected:
            print("✅ Device connected - Can fetch data")
            // fetchHeartRateData()
        default:
            print("ℹ️ Other BLE state: \(state)")
        }
    }

    private func showDeviceNotConnectedToast() {
        print("🟡 HeartRateVC - Showing device not connected toast")
        Toast.show(message: "Device not connected", in: self.view)
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

        // Setup date header first so labels are in place before chart
        setupDateHeader()

        // Health data chart - sit directly below valueLabel with no gap
        healthDataChart.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(healthDataChart)
        
        NSLayoutConstraint.activate([
            healthDataChart.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: -12),
            healthDataChart.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 6),
            healthDataChart.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -12),
            healthDataChart.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: 0)
        ])

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

            actionButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 60),
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

            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            timeLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),

            valueLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            valueLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor)
        ])

    }
    
    @objc private func rangeChanged(_ sender: UISegmentedControl) {

        switch sender.selectedSegmentIndex {

        case 0:
            selectedRange = .day
            resetChartForDailyView()

        case 1:
            selectedRange = .week

        case 2:
            selectedRange = .month

        default:
            selectedRange = .day
            resetChartForDailyView()
        }

        // 🔥 Reset base date when switching tabs
        selectedDate = Date()

        // 🔥 Recalculate header + arrows
        updateDateUI()

        // 🔥 Reload data for selected range
        fetchHeartRateData()
    }

    // MARK: - Chart Setup
    private func setupDailyChart() {
        healthDataChart.chartDescription.enabled = false
        healthDataChart.dragEnabled = true
        healthDataChart.setScaleEnabled(true)
        healthDataChart.pinchZoomEnabled = true
        healthDataChart.scaleXEnabled = true
        healthDataChart.scaleYEnabled = false

        healthDataChart.leftAxis.drawGridLinesEnabled = false
        healthDataChart.rightAxis.drawGridLinesEnabled = false
        healthDataChart.xAxis.drawGridLinesEnabled = false
        healthDataChart.leftAxis.drawAxisLineEnabled = false

        healthDataChart.dragDecelerationEnabled = true
        healthDataChart.dragDecelerationFrictionCoef = 0.9

        // Add value selection listener
        healthDataChart.delegate = self

        // Configure X-axis
        let xAxis = healthDataChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.granularity = 1.0
        xAxis.labelCount = 5

        xAxis.axisMinimum = 0
        xAxis.axisMaximum = 24

        xAxis.valueFormatter = TimeValueFormatter()

        // Set visible range based on selected range
        switch selectedRange {
        case .day:
            healthDataChart.setVisibleXRangeMaximum(5)
        case .week:
            healthDataChart.setVisibleXRangeMaximum(7)
        case .month:
            healthDataChart.setVisibleXRangeMaximum(10)
        }

        // Configure Y-axis
        let leftAxis = healthDataChart.leftAxis
        leftAxis.axisMinimum = 0

        healthDataChart.rightAxis.enabled = false
    }

    private func resetChartForDailyView() {
        // Reset X-axis to daily format (time labels)
        let xAxis = healthDataChart.xAxis
        xAxis.valueFormatter = TimeValueFormatter()
        xAxis.granularity = 1.0
        xAxis.labelCount = 5
        xAxis.axisMinimum = 0
        xAxis.axisMaximum = 24
        
        // Reset visible range for daily view
        healthDataChart.setVisibleXRangeMaximum(5)
        
        // Enable zoom/drag
        healthDataChart.dragEnabled = true
        healthDataChart.setScaleEnabled(true)
        healthDataChart.pinchZoomEnabled = true
        healthDataChart.scaleXEnabled = true
        healthDataChart.scaleYEnabled = false
    }

    private func updateXAxisLabels() {
        let xAxis = healthDataChart.xAxis
        let visibleRange = healthDataChart.highestVisibleX - healthDataChart.lowestVisibleX

        if visibleRange > 6 {
            xAxis.granularity = 1.0
        } else {
            xAxis.granularity = 0.5
        }

        healthDataChart.setNeedsDisplay()
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
    // Track whether stop was requested by user (vs timer completion)
    private var isUserRequestedStop = false

    @objc private func actionTapped() {
        if isMeasuring {
            // ask for confirmation before stopping
            presentStopConfirmation()
        } else {
            startMeasurement()
        }
    }

    private func startMeasurement() {
        // Check device connection using centralized manager
        let connected = BLEStateManager.shared.hasConnectedDevice() || BLEStateManager.shared.isConnected
        if !connected {
            print("🔴 Start requested but device not connected")
            Toast.show(message: "Device not connected", in: self.view)
            return
        }

        print("🟢 Starting measurement")
        Toast.show(message: "Starting test", in: self.view)

        isMeasuring = true
        isUserRequestedStop = false
        remainingSeconds = 60
        updateActionUI()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopMeasurement() {
        // stopping measurement (either by user confirmation or timer completion)
        isMeasuring = false
        timer?.invalidate()
        timer = nil
        updateActionUI()

        if isUserRequestedStop {
            print("🟡 User stopped the test")
            Toast.show(message: "Test stopped", in: self.view)
        } else if remainingSeconds <= 0 {
            print("✅ Test completed (60s)")
            Toast.show(message: "Test completed", in: self.view)
        }

        // reset the user stop flag
        isUserRequestedStop = false
    }

    private func tick() {
        remainingSeconds -= 1
        countdownLabel.text = "Remaining \(remainingSeconds) s"
        if remainingSeconds <= 0 {
            // timer finished naturally -> treat as completion
            stopMeasurement()
        }
    }

    private func updateActionUI() {
        actionButton.setTitle(isMeasuring ? "Stop" : "Start", for: .normal)
        countdownLabel.text = isMeasuring ? "Remaining \(remainingSeconds) s" : "Remaining 0 s"
    }

    private func presentStopConfirmation() {
        let alert = UIAlertController(title: "Stop Test", message: "Are you sure you want to stop the test?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Stop", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.isUserRequestedStop = true
            self.stopMeasurement()
        }))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - API

    private func fetchHeartRateData() {
        guard userId > 0 else { return }

        switch selectedRange {
        case .day:
            // 🔄 NEW: Fetch from local database instead of API
            print("📱 Fetching heart rate data for day from LOCAL DB")
            syncHelper?.fetchDataForDate(userId: userId, date: selectedDate)
            
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

        // Filter data within range and keep date/value pairs
        let filteredPairs = heartRateDayData.compactMap { dayData -> (Date, Int)? in
            guard let date = dateFormatter.date(from: dayData.vDate), let val = Int(dayData.value) else { return nil }
            if date >= start && date <= end {
                return (date, val)
            }
            return nil
        }
        let filtered = filteredPairs.map { $0.1 }

        guard !filtered.isEmpty else {
            resetHeartRateUI()
            return
        }

        minCard.updateValue("\(filtered.min()!)")
        maxCard.updateValue("\(filtered.max()!)")
        avgCard.updateValue("\(filtered.reduce(0, +) / filtered.count)")

        // Show latest (most recent in range)
        if let latestPair = filteredPairs.sorted(by: { $0.0 < $1.0 }).last {
            let latestDate = latestPair.0
            let latestValue = latestPair.1
            timeLabel.text = weekdayFormatter.string(from: latestDate)
            valueLabel.text = "\(latestValue) times/min"
        }

        // Populate chart with week/month data
        populateWeekMonthChart()
    }
    private func processHeartRateData(_ data: [GetRingDataByTypeResponse.RingData]) {

        let values = data.compactMap { Int($0.value) }
        guard !values.isEmpty else { resetHeartRateUI(); return }

        minCard.updateValue("\(values.min()!)")
        maxCard.updateValue("\(values.max()!)")
        avgCard.updateValue("\(values.reduce(0, +) / values.count)")

        if let latest = data.first, let latestValue = Int(latest.value) {
            valueLabel.text = "\(latestValue) times/min"

            // Show time for latest entry
            let ts = TimeInterval(latest.timestamp)
            let date = Date(timeIntervalSince1970: ts)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeLabel.text = timeFormatter.string(from: date)
        }
        
        // Populate chart with day data
        populateDailyChart(data)
    }

    // MARK: - Chart Population
    private func populateDailyChart(_ data: [GetRingDataByTypeResponse.RingData]) {
        var entries: [ChartDataEntry] = []

        data.forEach { healthData in
            let timestamp = Int(healthData.timestamp)
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            
            let hour = Float(components.hour ?? 0)
            let minute = Float(components.minute ?? 0)
            let hourFraction = hour + (minute / 60.0)
            
            if let value = Float(healthData.value) {
                entries.append(ChartDataEntry(x: Double(hourFraction), y: Double(value)))
            }
        }

        let sortedEntries = entries.sorted { $0.x < $1.x }
        
        guard !sortedEntries.isEmpty else {
            healthDataChart.data = nil
            healthDataChart.setNeedsDisplay()
            return
        }

        // Create line dataset
        let dataSet = LineChartDataSet(entries: sortedEntries, label: "Heart Rate")
        dataSet.drawValuesEnabled = false
        dataSet.setColor(.systemRed)
        dataSet.setCircleColor(.systemBlue)
        dataSet.circleRadius = 4

        // Set Y-axis maximum
        if let maxValue = sortedEntries.map({ $0.y }).max() {
            healthDataChart.leftAxis.axisMaximum = maxValue + 30
        }

        // Create line data and set to chart
        let lineData = LineChartData(dataSets: [dataSet])
        healthDataChart.data = lineData

        // Move to latest data point
        if let lastEntry = sortedEntries.last {
            healthDataChart.moveViewToX(lastEntry.x)
        }

        healthDataChart.xAxis.axisMaximum = (sortedEntries.last?.x ?? 0) + 1
        healthDataChart.setNeedsDisplay()
    }

    private func populateWeekMonthChart() {
        var entries: [ChartDataEntry] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var dayCount = 0
        var dayLabels: [String] = []

        switch selectedRange {
        case .week:
            guard let startDate = weekStartDate else { return }
            let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
            let calendar = Calendar.current
            
            for i in 0..<7 {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                let dateString = dateFormatter.string(from: currentDate)
                
                // Find data for this date
                if let dayData = heartRateDayData.first(where: { $0.vDate == dateString }) {
                    if let value = Float(dayData.value) {
                        entries.append(ChartDataEntry(x: Double(i), y: Double(value)))
                    }
                }
                
                // Add day label
                let weekdayComponent = calendar.component(.weekday, from: currentDate)
                dayLabels.append(weekDays[(weekdayComponent + 5) % 7])
            }
            
            // Configure X-axis for week
            let xAxis = healthDataChart.xAxis
            xAxis.valueFormatter = WeekValueFormatter(dayLabels: dayLabels)
            xAxis.granularity = 1.0
            xAxis.labelCount = 7
            xAxis.axisMinimum = -0.5
            xAxis.axisMaximum = 6.5
            
            // Enable dragging and zooming for week chart (only horizontal zoom)
            healthDataChart.dragEnabled = true
            healthDataChart.setScaleEnabled(true)
            healthDataChart.pinchZoomEnabled = true
            healthDataChart.scaleXEnabled = true
            healthDataChart.scaleYEnabled = false
            
            // Set visible range to show all 7 days at once
            healthDataChart.setVisibleXRangeMaximum(7.5)
            healthDataChart.fitScreen()

        case .month:
            guard let startDate = monthStartDate else { return }
            let calendar = Calendar.current
            let range = calendar.range(of: .day, in: .month, for: startDate)!
            let daysInMonth = range.count
            
            for i in 0..<daysInMonth {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                let dateString = dateFormatter.string(from: currentDate)
                
                // Find data for this date
                if let dayData = heartRateDayData.first(where: { $0.vDate == dateString }) {
                    if let value = Float(dayData.value) {
                        entries.append(ChartDataEntry(x: Double(i), y: Double(value)))
                    }
                }
            }
            
            // Configure X-axis for month
            let xAxis = healthDataChart.xAxis
            xAxis.valueFormatter = MonthValueFormatter(daysInMonth: daysInMonth)
            xAxis.granularity = 1.0
            xAxis.labelCount = min(6, daysInMonth)
            xAxis.axisMinimum = 0
            xAxis.axisMaximum = Double(daysInMonth - 1)
            // Ensure only horizontal scaling
            healthDataChart.dragEnabled = true
            healthDataChart.setScaleEnabled(true)
            healthDataChart.pinchZoomEnabled = true
            healthDataChart.scaleXEnabled = true
            healthDataChart.scaleYEnabled = false

        default:
            return
        }

        guard !entries.isEmpty else {
            healthDataChart.data = nil
            healthDataChart.setNeedsDisplay()
            return
        }

        // Create line dataset
        let dataSet = LineChartDataSet(entries: entries, label: "Heart Rate")
        dataSet.drawValuesEnabled = false
        dataSet.setColor(.systemRed)
        dataSet.setCircleColor(.systemBlue)
        dataSet.circleRadius = 4

        // Set Y-axis maximum
        if let maxValue = entries.map({ $0.y }).max() {
            healthDataChart.leftAxis.axisMaximum = maxValue + 30
        }

        // Create line data and set to chart
        let lineData = LineChartData(dataSets: [dataSet])
        healthDataChart.data = lineData
        
        // Move to latest data point (focused on last entry)
        if let lastEntry = entries.last {
            healthDataChart.moveViewToX(lastEntry.x)
        }
        
        healthDataChart.setNeedsDisplay()
    }

    private func resetHeartRateUI() {
        minCard.updateValue("--")
        maxCard.updateValue("--")
        avgCard.updateValue("--")
        heartRateTestValue.text = "-- times/min"
        valueLabel.text = "-- times/min"
        timeLabel.text = "--:--"
        // Clear chart data when there is no data to display
        healthDataChart.data = nil
        healthDataChart.setNeedsDisplay()
    }
}

// MARK: - ChartViewDelegate
extension HeartRateViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let heartRate = Int(entry.y)

        switch selectedRange {
        case .day:
            let hour = Int(entry.x)
            let minute = Int((entry.x - Double(hour)) * 60)
            let timeFormatted = String(format: "%02d:%02d", hour, minute)
            timeLabel.text = timeFormatted
            valueLabel.text = "\(heartRate) times/min"

        case .week:
            guard let start = weekStartDate else { return }
            let index = Int(round(entry.x))
            if let date = calendar.date(byAdding: .day, value: index, to: start) {
                timeLabel.text = weekdayFormatter.string(from: date)
                valueLabel.text = "\(heartRate) times/min"
            }

        case .month:
            guard let start = monthStartDate else { return }
            let index = Int(round(entry.x))
            if let date = calendar.date(byAdding: .day, value: index, to: start) {
                timeLabel.text = weekdayFormatter.string(from: date)
                valueLabel.text = "\(heartRate) times/min"
            }
        }
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Handle when nothing is selected
    }
}

// MARK: - TimeValueFormatter
class TimeValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let hour = Int(value)
        let minute = Int((value - Double(hour)) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - WeekValueFormatter
class WeekValueFormatter: AxisValueFormatter {
    let dayLabels: [String]
    
    init(dayLabels: [String]) {
        self.dayLabels = dayLabels
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard index >= 0 && index < dayLabels.count else { return "" }
        return dayLabels[index]
    }
}

// MARK: - MonthValueFormatter
class MonthValueFormatter: AxisValueFormatter {
    let daysInMonth: Int
    
    init(daysInMonth: Int) {
        self.daysInMonth = daysInMonth
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let day = Int(value) + 1
        return String(day)
    }
}

// MARK: - Heart Rate Sync
extension HeartRateViewController: HeartRateSyncHelper.HeartRateSyncListener {
    func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate]) {
        print("✅ HeartRateVC - Received \(data.count) heart rate entries from ring and saved to DB")
        
        // 🔄 Reload graph with updated local DB data (from BLE sync only)
        print("🔄 HeartRateVC - Reloading graph with fresh data from local DB")
        fetchHeartRateData()
    }
    
    func onSyncFailed(error: String) {
        print("❌ HeartRateVC - Sync failed: \(error)")
    }
    
    func onLocalDataFetched(_ data: [(timestamp: Int64, bpm: Int)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📊 HeartRateVC - Received \(data.count) entries from local DB")
            
            // Convert local DB format to API format for chart compatibility
            let chartData: [GetRingDataByTypeResponse.RingData] = data.map { item in
                GetRingDataByTypeResponse.RingData(
                    id: 0,
                    user_id: 0,
                    type: "heart_rate",
                    value: String(item.bpm),
                    timestamp: Int(item.timestamp),
                    created_at: "",
                    updated_at: ""
                )
            }
            
            // Use existing processHeartRateData method
            if !chartData.isEmpty {
                self.processHeartRateData(chartData)
            } else {
                print("ℹ️ No data found for selected date in local DB")
                self.resetHeartRateUI()
            }
        }
    }
}

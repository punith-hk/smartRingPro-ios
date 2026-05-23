import UIKit
import Charts
import YCProductSDK

final class HeartRateViewController: AppBaseViewController {

    private let userId = UserDefaultsManager.shared.userId

    // MARK: - Reusable Chart
    private lazy var chartView: VitalChartView = {
        let chart = VitalChartView(vitalType: .heartRate)
        chart.dataSource = self
        chart.delegate = self
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()

    // MARK: - State
    private var isMeasuring = false
    private var remainingSeconds = 60
    private var timer: Timer?

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - UI
    private let statsStack = UIStackView()

    private let minCard = VitalStatView(title: "Minimum", value: "--", color: .systemRed)
    private let maxCard = VitalStatView(title: "Maximum", value: "--", color: .systemGreen)
    private let avgCard = VitalStatView(title: "Average", value: "--", color: .systemYellow)

    private let actionButton     = UIButton(type: .system)
    private let actionContainer   = UIView()
    private let progressFill      = UIView()
    private let countdownLabel    = UILabel()
    private var progressFillWidth: NSLayoutConstraint?

    // MARK: - Data
    private var heartRateDayData: [GetRingDataByDayResponse.DayData] = []
    
    // MARK: - BLE Sync
    private var syncHelper: HeartRateSyncHelper?
    private var dailySyncHelper: HeartRateDailySyncHelper?
    
    // Store completion for day view
    private var dayDataCompletion: (([VitalDataPoint]) -> Void)?
    private var weekMonthDataCompletion: (([VitalDataPoint]) -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Heart Rate")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

        setupUI()
        updateActionUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Always create syncHelper
        syncHelper = HeartRateSyncHelper(listener: self)
        dailySyncHelper = HeartRateDailySyncHelper(listener: self)
        
        // Sync daily data once on launch (updates local DB from API)
        if userId > 0 {
            dailySyncHelper?.fetchDailyData(userId: userId) { _ in
                // Data synced to local DB, will be used for week/month views
            }
        }
        
        chartView.reloadData()
        
        // Check if device is connected
        if DeviceSessionManager.shared.isDeviceConnected() {
            checkInitialBLEConnection()
            syncHelper?.startSync()
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

        // Chart view (replaces segmented control + chart card + date header)
        contentView.addSubview(chartView)

        // Stats stack
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        [minCard, maxCard, avgCard].forEach { statsStack.addArrangedSubview($0) }
        contentView.addSubview(statsStack)

        // Heart rate value label
        let heartRateTestValue = UILabel()
        heartRateTestValue.font = .boldSystemFont(ofSize: 24)
        heartRateTestValue.textColor = UIColor(white: 0.10, alpha: 1)
        heartRateTestValue.textAlignment = .center
        heartRateTestValue.text = "-- times/min"
        heartRateTestValue.tag = 1002
        heartRateTestValue.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heartRateTestValue)

        // Shadow container
        actionContainer.backgroundColor = .white
        actionContainer.layer.cornerRadius = 12
        actionContainer.layer.shadowColor = UIColor.black.cgColor
        actionContainer.layer.shadowOpacity = 0.1
        actionContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        actionContainer.layer.shadowRadius = 4
        actionContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionContainer)

        // Pill container
        actionButton.backgroundColor = .systemRed
        actionButton.layer.cornerRadius = 12
        actionButton.layer.masksToBounds = true
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionContainer.addSubview(actionButton)

        // Progress fill
        progressFill.backgroundColor = UIColor(white: 0, alpha: 0.18)
        progressFill.isUserInteractionEnabled = false
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        actionButton.insertSubview(progressFill, at: 0)

        // "Start" / "Stop" title label
        let titleLabel = UILabel()
        titleLabel.text = "Start Live Test"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.tag = 1001
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addSubview(titleLabel)

        // Countdown label — right side
        countdownLabel.font = .boldSystemFont(ofSize: 16)
        countdownLabel.textColor = .white
        countdownLabel.textAlignment = .right
        countdownLabel.isHidden = true
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addSubview(countdownLabel)

        progressFillWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)
        progressFillWidth?.isActive = true

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            statsStack.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            statsStack.heightAnchor.constraint(equalToConstant: 90),

            actionContainer.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 32),
            actionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionContainer.heightAnchor.constraint(equalToConstant: 50),

            actionButton.topAnchor.constraint(equalTo: actionContainer.topAnchor),
            actionButton.leadingAnchor.constraint(equalTo: actionContainer.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            actionButton.bottomAnchor.constraint(equalTo: actionContainer.bottomAnchor),

            progressFill.topAnchor.constraint(equalTo: actionButton.topAnchor),
            progressFill.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor),
            progressFill.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),

            countdownLabel.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            countdownLabel.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: -16),

            heartRateTestValue.topAnchor.constraint(equalTo: actionContainer.bottomAnchor, constant: 20),
            heartRateTestValue.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            heartRateTestValue.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

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
        let elapsed = 60 - remainingSeconds
        let progress = Double(elapsed) / 60.0
        countdownLabel.text = "\(remainingSeconds)s"
        let totalWidth = actionButton.bounds.width
        if totalWidth > 0 {
            progressFillWidth?.constant = totalWidth * CGFloat(progress)
            UIView.animate(withDuration: 0.9, delay: 0, options: .curveLinear) {
                self.actionButton.layoutIfNeeded()
            }
        }
        if remainingSeconds <= 0 {
            stopMeasurement()
        }
    }

    private func updateActionUI() {
        let titleLabel = actionButton.viewWithTag(1001) as? UILabel
        if isMeasuring {
            titleLabel?.text = "Stop Live Test"
            countdownLabel.text = "\(remainingSeconds)s"
            countdownLabel.isHidden = false
            progressFillWidth?.constant = 0
        } else {
            titleLabel?.text = "Start Live Test"
            countdownLabel.isHidden = true
            progressFillWidth?.constant = 0
            actionButton.layoutIfNeeded()
        }
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
}

// MARK: - VitalChartDataSource
extension HeartRateViewController: VitalChartDataSource {
    func fetchChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        guard userId > 0 else {
            completion([])
            return
        }
        
        switch range {
        case .day:
            // Store completion for later
            dayDataCompletion = completion
            syncHelper?.fetchDataForDate(userId: userId, date: date)
            
        case .week, .month:
            // Query local DB for the selected date range (no API call)
            dailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                completion(dataPoints)
                self?.updateStats(with: dataPoints)
            }
        }
    }
    
    private func convertToDataPoints(_ data: [GetRingDataByDayResponse.DayData]) -> [VitalDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return data.compactMap { dayData -> VitalDataPoint? in
            guard let date = dateFormatter.date(from: dayData.vDate),
                  let value = Double(dayData.value) else { return nil }
            
            return VitalDataPoint(
                timestamp: Int64(date.timeIntervalSince1970),
                value: value
            )
        }
    }
    
    private func updateStats(with dataPoints: [VitalDataPoint]) {
        guard !dataPoints.isEmpty else {
            resetStats()
            return
        }
        
        let values = dataPoints.map { Int($0.value) }
        minCard.updateValue("\(values.min()!)")
        maxCard.updateValue("\(values.max()!)")
        avgCard.updateValue("\(values.reduce(0, +) / values.count)")
    }
    
    private func resetStats() {
        minCard.updateValue("--")
        maxCard.updateValue("--")
        avgCard.updateValue("--")
    }
}

// MARK: - VitalChartDelegate
extension HeartRateViewController: VitalChartDelegate {
    func chartShouldUpdateLabels(time: String, value: String) {
        // Labels are now internal to VitalChartView, no action needed
        // This delegate method can be used for other purposes if needed
    }
}

// MARK: - Heart Rate Sync
extension HeartRateViewController: HeartRateSyncHelper.HeartRateSyncListener {
    func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate]) {
        print("✅ Received \(data.count) heart rate entries from ring")
        chartView.reloadData()
    }
    
    func onSyncFailed(error: String) {
        print("❌ Sync failed: \(error)")
    }
    
    func onLocalDataFetched(_ data: [(timestamp: Int64, bpm: Int)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let dataPoints = data.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.bpm)) }
            
            // Update stats
            self.updateStats(with: dataPoints)
            
            // Call chart completion
            self.dayDataCompletion?(dataPoints)
            self.dayDataCompletion = nil
        }
    }
}

// MARK: - Daily Stats Sync
extension HeartRateViewController: HeartRateDailySyncHelper.HeartRateDailySyncListener {
    func onLocalDailyDataFetched(_ data: [VitalDataPoint]) {
        print("📊 Loaded \(data.count) daily entries from local DB")
        // Data already sent via completion in fetchDailyData
    }
    
    func onAPIDailyDataFetched(_ data: [VitalDataPoint]) {
        print("🔄 Received \(data.count) updated daily entries from API")
        
        // API sync completed - local DB is now up to date
        // Reload chart if currently viewing week/month tab
        DispatchQueue.main.async { [weak self] in
            self?.chartView.reloadData()
        }
    }
    
    func onDailySyncFailed(error: String) {
        print("❌ Daily sync failed: \(error)")
    }
}

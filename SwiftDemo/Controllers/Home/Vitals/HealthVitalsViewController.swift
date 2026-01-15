import UIKit
import Charts
import YCProductSDK

/// Generic Health Vitals ViewController
/// Supports: HRV, Temperature, Blood Glucose, Blood Oxygen, etc.
/// Usage: HealthVitalsViewController(vitalType: .hrv)
final class HealthVitalsViewController: AppBaseViewController {

    // MARK: - Properties
    private let vitalType: VitalType
    private let userId = UserDefaultsManager.shared.userId

    // MARK: - Reusable Chart
    private lazy var chartView: VitalChartView = {
        let chart = VitalChartView(vitalType: vitalType)
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

    private lazy var minCard = VitalStatView(title: "Minimum", value: "--", color: .systemRed)
    private lazy var maxCard = VitalStatView(title: "Maximum", value: "--", color: .systemGreen)
    private lazy var avgCard = VitalStatView(title: "Average", value: "--", color: .systemYellow)

    private let actionButton = UIButton(type: .system)
    private lazy var measurementValueLabel = UILabel()
    private let countdownLabel = UILabel()

    // MARK: - Sync Helpers
    private var heartRateSyncHelper: HeartRateSyncHelper?
    private var heartRateDailySyncHelper: HeartRateDailySyncHelper?
    
    // Store completion for day view
    private var dayDataCompletion: (([VitalDataPoint]) -> Void)?
    private var weekMonthDataCompletion: (([VitalDataPoint]) -> Void)?

    // MARK: - Initialization
    init(vitalType: VitalType) {
        self.vitalType = vitalType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle(vitalType.displayName)
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)

        setupUI()
        updateActionUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: Create sync helpers based on vitalType
        // This will be implemented when we add specific sync helpers
        setupSyncHelpers()
        
        chartView.reloadData()
        
        // Check if device is connected
        if DeviceSessionManager.shared.isDeviceConnected() {
            checkInitialBLEConnection()
            startBLESync()
            
            // Listen for BLE state changes
            BLEStateManager.shared.onStateChanged = { [weak self] state in
                print("🔵 \(self?.vitalType.displayName ?? "Vitals")VC received state change: \(state)")
                self?.handleBLEStateChange(state)
            }
        } else {
            print("❌ \(vitalType.displayName)VC - No device connected, showing local data only")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clear the state change listener
        BLEStateManager.shared.onStateChanged = nil
    }
    
    // MARK: - Sync Helper Setup
    private func setupSyncHelpers() {
        print("📊 Setting up sync helpers for \(vitalType.displayName)")
        
        switch vitalType {
        case .heartRate:
            heartRateSyncHelper = HeartRateSyncHelper(listener: self)
            heartRateDailySyncHelper = HeartRateDailySyncHelper(listener: self)
            
            // Sync daily data once on launch (updates local DB from API)
            if userId > 0 {
                heartRateDailySyncHelper?.fetchDailyData(userId: userId) { _ in
                    // Data synced to local DB, will be used for week/month views
                }
            }
            
        case .hrv, .temperature, .bloodGlucose, .bloodOxygen:
            // TODO: Implement combined data sync helpers
            print("⚠️ Sync helpers not yet implemented for \(vitalType.displayName)")
        }
    }
    
    private func startBLESync() {
        print("🔄 Starting BLE sync for \(vitalType.displayName)")
        
        switch vitalType {
        case .heartRate:
            heartRateSyncHelper?.startSync()
            
        case .hrv, .temperature, .bloodGlucose, .bloodOxygen:
            // TODO: Start combined data sync
            print("⚠️ BLE sync not yet implemented for \(vitalType.displayName)")
        }
    }

    // MARK: - BLE Connection Check
    private func checkInitialBLEConnection() {
        print("🟡 \(vitalType.displayName)VC - Checking initial BLE connection")
        
        let hasPeripheral = BLEStateManager.shared.hasConnectedDevice()
        let isConnected = BLEStateManager.shared.isConnected
        let currentState = BLEStateManager.shared.currentState
        
        print("  - BLEStateManager current state: \(currentState)")
        print("  - Has peripheral: \(hasPeripheral)")
        print("  - Is connected: \(isConnected)")
        
        if !isConnected {
            print("🔴 Device NOT connected - Showing toast")
            showDeviceNotConnectedToast()
        } else {
            print("✅ Device IS connected")
        }
    }
    
    private func handleBLEStateChange(_ state: YCProductState) {
        print("🟡 \(vitalType.displayName)VC - Handling BLE state change: \(state)")
        
        switch state {
        case .disconnected, .connectedFailed:
            print("❌ Device disconnected/failed - Showing toast")
            showDeviceNotConnectedToast()
        case .connected:
            print("✅ Device connected - Can fetch data")
        default:
            print("ℹ️ Other BLE state: \(state)")
        }
    }

    private func showDeviceNotConnectedToast() {
        print("🟡 \(vitalType.displayName)VC - Showing device not connected toast")
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

        // Chart view
        contentView.addSubview(chartView)

        // Stats stack
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        [minCard, maxCard, avgCard].forEach { statsStack.addArrangedSubview($0) }
        contentView.addSubview(statsStack)

        // Measurement controls (show/hide based on vital type)
        if shouldShowMeasurementControls() {
            setupMeasurementControls()
        } else {
            // If no measurement controls, anchor stats to chart
            NSLayoutConstraint.activate([
                chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

                statsStack.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
                statsStack.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
                statsStack.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
                statsStack.heightAnchor.constraint(equalToConstant: 90),
                statsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
            ])
        }
    }
    
    private func setupMeasurementControls() {
        // Action button
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        actionButton.backgroundColor = vitalType.color
        actionButton.layer.cornerRadius = 46
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        contentView.addSubview(actionButton)

        // Measurement value label
        measurementValueLabel.font = .boldSystemFont(ofSize: 24)
        measurementValueLabel.textColor = .white
        measurementValueLabel.textAlignment = .center
        measurementValueLabel.text = "-- \(vitalType.unit)"
        measurementValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(measurementValueLabel)

        // Countdown
        countdownLabel.font = .systemFont(ofSize: 13)
        countdownLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        countdownLabel.textAlignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countdownLabel)

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            statsStack.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            statsStack.heightAnchor.constraint(equalToConstant: 90),

            actionButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 60),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 100),
            actionButton.heightAnchor.constraint(equalToConstant: 100),

            measurementValueLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            measurementValueLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            countdownLabel.topAnchor.constraint(equalTo: measurementValueLabel.bottomAnchor, constant: 6),
            countdownLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countdownLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func shouldShowMeasurementControls() -> Bool {
        // TODO: Define which vitals support measurement
        // For now, return false (no measurement controls)
        // Can be customized later: return vitalType == .heartRate || vitalType == .bloodPressure
        return false
    }

    // MARK: - Measurement (Optional - only if shouldShowMeasurementControls)
    private var isUserRequestedStop = false

    @objc private func actionTapped() {
        if isMeasuring {
            presentStopConfirmation()
        } else {
            startMeasurement()
        }
    }

    private func startMeasurement() {
        let connected = BLEStateManager.shared.hasConnectedDevice() || BLEStateManager.shared.isConnected
        if !connected {
            print("🔴 Start requested but device not connected")
            Toast.show(message: "Device not connected", in: self.view)
            return
        }

        print("🟢 Starting \(vitalType.displayName) measurement")
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

        isUserRequestedStop = false
    }

    private func tick() {
        remainingSeconds -= 1
        countdownLabel.text = "Remaining \(remainingSeconds) s"
        if remainingSeconds <= 0 {
            stopMeasurement()
        }
    }

    private func updateActionUI() {
        actionButton.setTitle(isMeasuring ? "Stop" : "Start", for: .normal)
        countdownLabel.text = isMeasuring ? "Remaining \(remainingSeconds) s" : "Remaining 0 s"
    }

    private func presentStopConfirmation() {
        let alert = UIAlertController(
            title: "Stop Test",
            message: "Are you sure you want to stop the test?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Stop", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.isUserRequestedStop = true
            self.stopMeasurement()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Stats Update
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

// MARK: - VitalChartDataSource
extension HealthVitalsViewController: VitalChartDataSource {
    func fetchChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        guard userId > 0 else {
            completion([])
            return
        }
        
        print("📊 Fetching \(vitalType.displayName) data for \(range)")
        
        switch vitalType {
        case .heartRate:
            switch range {
            case .day:
                // Store completion for later
                dayDataCompletion = completion
                heartRateSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                // Query local DB for the selected date range (no API call)
                heartRateDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                    completion(dataPoints)
                    self?.updateStats(with: dataPoints)
                }
            }
            
        case .hrv, .temperature, .bloodGlucose, .bloodOxygen:
            // TODO: Implement combined data fetching
            print("⚠️ Data fetching not yet implemented for \(vitalType.displayName)")
            completion([])
        }
    }
}

// MARK: - VitalChartDelegate
extension HealthVitalsViewController: VitalChartDelegate {
    func chartShouldUpdateLabels(time: String, value: String) {
        // Labels are now internal to VitalChartView, no action needed
        // This delegate method can be used for other purposes if needed
    }
}

// MARK: - Heart Rate Sync Listeners
extension HealthVitalsViewController: HeartRateSyncHelper.HeartRateSyncListener {
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

// MARK: - Heart Rate Daily Stats Sync
extension HealthVitalsViewController: HeartRateDailySyncHelper.HeartRateDailySyncListener {
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

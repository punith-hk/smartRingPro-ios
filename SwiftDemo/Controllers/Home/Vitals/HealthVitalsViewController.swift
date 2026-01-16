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
    
    // Blood Pressure uses a custom dual-line chart
    private lazy var bpChartView: BloodPressureDualLineChartView = {
        let chart = BloodPressureDualLineChartView()
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
    
    // Blood Pressure specific stat cards
    private lazy var systolicCard = VitalStatView(title: "Mean Systolic BP", value: "--", color: .systemIndigo, titleFont: .boldSystemFont(ofSize: 14))
    private lazy var diastolicCard = VitalStatView(title: "Mean Diastolic BP", value: "--", color: .systemRed, titleFont: .boldSystemFont(ofSize: 14))

    private let actionButton = UIButton(type: .system)
    private lazy var measurementValueLabel = UILabel()
    private let countdownLabel = UILabel()

    // MARK: - Sync Helpers
    private var heartRateSyncHelper: HeartRateSyncHelper?
    private var heartRateDailySyncHelper: HeartRateDailySyncHelper?
    
    // Blood Pressure sync helper (separate query like heart rate)
    private var bloodPressureSyncHelper: BloodPressureSyncHelper?
    private var bloodPressureDailySyncHelper: BloodPressureDailySyncHelper?
    
    // Combined data sync helper (for HRV, Temperature, Blood Glucose, Blood Oxygen)
    private var combinedDataSyncHelper: CombinedDataSyncHelper?
    
    // Daily sync helpers for each vital
    private var hrvDailySyncHelper: HRVDailySyncHelper?
    private var bloodOxygenDailySyncHelper: BloodOxygenDailySyncHelper?
    private var bloodGlucoseDailySyncHelper: BloodGlucoseDailySyncHelper?
    private var temperatureDailySyncHelper: TemperatureDailySyncHelper?
    
    // Store completion for day view
    private var dayDataCompletion: (([VitalDataPoint]) -> Void)?
    private var weekMonthDataCompletion: (([VitalDataPoint]) -> Void)?
    
    // Store BP data for dual-line chart and value display
    private var currentBPData: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)] = []

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
        
        // Load initial data from local DB
        if vitalType == .bloodPressure {
            // BP fetches data and updates stats manually
            if userId > 0 {
                bloodPressureSyncHelper?.fetchDataForDate(userId: userId, date: Date())
            }
        }
        
        // All vitals use chartView (including BP now)
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
            
        case .bloodPressure:
            bloodPressureSyncHelper = BloodPressureSyncHelper(listener: self)
            bloodPressureDailySyncHelper = BloodPressureDailySyncHelper(listener: self)
            
            if userId > 0 {
                bloodPressureDailySyncHelper?.fetchDailyData(userId: userId) { _, _ in }
            }
            
        case .hrv:
            combinedDataSyncHelper = CombinedDataSyncHelper(listener: self)
            hrvDailySyncHelper = HRVDailySyncHelper(listener: self)
            
            if userId > 0 {
                hrvDailySyncHelper?.fetchDailyData(userId: userId) { _ in }
            }
            
        case .bloodOxygen:
            combinedDataSyncHelper = CombinedDataSyncHelper(listener: self)
            bloodOxygenDailySyncHelper = BloodOxygenDailySyncHelper(listener: self)
            
            if userId > 0 {
                bloodOxygenDailySyncHelper?.fetchDailyData(userId: userId) { _ in }
            }
            
        case .bloodGlucose:
            combinedDataSyncHelper = CombinedDataSyncHelper(listener: self)
            bloodGlucoseDailySyncHelper = BloodGlucoseDailySyncHelper(listener: self)
            
            if userId > 0 {
                bloodGlucoseDailySyncHelper?.fetchDailyData(userId: userId) { _ in }
            }
            
        case .temperature:
            combinedDataSyncHelper = CombinedDataSyncHelper(listener: self)
            temperatureDailySyncHelper = TemperatureDailySyncHelper(listener: self)
            
            if userId > 0 {
                temperatureDailySyncHelper?.fetchDailyData(userId: userId) { _ in }
            }
        }
    }
    
    private func startBLESync() {
        print("🔄 Starting BLE sync for \(vitalType.displayName)")
        
        switch vitalType {
        case .heartRate:
            heartRateSyncHelper?.startSync()
            
        case .bloodPressure:
            bloodPressureSyncHelper?.startSync()
            
        case .hrv, .temperature, .bloodGlucose, .bloodOxygen:
            combinedDataSyncHelper?.startSync()
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

        // Chart view - BP uses both chartView (for tabs/date) and bpChartView (for dual-line rendering)
        if vitalType == .bloodPressure {
            // Use chartView for UI structure (tabs, date selector)
            contentView.addSubview(chartView)
            // But we'll need to customize it to show BP data
        } else {
            contentView.addSubview(chartView)
        }

        // Stats stack
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // For blood pressure, show systolic and diastolic mean cards
        if vitalType == .bloodPressure {
            [systolicCard, diastolicCard].forEach { statsStack.addArrangedSubview($0) }
        } else {
            [minCard, maxCard, avgCard].forEach { statsStack.addArrangedSubview($0) }
        }
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
                dayDataCompletion = completion
                heartRateSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                heartRateDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                    completion(dataPoints)
                    self?.updateStats(with: dataPoints)
                }
            }
            
        case .bloodPressure:
            switch range {
            case .day:
                dayDataCompletion = completion
                bloodPressureSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                bloodPressureDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] systolicPoints, diastolicPoints in
                    guard let self = self else { return }
                    
                    // Store BP data for custom value formatting (combine systolic and diastolic by timestamp)
                    var bpData: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)] = []
                    for (index, systolicPoint) in systolicPoints.enumerated() {
                        if index < diastolicPoints.count {
                            let diastolicPoint = diastolicPoints[index]
                            bpData.append((
                                timestamp: systolicPoint.timestamp,
                                systolicValue: Int(systolicPoint.value),
                                diastolicValue: Int(diastolicPoint.value)
                            ))
                        }
                    }
                    self.currentBPData = bpData
                    
                    // Update mean cards with data from date range
                    if !systolicPoints.isEmpty {
                        let systolicValues = systolicPoints.map { Int($0.value) }
                        let diastolicValues = diastolicPoints.map { Int($0.value) }
                        
                        let meanSystolic = systolicValues.reduce(0, +) / systolicValues.count
                        let meanDiastolic = diastolicValues.reduce(0, +) / diastolicValues.count
                        
                        self.systolicCard.updateValue("\(meanSystolic)")
                        self.diastolicCard.updateValue("\(meanDiastolic)")
                    } else {
                        self.systolicCard.updateValue("--")
                        self.diastolicCard.updateValue("--")
                    }
                    
                    // Return systolic data for chart
                    completion(systolicPoints)
                }
            }
            
        case .hrv:
            switch range {
            case .day:
                dayDataCompletion = completion
                combinedDataSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                hrvDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                    completion(dataPoints)
                    self?.updateStats(with: dataPoints)
                }
            }
            
        case .bloodOxygen:
            switch range {
            case .day:
                dayDataCompletion = completion
                combinedDataSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                bloodOxygenDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                    completion(dataPoints)
                    self?.updateStats(with: dataPoints)
                }
            }
            
        case .bloodGlucose:
            switch range {
            case .day:
                dayDataCompletion = completion
                combinedDataSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                bloodGlucoseDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                    completion(dataPoints)
                    self?.updateStats(with: dataPoints)
                }
            }
            
        case .temperature:
            switch range {
            case .day:
                dayDataCompletion = completion
                combinedDataSyncHelper?.fetchDataForDate(userId: userId, date: date)
                
            case .week, .month:
                temperatureDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { [weak self] dataPoints in
                    completion(dataPoints)
                    self?.updateStats(with: dataPoints)
                }
            }
        }
    }
    
    func fetchSecondaryChartData(for range: VitalChartRange, date: Date, completion: @escaping ([VitalDataPoint]) -> Void) {
        // Only BP has secondary data (diastolic)
        guard vitalType == .bloodPressure else {
            completion([])
            return
        }
        
        guard userId > 0 else {
            completion([])
            return
        }
        
        switch range {
        case .day:
            // Convert diastolic values from currentBPData to VitalDataPoint
            let diastolicPoints = currentBPData.map { entry in
                VitalDataPoint(timestamp: entry.timestamp, value: Double(entry.diastolicValue))
            }
            completion(diastolicPoints)
            
        case .week, .month:
            // Fetch diastolic data from daily stats
            bloodPressureDailySyncHelper?.loadDataForDateRange(userId: userId, range: range, selectedDate: date) { _, diastolicPoints in
                completion(diastolicPoints)
            }
        }
    }
}

// MARK: - VitalChartDelegate
extension HealthVitalsViewController: VitalChartDelegate {
    func chartShouldUpdateLabels(time: String, value: String) {
        // Labels are now internal to VitalChartView, no action needed
        // This delegate method can be used for other purposes if needed
    }
    
    func chartCustomValueFormat(for timestamp: Int64) -> String? {
        // Custom formatting for Blood Pressure: show "systolic/diastolic mmHg"
        guard vitalType == .bloodPressure else { return nil }
        
        if let bpEntry = currentBPData.first(where: { $0.timestamp == timestamp }) {
            return "\(bpEntry.systolicValue)/\(bpEntry.diastolicValue) mmHg"
        }
        
        return nil
    }
}

// MARK: - BLE Sync Listeners (Consolidated)
// HeartRateSyncListener and CombinedDataSyncListener both have onSyncFailed(error:)
extension HealthVitalsViewController: HeartRateSyncHelper.HeartRateSyncListener,
                                       BloodPressureSyncHelper.BloodPressureSyncListener,
                                       CombinedDataSyncHelper.CombinedDataSyncListener {
    
    // HeartRateSyncListener methods
    func onHeartRateDataFetched(_ data: [YCHealthDataHeartRate]) {
        print("✅ Received \(data.count) heart rate entries from ring")
        chartView.reloadData()
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
    
    // BloodPressureSyncListener methods
    func onBloodPressureDataFetched(_ data: [YCHealthDataBloodPressure]) {
        print("✅ Received \(data.count) blood pressure entries from ring")
    }
    
    func onLocalDataFetched(data: [(timestamp: Int64, systolicValue: Int, diastolicValue: Int)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📊 [Blood Pressure] Loaded \(data.count) readings from local DB")
            
            // Store BP data for later use (chart needs both values)
            self.currentBPData = data
            
            // Convert to VitalDataPoint for chart (using systolic values)
            let dataPoints = data.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.systolicValue)) }
            
            // Calculate and show mean systolic and diastolic values
            if !data.isEmpty {
                let systolicValues = data.map { $0.systolicValue }
                let diastolicValues = data.map { $0.diastolicValue }
                
                let meanSystolic = systolicValues.reduce(0, +) / systolicValues.count
                let meanDiastolic = diastolicValues.reduce(0, +) / diastolicValues.count
                
                self.systolicCard.updateValue("\(meanSystolic)")
                self.diastolicCard.updateValue("\(meanDiastolic)")
                
                print("📊 Mean BP: \(meanSystolic)/\(meanDiastolic) mmHg")
            } else {
                // Reset to -- when no data
                self.systolicCard.updateValue("--")
                self.diastolicCard.updateValue("--")
            }
            
            // Call chart completion to update the chart
            self.dayDataCompletion?(dataPoints)
            self.dayDataCompletion = nil
        }
    }
    
    // CombinedDataSyncListener methods
    func onCombinedDataFetched(
        hrv: [YCHealthDataCombinedData],
        bloodOxygen: [YCHealthDataCombinedData],
        bloodGlucose: [YCHealthDataCombinedData],
        temperature: [YCHealthDataCombinedData]
    ) {
        print("✅ [\(vitalType.displayName)] Combined data fetched from BLE:")
        print("   - HRV: \(hrv.count) entries")
        print("   - Blood Oxygen: \(bloodOxygen.count) entries")
        print("   - Blood Glucose: \(bloodGlucose.count) entries")
        print("   - Temperature: \(temperature.count) entries")
        
        // Print sample values based on vital type
        switch vitalType {
        case .hrv:
            if let first = hrv.first {
                print("   📊 Sample HRV: \(first.hrv)ms at timestamp \(first.startTimeStamp)")
            }
            
        case .bloodOxygen:
            if let first = bloodOxygen.first {
                print("   📊 Sample Blood Oxygen: \(first.bloodOxygen)% at timestamp \(first.startTimeStamp)")
            }
            
        case .bloodGlucose:
            if let first = bloodGlucose.first {
                print("   📊 Sample Blood Glucose: \(first.bloodGlucose)mg/dL at timestamp \(first.startTimeStamp)")
            }
            
        case .temperature:
            if let first = temperature.first {
                print("   📊 Sample Temperature: \(first.temperature)°C (valid: \(first.temperatureValid)) at timestamp \(first.startTimeStamp)")
            }
            
        default:
            break
        }
        
        chartView.reloadData()
    }
    
    func onLocalDataFetched(
        hrv: [(timestamp: Int64, hrvValue: Int)],
        bloodOxygen: [(timestamp: Int64, oxygenValue: Int)],
        bloodGlucose: [(timestamp: Int64, glucoseValue: Double)],
        temperature: [(timestamp: Int64, temperatureValue: Double)]
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📊 [\(self.vitalType.displayName)] Local data fetched:")
            
            var dataPoints: [VitalDataPoint] = []
            
            switch self.vitalType {
            case .hrv:
                print("   - HRV: \(hrv.count) entries from local DB")
                if let first = hrv.first {
                    print("   📊 First HRV value: \(first.hrvValue)ms")
                }
                dataPoints = hrv.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.hrvValue)) }
                
            case .bloodOxygen:
                print("   - Blood Oxygen: \(bloodOxygen.count) entries from local DB")
                if let first = bloodOxygen.first {
                    print("   📊 First Blood Oxygen value: \(first.oxygenValue)%")
                }
                dataPoints = bloodOxygen.map { VitalDataPoint(timestamp: $0.timestamp, value: Double($0.oxygenValue)) }
                
            case .bloodGlucose:
                print("   - Blood Glucose: \(bloodGlucose.count) entries from local DB")
                if let first = bloodGlucose.first {
                    print("   📊 First Blood Glucose value: \(first.glucoseValue)mg/dL")
                }
                dataPoints = bloodGlucose.map { VitalDataPoint(timestamp: $0.timestamp, value: $0.glucoseValue) }
                
            case .temperature:
                print("   - Temperature: \(temperature.count) entries from local DB")
                if let first = temperature.first {
                    print("   📊 First Temperature value: \(first.temperatureValue)°C")
                }
                dataPoints = temperature.map { VitalDataPoint(timestamp: $0.timestamp, value: $0.temperatureValue) }
                
            default:
                break
            }
            
            // Update stats
            self.updateStats(with: dataPoints)
            
            // Call chart completion
            self.dayDataCompletion?(dataPoints)
            self.dayDataCompletion = nil
        }
    }
    
    // Shared method: onSyncFailed (used by both protocols)
    func onSyncFailed(error: String) {
        print("❌ [\(vitalType.displayName)] Sync failed: \(error)")
    }
}







// MARK: - Daily Stats Sync Listeners (Consolidated)
// All daily sync listeners share same method signatures
extension HealthVitalsViewController: HeartRateDailySyncHelper.HeartRateDailySyncListener,
                                       BloodPressureDailySyncHelper.BloodPressureDailySyncListener,
                                       HRVDailySyncHelper.HRVDailySyncListener,
                                       BloodOxygenDailySyncHelper.BloodOxygenDailySyncListener,
                                       BloodGlucoseDailySyncHelper.BloodGlucoseDailySyncListener,
                                       TemperatureDailySyncHelper.TemperatureDailySyncListener {
    
    func onLocalDailyDataFetched(_ data: [VitalDataPoint]) {
        print("📊 [\(vitalType.displayName) Daily] Loaded \(data.count) daily entries from local DB")
    }
    
    func onAPIDailyDataFetched(_ data: [VitalDataPoint]) {
        print("🔄 [\(vitalType.displayName) Daily] Received \(data.count) updated daily entries from API")
        DispatchQueue.main.async { [weak self] in
            self?.chartView.reloadData()
        }
    }
    
    func onDailySyncFailed(error: String) {
        print("❌ [\(vitalType.displayName) Daily] Sync failed: \(error)")
    }
    
    // BP-specific daily sync callbacks
    func onLocalDailyBPDataFetched(_ systolicData: [VitalDataPoint], _ diastolicData: [VitalDataPoint]) {
        print("📊 [Blood Pressure Daily] Loaded \(systolicData.count) daily entries from local DB")
    }
    
    func onAPIDailyBPDataFetched(_ systolicData: [VitalDataPoint], _ diastolicData: [VitalDataPoint]) {
        print("🔄 [Blood Pressure Daily] Received \(systolicData.count) updated daily entries from API")
        DispatchQueue.main.async { [weak self] in
            self?.chartView.reloadData()
        }
    }
    
    func onDailyBPSyncFailed(error: String) {
        print("❌ [Blood Pressure Daily] Sync failed: \(error)")
    }
}

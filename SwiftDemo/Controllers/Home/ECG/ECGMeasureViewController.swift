import UIKit
import AVFoundation
import YCProductSDK

/// Main ECG measurement screen - coordinates UI and measurement logic
final class ECGMeasureViewController: BaseViewController {
    
    // MARK: - UI Components
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private let measurementCard = ECGMeasurementCardView()
    private let progressView = ECGProgressView()
    private let tipsOverlay = ECGTipsOverlayView()
    
    // MARK: - Managers
    private let measurementManager = ECGMeasurementManager()
    private let dataProcessor = ECGDataProcessor()
    
    // MARK: - Properties
    private var hasShownTips = false
    
    // Vital signs
    private var currentHR: Int = 0
    private var currentHRV: Int = 0
    private var currentSystolic: Int = 0
    private var currentDiastolic: Int = 0
    private var currentBloodOxygen: Int = 0
    private var currentTemperature: Double = 0.0
    
    // ECG data collection
    private var ecgWaveformData: [Int32] = []
    private var processedECGData: [Int] = []  // For display/saving (drawLists)
    private var rrIntervals: [Float] = []
    private var measurementStartTime: Date?
    
    // Database & Loading
    private let ecgRepository = ECGRecordRepository()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide inherited textView and listView from BaseViewController
        textView?.isHidden = true
        listView?.isHidden = true
        
        setupUI()
        setupBindings()
        setupNotifications()
        setupLoadingView()
        
        // Initialize algorithm manager
        dataProcessor.setupAlgorithm()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show tips on first launch
        if !hasShownTips {
            hasShownTips = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.tipsOverlay.show()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Ensure ECG line view frame is set properly for drawing
        measurementCard.ecgLineView.frame = measurementCard.ecgLineView.superview?.bounds ?? .zero
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if measurementManager.isMeasuring {
            measurementManager.stopMeasurement()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("[ECG] ECGMeasureViewController deinitialized")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "ECG Measurement"
        view.backgroundColor = .white
        
        // Scroll View
        scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Measurement Card
        measurementCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(measurementCard)
        
        // Progress View
        progressView.layer.cornerRadius = 25
        progressView.layer.masksToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.startStopButton.addTarget(self, action: #selector(startStopTapped), for: .touchUpInside)
        contentView.addSubview(progressView)
        
        // Tips Overlay
        tipsOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tipsOverlay)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            measurementCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            measurementCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            measurementCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            progressView.topAnchor.constraint(equalTo: measurementCard.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 50),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            tipsOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            tipsOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tipsOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tipsOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupLoadingView() {
        // Loading spinner
        loadingView.color = .white
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        loadingView.layer.cornerRadius = 16
        loadingView.hidesWhenStopped = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        // Loading label
        loadingLabel.text = "Generating AI Report..."
        loadingLabel.textColor = .white
        loadingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 200),
            loadingView.heightAnchor.constraint(equalToConstant: 120),
            
            loadingLabel.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: -20),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 12),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Tips overlay
        tipsOverlay.onConfirm = { [weak self] in
            self?.startMeasurement()
        }
        
        // Measurement manager callbacks
        measurementManager.onTimeUpdate = { [weak self] seconds, progress in
            self?.updateMeasurementProgress(seconds: seconds, progress: progress)
        }
        
        measurementManager.onMeasurementComplete = { [weak self] in
            self?.handleMeasurementComplete()
        }
        
        // Data processor callbacks
        dataProcessor.onHRUpdate = { [weak self] hr in
            print("[ECG] ✅ HR updated: \(hr) bpm")
            self?.currentHR = hr
            self?.measurementCard.hrValueLabel.text = "\(hr)"
        }
        
        dataProcessor.onBPUpdate = { [weak self] systolic, diastolic in
            print("[ECG] ✅ BP updated: \(systolic)/\(diastolic) mmHg")
            self?.currentSystolic = systolic
            self?.currentDiastolic = diastolic
            self?.measurementCard.bpValueLabel.text = "\(systolic)/\(diastolic)"
        }
        
        dataProcessor.onHRVUpdate = { [weak self] hrv in
            print("[ECG] ✅ HRV updated: \(hrv) ms")
            self?.currentHRV = hrv
            self?.measurementCard.hrvValueLabel.text = "\(hrv)"
        }
        
        dataProcessor.onBloodOxygenUpdate = { [weak self] oxygen in
            self?.currentBloodOxygen = oxygen
        }
        
        dataProcessor.onTemperatureUpdate = { [weak self] temp in
            self?.currentTemperature = temp
        }
        
        dataProcessor.onRRIntervalUpdate = { [weak self] rr in
            self?.rrIntervals.append(rr)
        }
        
        dataProcessor.onDrawECGValue = { [weak self] ecgValue in
            guard let self = self else { return }
            
            // Collect for saving (matches Android drawLists)
            self.processedECGData.append(ecgValue)
            
            // Distance between points (same as reference implementation)
            let distance = 6.25 * 0.1 * 3  // CELL_SIZE * 0.1 * 3
            let screenWidth = UIScreen.main.bounds.width
            
            // Check if screen is filled
            let currentWidth = CGFloat(self.measurementCard.ecgLineView.datas.count) * CGFloat(distance)
            
            if currentWidth < screenWidth {
                // Still filling screen, just add data
                self.measurementCard.ecgLineView.datas.add(NSNumber(value: ecgValue))
            } else {
                // Screen is full, remove first and add new (scrolling effect)
                self.measurementCard.ecgLineView.datas.removeObject(at: 0)
                self.measurementCard.ecgLineView.datas.add(NSNumber(value: ecgValue))
            }
            
            // Trigger redraw
            self.measurementCard.ecgLineView.setNeedsDisplay()
        }
        
        dataProcessor.onHeartbeat = { [weak self] in
            self?.measurementManager.playHeartbeatSound()
        }
        
        dataProcessor.onElectrodeStatusChange = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.measurementCard.updateElectrodeStatus(isConnected: isConnected)
            }
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRealTimeNotification(_:)),
            name: YCProduct.receivedRealTimeNotification,
            object: nil
        )
    }
    
    @objc private func handleRealTimeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        // Collect ECG waveform data
        if let ecgData = (userInfo[YCReceivedRealTimeDataType.ecg.string] as? YCReceivedDeviceReportInfo)?.data as? [Int32] {
            ecgWaveformData.append(contentsOf: ecgData)
        }
        
        // Process other data
        dataProcessor.processRealTimeNotificationData(userInfo)
    }
    
    // MARK: - Actions
    @objc private func startStopTapped() {
        if measurementManager.isMeasuring {
            // Show confirmation popup when stopping during measurement
            showStopConfirmation()
        } else {
            tipsOverlay.show()
        }
    }
    
    private func showStopConfirmation() {
        let alert = UIAlertController(
            title: "End ECG Measurement",
            message: "Are you sure you want to stop the measurement?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.stopMeasurement()
        })
        
        present(alert, animated: true)
    }
    
    private func startMeasurement() {
        print("[ECG] Starting measurement...")
        
        // Reset state
        currentHR = 0
        currentHRV = 0
        currentSystolic = 0
        currentDiastolic = 0
        currentBloodOxygen = 0
        currentTemperature = 0.0
        ecgWaveformData.removeAll()
        processedECGData.removeAll()  // Reset processed data
        rrIntervals.removeAll()
        measurementStartTime = Date()
        
        // Reset UI
        measurementCard.hrValueLabel.text = "--"
        measurementCard.bpValueLabel.text = "--"
        measurementCard.hrvValueLabel.text = "--"
        measurementCard.ecgLineView.datas.removeAllObjects()
        measurementCard.ecgLineView.setNeedsLayout()
        measurementCard.ecgLineView.setNeedsDisplay()
        
        // Show electrode status as disconnected initially
        measurementCard.updateElectrodeStatus(isConnected: false)
        
        progressView.progressView.progress = 0.0
        progressView.progressLabel.text = ""
        
        // Reset algorithm for clean state
        dataProcessor.resetAlgorithm()
        
        // Start measurement
        measurementManager.startMeasurement()
        progressView.updateForMeasuring(true)
        
        print("[ECG] Measurement started")
    }
    
    private func stopMeasurement() {
        measurementManager.stopMeasurement()
        progressView.updateForMeasuring(false)
        
        // Reset progress view completely
        progressView.progressView.progress = 0.0
        progressView.progressLabel.text = ""
        
        // Hide electrode status when stopped
        measurementCard.electrodeStatusView.isHidden = true
        
        print("[ECG] Measurement stopped manually")
    }
    
    private func updateMeasurementProgress(seconds: Int, progress: Double) {
        progressView.progressView.progress = Float(progress)
        progressView.progressLabel.text = "\(Int(progress * 100))%"
        
        print("[ECG] Progress: \(seconds)s / \(Int(progress * 100))%")
    }
    
    private func handleMeasurementComplete() {
        print("[ECG] Measurement complete!")
        
        progressView.updateForMeasuring(false)
        
        // Hide electrode status when complete
        measurementCard.electrodeStatusView.isHidden = true
        
        // Get results using async completion
        let deviceHR = currentHR > 0 ? currentHR : nil
        let deviceHRV = currentHRV > 0 ? currentHRV : nil
        
        measurementManager.getMeasurementResult(deviceHR: deviceHR, deviceHRV: deviceHRV) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Check if measurement failed (Type 0)
                if result.ecgMeasurementType == .failed {
                    print("[ECG] ⚠️ Measurement failed (Type 0) - NOT saving")
                    self.showFailedMeasurementAlert()
                    return
                }
                
                // Valid measurement (Type 1-7) - Show loading and save
                print("[ECG] ✅ Valid measurement (Type \(result.ecgMeasurementType.rawValue)) - saving...")
                self.showLoadingAndSave(result: result)
            }
        }
    }
    
    private func logCompleteMeasurementData(result: YCECGMeasurementResult, bodyIndexes: YCECGBodyIndexResult?) {
        let duration = measurementStartTime.map { -$0.timeIntervalSinceNow } ?? 0
        let avgRR = rrIntervals.isEmpty ? 0 : rrIntervals.reduce(0, +) / Float(rrIntervals.count)
        
        // Determine final values (device priority)
        let finalHR = currentHR > 0 ? currentHR : result.hearRate
        let finalHRV = currentHRV > 0 ? currentHRV : result.hrv
        
        print("\n" + String(repeating: "=", count: 80))
        print("📊 ECG MEASUREMENT COMPLETE - ALL COLLECTED DATA")
        print(String(repeating: "=", count: 80))
        
        print("\n⏱️  MEASUREMENT INFO:")
        print("   Duration: \(String(format: "%.1f", duration))s")
        print("   Start Time: \(measurementStartTime?.description ?? "N/A")")
        print("   Sample Count: \(ecgWaveformData.count)")
        
        print("\n💓 PRIMARY VITAL SIGNS (Algorithm Results):")
        print("   Heart Rate: \(result.hearRate) bpm")
        print("   HRV: \(result.hrv) ms")
        print("   ECG Type: \(result.ecgMeasurementType.rawValue)")
        print("   Diagnosis: \(getDiagnosisText(result.ecgMeasurementType))")
        
        print("\n📊 REAL-TIME MEASUREMENTS (if available):")
        print("   RT Heart Rate: \(currentHR > 0 ? "\(currentHR) bpm" : "N/A")")
        print("   RT HRV: \(currentHRV > 0 ? "\(currentHRV) ms" : "N/A")")
        print("   Systolic BP: \(currentSystolic > 0 ? "\(currentSystolic) mmHg" : "N/A")")
        print("   Diastolic BP: \(currentDiastolic > 0 ? "\(currentDiastolic) mmHg" : "N/A")")
        print("   Blood Oxygen: \(currentBloodOxygen > 0 ? "\(currentBloodOxygen)%" : "N/A")")
        print("   Temperature: \(currentTemperature > 0 ? String(format: "%.1f°C", currentTemperature) : "N/A")")
        
        print("\n✅ FINAL VALUES FOR SAVE (Device Priority):")
        print("   Heart Rate: \(finalHR) bpm \(currentHR > 0 ? "(Device)" : "(Algorithm)")")
        print("   HRV: \(finalHRV) ms \(currentHRV > 0 ? "(Device)" : "(Algorithm)")")
        print("   Blood Pressure: \(currentSystolic)/\(currentDiastolic) mmHg (Device)")
        print("   Blood Oxygen: \(currentBloodOxygen)% (Device)")
        print("   Temperature: \(String(format: "%.3f", currentTemperature))°C (Device)")
        
        print("\n📉 RR INTERVALS:")
        print("   Count: \(rrIntervals.count)")
        print("   Average: \(String(format: "%.2f", avgRR)) ms")
        if !rrIntervals.isEmpty {
            print("   Min: \(String(format: "%.2f", rrIntervals.min() ?? 0)) ms")
            print("   Max: \(String(format: "%.2f", rrIntervals.max() ?? 0)) ms")
        }
        
        print("\n🌊 WAVEFORM DATA:")
        print("   Total Samples: \(ecgWaveformData.count)")
        if !ecgWaveformData.isEmpty {
            print("   First 10: \(Array(ecgWaveformData.prefix(10)))")
            print("   Last 10: \(Array(ecgWaveformData.suffix(10)))")
        }
        
        if let bodyIndexes = bodyIndexes, bodyIndexes.isAvailable {
            print("\n🏥 BODY INDEXES (AVAILABLE ✅):")
            print("   HRV Index: \(String(format: "%.2f", bodyIndexes.hrvNorm))")
            print("   Load Index: \(String(format: "%.2f", bodyIndexes.heavyLoad))")
            print("   Pressure Index: \(String(format: "%.2f", bodyIndexes.pressure))")
            print("   Body Index: \(String(format: "%.2f", bodyIndexes.body))")
        } else {
            print("\n🏥 BODY INDEXES: ❌ Not Available")
        }
        
        print("\n📦 DATA FOR API UPLOAD:")
        print("""
        {
          "timestamp": "\(ISO8601DateFormatter().string(from: Date()))",
          "heartRate": \(finalHR),
          "systolicBP": \(currentSystolic > 0 ? currentSystolic : 0),
          "diastolicBP": \(currentDiastolic > 0 ? currentDiastolic : 0),
          "hrv": \(finalHRV),
          "diagnoseType": \(result.ecgMeasurementType.rawValue),
          "isAfib": \(result.ecgMeasurementType == .atrialFibrillation),
          "ecgDataCount": \(ecgWaveformData.count),
          "bloodOxygen": \(currentBloodOxygen > 0 ? currentBloodOxygen : 0),
          "temperature": \(currentTemperature > 0 ? currentTemperature : 0),
          "avgRR": \(avgRR),
          "hrvIndex": \(bodyIndexes?.isAvailable == true ? String(format: "%.2f", bodyIndexes!.hrvNorm) : "null"),
          "loadIndex": \(bodyIndexes?.isAvailable == true ? String(format: "%.2f", bodyIndexes!.heavyLoad) : "null"),
          "pressureIndex": \(bodyIndexes?.isAvailable == true ? String(format: "%.2f", bodyIndexes!.pressure) : "null"),
          "bodyIndex": \(bodyIndexes?.isAvailable == true ? String(format: "%.2f", bodyIndexes!.body) : "null")
        }
        """)
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    private func showFailedMeasurementAlert() {
        let alert = UIAlertController(
            title: "Measurement Failed",
            message: "Poor signal quality. Please ensure:\n\n• Ring fits snugly\n• Fingers firmly on metal contacts\n• Stay still during measurement\n\nWould you like to retry?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.tipsOverlay.show()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showLoadingAndSave(result: YCECGMeasurementResult) {
        // Show loading
        loadingView.startAnimating()
        view.bringSubviewToFront(loadingView)
        
        // Get body indexes
        let bodyIndexes = measurementManager.getBodyIndexes()
        
        // Debug log
        print("[ECG] 🔍 Stored values: HR=\(currentHR), HRV=\(currentHRV), BP=\(currentSystolic)/\(currentDiastolic)")
        
        // Log all collected data
        logCompleteMeasurementData(result: result, bodyIndexes: bodyIndexes)
        
        // Prepare final values (device priority)
        let finalHR = currentHR > 0 ? currentHR : result.hearRate
        let finalHRV = currentHRV > 0 ? currentHRV : result.hrv
        
        // Format timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: measurementStartTime ?? Date())
        
        // Save to database
        ecgRepository.saveRecord(
            timestamp: timestamp,
            heartRate: finalHR,
            sbp: currentSystolic,
            dbp: currentDiastolic,
            hrv: finalHRV,
            ecgList: processedECGData,  // Use processed data
            diagnoseType: Int(result.ecgMeasurementType.rawValue),
            isAfib: result.ecgMeasurementType == .atrialFibrillation,
            hrvIndex: bodyIndexes?.isAvailable == true ? Double(bodyIndexes!.hrvNorm) : 0.0,
            loadIndex: bodyIndexes?.isAvailable == true ? Double(bodyIndexes!.heavyLoad) : 0.0,
            pressureIndex: bodyIndexes?.isAvailable == true ? Double(bodyIndexes!.pressure) : 0.0,
            bodyIndex: bodyIndexes?.isAvailable == true ? Double(bodyIndexes!.body) : 0.0,
            bloodOxygen: currentBloodOxygen,
            temperature: currentTemperature
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.loadingView.stopAnimating()
                
                if success {
                    print("[ECG] 💾 Saved to database successfully!")
                    self?.showMeasurementResults(result: result)
                } else {
                    print("[ECG] ❌ Save failed: \(error ?? "unknown")")
                    self?.showSaveErrorAlert()
                }
            }
        }
    }
    
    private func showSaveErrorAlert() {
        let alert = UIAlertController(
            title: "Save Failed",
            message: "Unable to save ECG record. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func getDiagnosisText(_ type: YCECGResultType) -> String {
        switch type {
        case .normal: return "Normal ECG"
        case .atrialFibrillation: return "Suspected Atrial Fibrillation"
        case .earlyHeartbeat: return "Suspected Atrial Premature Beats"
        case .supraventricularHeartbeat: return "Suspected Ventricular Premature Beats"
        case .atrialBradycardia: return "Suspected Bradycardia"
        case .atrialTachycardia: return "Suspected Tachycardia"
        case .atrialArrhythmi: return "Suspected Arrhythmia"
        case .failed: return "Measurement Failed (Poor Signal)"
        @unknown default: return "Unknown"
        }
    }
    
    private func showMeasurementResults(result: YCECGMeasurementResult) {
        // TODO: Navigate to ECG report screen
        let alert = UIAlertController(
            title: "Measurement Complete",
            message: "HR: \(result.hearRate) bpm\nHRV: \(result.hrv) ms\nType: \(getDiagnosisText(result.ecgMeasurementType))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

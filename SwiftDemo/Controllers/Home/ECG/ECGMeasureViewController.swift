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
    private var currentHR: Int = 0
    private var currentHRV: Int = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide inherited textView and listView from BaseViewController
        textView?.isHidden = true
        listView?.isHidden = true
        
        setupUI()
        setupBindings()
        setupNotifications()
        
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
            self?.currentHR = hr
            self?.measurementCard.hrValueLabel.text = "\(hr)"
        }
        
        dataProcessor.onBPUpdate = { [weak self] systolic, diastolic in
            self?.measurementCard.bpValueLabel.text = "\(systolic)/\(diastolic)"
        }
        
        dataProcessor.onHRVUpdate = { [weak self] hrv in
            self?.currentHRV = hrv
            self?.measurementCard.hrvValueLabel.text = "\(hrv)"
        }
        
        dataProcessor.onDrawECGValue = { [weak self] ecgValue in
            guard let self = self else { return }
            
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
                print("[ECG] Final Results: HR=\(result.hearRate), HRV=\(result.hrv), Type=\(result.ecgMeasurementType.rawValue)")
                
                // Navigate to report
                self?.showMeasurementResults(result: result)
            }
        }
    }
    
    private func showMeasurementResults(result: YCECGMeasurementResult) {
        // TODO: Navigate to ECG report screen
        let alert = UIAlertController(
            title: "Measurement Complete",
            message: "HR: \(result.hearRate) bpm\nHRV: \(result.hrv) ms\nType: \(result.ecgMeasurementType.rawValue)",
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

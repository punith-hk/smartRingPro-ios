import UIKit
import CoreBluetooth
import YCProductSDK

struct ScannedDevice {
    let peripheral: CBPeripheral
    let name: String
    let mac: String
}

class SearchDeviceViewController: AppBaseViewController {

    private var devices: [ScannedDevice] = []
    private var scanTimer: Timer?

    // Connection state
    private var isConnecting = false

    // UI
    private let scanAnimationView = UIView()
    private let deviceIconView    = UIImageView()
    private var rippleLayers: [CAShapeLayer] = []
    private let containerView  = UIView()
    private let tableView      = UITableView()
    private let scanButton     = UIButton(type: .system)
    private let statusLabel    = UILabel()
    private let subStatusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []   // start layout below the navigation bar
        setScreenTitle("Bind Device")
        setupUI()
        startScanCycle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Kick off animation now that bounds are final
        if !scanButton.isEnabled { startScanAnimation() }
    }

    // MARK: - Layout

    private func setupUI() {
        let W = view.bounds.width
        view.backgroundColor = AppTheme.background

        // ── Device list card (top) ───────────────────────────────────────────
        containerView.frame = CGRect(x: 16, y: 16, width: W - 32, height: 280)
        AppTheme.styleCard(containerView, cornerRadius: 20)
        view.addSubview(containerView)

        tableView.frame = containerView.bounds
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.identifier)
        containerView.addSubview(tableView)

        // ── Status labels + scan button ──────────────────────────────────────
        let labelTop = containerView.frame.maxY + 16
        statusLabel.frame = CGRect(x: 0, y: labelTop, width: W, height: 20)
        statusLabel.textAlignment = .center
        statusLabel.font = AppTheme.bodyFont(size: 14)
        statusLabel.textColor = AppTheme.textPrimary
        view.addSubview(statusLabel)

        subStatusLabel.frame = CGRect(x: 0, y: statusLabel.frame.maxY + 4, width: W, height: 18)
        subStatusLabel.textAlignment = .center
        subStatusLabel.font = AppTheme.captionFont(size: 13)
        subStatusLabel.textColor = AppTheme.textSecondary
        view.addSubview(subStatusLabel)

        scanButton.frame = CGRect(
            x: 40, y: subStatusLabel.frame.maxY + 16,
            width: W - 80, height: 44)
        AppTheme.stylePrimaryButton(scanButton, title: "Scanning…", cornerRadius: 8)
        scanButton.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)
        view.addSubview(scanButton)

        // ── Scanning animation host (BOTTOM) ─────────────────────────────────
        let iconSz: CGFloat = min(W * 0.175, 70)
        let animH: CGFloat  = iconSz + 80          // just enough room for icon + ripples
        let animTop = scanButton.frame.maxY + 12
        scanAnimationView.backgroundColor = .clear
        scanAnimationView.frame = CGRect(x: 0, y: animTop, width: W, height: animH)
        view.addSubview(scanAnimationView)

        // Ring icon centred inside the animation zone
        deviceIconView.image = UIImage(named: "hearto_ring-nobg")
            ?? UIImage(systemName: "antenna.radiowaves.left.and.right")
        deviceIconView.contentMode = .scaleAspectFit
        deviceIconView.tintColor = AppTheme.primaryBlue
        deviceIconView.frame = CGRect(
            x: W / 2 - iconSz / 2,
            y: scanAnimationView.bounds.midY - iconSz / 2,
            width: iconSz, height: iconSz)
        scanAnimationView.addSubview(deviceIconView)
    }

    // MARK: - Scan Animation

    private func startScanAnimation() {
        scanAnimationView.alpha = 1

        // Remove stale ripples
        rippleLayers.forEach { $0.removeFromSuperlayer() }
        rippleLayers.removeAll()
        deviceIconView.layer.removeAnimation(forKey: "iconPulse")

        // Ripple anchor = center of the icon in scanAnimationView's coordinate space
        let cx = scanAnimationView.bounds.midX
        let cy = scanAnimationView.bounds.midY
        let maxR: CGFloat = 54

        for i in 0..<3 {
            let ripple = CAShapeLayer()
            ripple.path = UIBezierPath(
                ovalIn: CGRect(x: -maxR, y: -maxR, width: maxR * 2, height: maxR * 2)
            ).cgPath
            ripple.fillColor   = AppTheme.primaryBlue.withAlphaComponent(0.06).cgColor
            ripple.strokeColor = AppTheme.primaryBlue.withAlphaComponent(0.40).cgColor
            ripple.lineWidth   = 1.5
            ripple.opacity     = 0
            ripple.position    = CGPoint(x: cx, y: cy)
            scanAnimationView.layer.insertSublayer(ripple, at: 0)
            rippleLayers.append(ripple)

            let group = CAAnimationGroup()
            group.duration     = 2.6
            group.repeatCount  = .infinity
            group.beginTime    = CACurrentMediaTime() + Double(i) * 0.80
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.05
            scale.toValue   = 1.0

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values    = [0.0, 0.85, 0.0]
            fade.keyTimes  = [0, 0.12, 1.0]

            group.animations = [scale, fade]
            ripple.add(group, forKey: "ripple")
        }

        // Gentle pulse on the ring icon
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue     = 0.92
        pulse.toValue       = 1.08
        pulse.duration      = 1.1
        pulse.autoreverses  = true
        pulse.repeatCount   = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        deviceIconView.layer.add(pulse, forKey: "iconPulse")
    }

    private func stopScanAnimation() {
        deviceIconView.layer.removeAnimation(forKey: "iconPulse")
        rippleLayers.forEach { $0.removeAllAnimations() }
        UIView.animate(withDuration: 0.5) { self.scanAnimationView.alpha = 0 }
    }

    // MARK: - Scan

    private func startScanCycle() {
        devices.removeAll()
        tableView.reloadData()

        statusLabel.text = "Scanning in progress"
        subStatusLabel.text = "Scanning for available devices..."
        scanButton.setTitle("Scanning…", for: .normal)
        scanButton.isEnabled = false

        // Show ripple animation (runs immediately if viewDidAppear has fired)
        startScanAnimation()

        YCProduct.scanningDevice { [weak self] peripherals, _ in
            guard let self = self else { return }

            self.devices = peripherals.map {
                ScannedDevice(
                    peripheral: $0,
                    name: $0.name ?? "Unknown",
                    mac: $0.macAddress.uppercased()
                )
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(timeInterval: 10, target: self,
                                         selector: #selector(scanCompleted),
                                         userInfo: nil, repeats: false)
    }

    @objc private func scanCompleted() {
        statusLabel.text = devices.isEmpty ? "No devices found" : "Scan completed"
        subStatusLabel.text = devices.isEmpty
            ? "Make sure your ring is charged and nearby"
            : "\(devices.count) device\(devices.count == 1 ? "" : "s") found"
        scanButton.setTitle("Rescan", for: .normal)
        scanButton.isEnabled = true
        stopScanAnimation()
    }

    @objc private func rescanTapped() {
        startScanCycle()
    }
}

extension SearchDeviceViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: DeviceCell.identifier,
            for: indexPath
        ) as! DeviceCell

        let device = devices[indexPath.row]
        cell.configure(with: device)
        
        cell.onRawTapped = { [weak self] in
            guard let self = self else { return }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "ViewController"
            ) as! ViewController

            self.navigationController?.pushViewController(vc, animated: true)
        }

        // CONNECT BUTTON TAP
        cell.onConnectTapped = { [weak self] in
            guard let self = self else { return }
            self.connectToDevice(device)
        }

        return cell
    }

    // ROW TAP = SAME AS CONNECT BUTTON
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        connectToDevice(device)
    }
}

// MARK: - BLE Connection

extension SearchDeviceViewController {
    
    private func connectToDevice(_ device: ScannedDevice) {
        
        // Prevent multiple connection attempts
        guard !isConnecting else { return }
        isConnecting = true
        
        // 🔄 Show loading
        Loader.shared.show(on: view, message: "Connecting…", timeout: 10)
        
        print("🔵 Connecting to device: \(device.name) (\(device.mac))")
        
        // 🔗 Start BLE connection
        YCProduct.connectDevice(device.peripheral) { [weak self] state, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                Loader.shared.hide()
                self.isConnecting = false
                
                switch state {
                case .connected:
                    print("✅ Device connected successfully")
                    
                    // Save device info
                    DeviceSessionManager.shared.saveConnectedDevice(
                        mac: device.mac,
                        name: device.name
                    )
                    
                    // Navigate back immediately
                    self.navigationController?.popViewController(animated: true)
                    
                    // Show success toast on navigation controller's view (persists during transition)
                    if let navView = self.navigationController?.view {
                        Toast.show(message: "Connected to \(device.name)", in: navView)
                    }
                    
                case .connectedFailed:
                    print("❌ Connection failed")
                    self.showConnectionError(
                        title: "Connection Failed",
                        message: "Could not connect to \(device.name). Please try again."
                    )
                    
                case .timeout:
                    print("⏱️ Connection timeout")
                    self.showConnectionError(
                        title: "Connection Timeout",
                        message: "Connection to \(device.name) timed out. Please make sure the device is nearby and try again."
                    )
                    
                default:
                    print("⚠️ Connection state: \(state)")
                    if let error = error {
                        self.showConnectionError(
                            title: "Connection Error",
                            message: error.localizedDescription
                        )
                    } else {
                        self.showConnectionError(
                            title: "Connection Error",
                            message: "Unable to connect to \(device.name). Please try again."
                        )
                    }
                }
            }
        }
    }
    
    private func showConnectionError(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

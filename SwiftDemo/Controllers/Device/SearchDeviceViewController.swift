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
    private let loadingView = UIActivityIndicatorView(style: .large)

    // UI
    private let containerView = UIView()
    private let tableView = UITableView()
    private let scanButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let subStatusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Bind Device")
        setupUI()
        setupLoadingView()
        startScanCycle()
    }
    
    private func setupLoadingView() {
        // Loading indicator (hidden by default)
        loadingView.color = .white
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingView.layer.cornerRadius = 10
        loadingView.hidesWhenStopped = true
        view.addSubview(loadingView)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)

        containerView.frame = CGRect(x: 16, y: 120, width: view.bounds.width - 32, height: 360)
        containerView.backgroundColor = UIColor(red: 0.35, green: 0.7, blue: 0.8, alpha: 1)
        containerView.layer.cornerRadius = 20
        view.addSubview(containerView)

        tableView.frame = containerView.bounds
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.identifier)
        containerView.addSubview(tableView)

        statusLabel.frame = CGRect(x: 0, y: containerView.frame.maxY + 16, width: view.bounds.width, height: 20)
        statusLabel.textAlignment = .center
        statusLabel.font = .boldSystemFont(ofSize: 14)
        view.addSubview(statusLabel)

        subStatusLabel.frame = CGRect(x: 0, y: statusLabel.frame.maxY + 4, width: view.bounds.width, height: 18)
        subStatusLabel.textAlignment = .center
        subStatusLabel.font = .systemFont(ofSize: 13)
        subStatusLabel.textColor = .darkGray
        view.addSubview(subStatusLabel)

        scanButton.frame = CGRect(x: 40, y: subStatusLabel.frame.maxY + 20, width: view.bounds.width - 80, height: 44)
        scanButton.backgroundColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
        scanButton.layer.cornerRadius = 8
        scanButton.setTitleColor(.black, for: .normal)
        scanButton.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)
        view.addSubview(scanButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Center loading view after layout
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = view.center
    }

    // MARK: - Scan

    private func startScanCycle() {
        devices.removeAll()
        tableView.reloadData()

        statusLabel.text = "Scanning in progress"
        subStatusLabel.text = "Scanning for available devices..."
        scanButton.setTitle("Scanning...", for: .normal)
        scanButton.isEnabled = false

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
        statusLabel.text = "Scan completed"
        subStatusLabel.text = "Devices found: \(devices.count)"
        scanButton.setTitle("Rescan", for: .normal)
        scanButton.isEnabled = true
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
        loadingView.startAnimating()
        view.bringSubviewToFront(loadingView)
        
        print("🔵 Connecting to device: \(device.name) (\(device.mac))")
        
        // 🔗 Start BLE connection
        YCProduct.connectDevice(device.peripheral) { [weak self] state, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingView.stopAnimating()
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

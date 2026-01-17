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
        startScanCycle()
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

            // 1️⃣ Save device for routing
            DeviceSessionManager.shared.saveConnectedDevice(
                mac: device.mac,
                name: device.name
            )

            // 2️⃣ Start BLE connection
            YCProduct.connectDevice(device.peripheral) { _, _ in }

            // 3️⃣ Go back to DeviceViewController
            self.navigationController?.popViewController(animated: true)
        }

        return cell
    }

    // ROW TAP = SAME AS CONNECT BUTTON
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let device = devices[indexPath.row]

        DeviceSessionManager.shared.saveConnectedDevice(
            mac: device.mac,
            name: device.name
        )

        YCProduct.connectDevice(device.peripheral) { _, _ in }

        navigationController?.popViewController(animated: true)
    }
}

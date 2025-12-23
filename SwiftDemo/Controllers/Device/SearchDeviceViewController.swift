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

    // UI
    private let containerView = UIView()
    private let tableView = UITableView()
    private let scanButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Bind Device")

        setupUI()
        startScan()
    }
    
    private func setupUI() {

            view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)

            // Card
            containerView.frame = CGRect(x: 16, y: 120, width: view.bounds.width - 32, height: 360)
            containerView.backgroundColor = UIColor(red: 0.35, green: 0.7, blue: 0.8, alpha: 1)
            containerView.layer.cornerRadius = 20
            view.addSubview(containerView)

            // Table
            tableView.frame = containerView.bounds
            tableView.backgroundColor = .clear
            tableView.separatorStyle = .none
            tableView.rowHeight = 80
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.identifier)
            containerView.addSubview(tableView)

            // Status
            statusLabel.frame = CGRect(x: 0, y: containerView.frame.maxY + 20, width: view.bounds.width, height: 20)
            statusLabel.textAlignment = .center
            statusLabel.font = .systemFont(ofSize: 14)
            statusLabel.text = "Scanning in progress"
            view.addSubview(statusLabel)

            // Scan button
            scanButton.frame = CGRect(x: 40, y: statusLabel.frame.maxY + 20, width: view.bounds.width - 80, height: 44)
            scanButton.setTitle("scan it", for: .normal)
            scanButton.backgroundColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
            scanButton.layer.cornerRadius = 22
            scanButton.setTitleColor(.black, for: .normal)
            scanButton.addTarget(self, action: #selector(startScan), for: .touchUpInside)
            view.addSubview(scanButton)
        }

        @objc private func startScan() {

            statusLabel.text = "Searching for available devices..."
            devices.removeAll()
            tableView.reloadData()

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
        }

}

extension SearchDeviceViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: DeviceCell.identifier,
            for: indexPath
        ) as! DeviceCell

        cell.configure(with: devices[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let device = devices[indexPath.row]

        YCProduct.connectDevice(device.peripheral) { state, _ in
            if state == .connected {
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}


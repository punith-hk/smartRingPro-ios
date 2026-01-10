import UIKit
import YCProductSDK
import CoreBluetooth

class ConnectedDeviceViewController: AppBaseViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Device card
    private let deviceCard = UIView()
    private let deviceImageView = UIImageView()
    private let deviceNameLabel = UILabel()
    private let connectionLabel = UILabel()
    private let macLabel = UILabel()
    private let batteryView = UIImageView()
    private let batteryLabel = UILabel()
    
    // MARK: - Connection UI State
    private var isBlinking = false

    // Option cards
    private let temperatureCard = InfoCardView(
        icon: "thermometer",
        title: "Temperature unit",
        subtitle: "Celsius degrees (°C)"
    )
    
    private let temperatureOptions: [AppSettingsManager.TemperatureUnit] = [
        .celsius,
        .fahrenheit
    ]

    private let intervalCard = InfoCardView(
        icon: "timer",
        title: "Health Monitor Interval",
        subtitle: "15 min"
    )
    
    private let intervalOptions: [AppSettingsManager.HealthInterval] = [
        .min15,
        .min30,
        .min45,
        .min60
    ]

    // Firmware
    private let firmwareIcon = UIImageView()
    private let firmwareLabel = UILabel()
    private let firmwareValueLabel = UILabel()

    // Unpair
    private let unpairButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Equipment")
        view.backgroundColor = UIColor(
            red: 0.30,
            green: 0.60,
            blue: 0.95,
            alpha: 1
        )

        setupUI()
        populateCachedDeviceInfo()
        fetchAndUpdateDeviceBasicInfo()
        applySavedSettings()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceStateChanged(_:)),
            name: YCProduct.deviceStateNotification,
            object: nil
        )

        // Listen for temperature unit changes (others may change this)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(temperatureUnitChangedNotification(_:)),
            name: .temperatureUnitChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func temperatureUnitChangedNotification(_ notification: Notification) {
        // Show a friendly toast describing the newly selected temperature unit
        let unit = AppSettingsManager.shared.getTemperatureUnit()
        let name = unit == .fahrenheit ? "Fahrenheit (°F)" : "Celsius (°C)"
        Toast.show(message: "Temperature unit set to \(name)", in: self.view)
    }
    
    private func populateCachedDeviceInfo() {

        // Always show cached info immediately
        deviceNameLabel.text =
            DeviceSessionManager.shared.connectedDeviceName() ?? "Device"

        macLabel.text =
            DeviceSessionManager.shared.connectedDeviceMac() ?? "--"

        // While reconnecting → keep connecting UI
        startBlinking()
        updateBatteryUI(power: nil, status: nil)
        firmwareValueLabel.text = "--"
    }
    
    private func populateConnectedDeviceInfo() {

        let peripheral = YCProduct.shared.currentPeripheral

        deviceNameLabel.text =
            peripheral?.name ??
            DeviceSessionManager.shared.connectedDeviceName() ??
            "Device"

        macLabel.text =
            peripheral?.macAddress.uppercased() ??
            DeviceSessionManager.shared.connectedDeviceMac() ??
            "--"

        stopBlinkingConnected()
    }


    // MARK: - UI Setup
    private func setupUI() {

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

        setupDeviceCard()
        setupOptionCards()
        setupFirmwareSection()
        setupUnpairButton()
    }

    // MARK: - Device Card
    private func setupDeviceCard() {

        deviceCard.backgroundColor = .white
        deviceCard.layer.cornerRadius = 16
        deviceCard.translatesAutoresizingMaskIntoConstraints = false

        deviceImageView.image = UIImage(named: "smart_ring")
        deviceImageView.contentMode = .scaleAspectFit
        deviceImageView.clipsToBounds = true

        deviceNameLabel.font = .boldSystemFont(ofSize: 16)
        connectionLabel.font = .systemFont(ofSize: 14)
        macLabel.font = .systemFont(ofSize: 13)
        macLabel.textColor = .darkGray

        batteryView.image = UIImage(systemName: "battery.100")
        batteryView.tintColor = .systemGreen
        batteryLabel.font = .systemFont(ofSize: 14)

        [deviceImageView, deviceNameLabel, connectionLabel, macLabel,
         batteryView, batteryLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            deviceCard.addSubview($0)
        }

        contentView.addSubview(deviceCard)

        NSLayoutConstraint.activate([
            deviceCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            deviceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deviceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deviceCard.heightAnchor.constraint(equalToConstant: 110),

            deviceImageView.leadingAnchor.constraint(equalTo: deviceCard.leadingAnchor, constant: 16),
            deviceImageView.centerYAnchor.constraint(equalTo: deviceCard.centerYAnchor),
            deviceImageView.widthAnchor.constraint(equalToConstant: 60),
            deviceImageView.heightAnchor.constraint(equalToConstant: 60),

            deviceNameLabel.topAnchor.constraint(equalTo: deviceCard.topAnchor, constant: 16),
            deviceNameLabel.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 12),

            connectionLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 4),
            connectionLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),

            macLabel.topAnchor.constraint(equalTo: connectionLabel.bottomAnchor, constant: 4),
            macLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),

            batteryView.bottomAnchor.constraint(equalTo: deviceCard.bottomAnchor, constant: -6),
            batteryView.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            batteryView.widthAnchor.constraint(equalToConstant: 42),
            batteryView.heightAnchor.constraint(equalToConstant: 26),

            batteryLabel.centerYAnchor.constraint(equalTo: batteryView.centerYAnchor),
            batteryLabel.leadingAnchor.constraint(equalTo: batteryView.trailingAnchor, constant: 6)
        ])
    }

    // MARK: - Options
    private func setupOptionCards() {

        temperatureCard.translatesAutoresizingMaskIntoConstraints = false
        intervalCard.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(temperatureCard)
        contentView.addSubview(intervalCard)

        NSLayoutConstraint.activate([
            temperatureCard.topAnchor.constraint(equalTo: deviceCard.bottomAnchor, constant: 16),
            temperatureCard.leadingAnchor.constraint(equalTo: deviceCard.leadingAnchor),
            temperatureCard.trailingAnchor.constraint(equalTo: deviceCard.trailingAnchor),
            temperatureCard.heightAnchor.constraint(equalToConstant: 64),

            intervalCard.topAnchor.constraint(equalTo: temperatureCard.bottomAnchor, constant: 12),
            intervalCard.leadingAnchor.constraint(equalTo: deviceCard.leadingAnchor),
            intervalCard.trailingAnchor.constraint(equalTo: deviceCard.trailingAnchor),
            intervalCard.heightAnchor.constraint(equalToConstant: 64)
        ])

        // ✅ Attach actions
        temperatureCard.onTap = { [weak self] in
            self?.openTemperatureSelector()
        }

        intervalCard.onTap = { [weak self] in
            self?.openIntervalSelector()
        }
    }
    
    @objc private func openTemperatureSelector() {

        let current = AppSettingsManager.shared.getTemperatureUnit()

        let popup = MultiSelectPopupViewController(
            title: "Temperature Unit",
            options: temperatureOptions.map { $0.rawValue },
            preselected: [current.rawValue],
            maxSelection: 1
        )

        popup.onConfirm = { [weak self] selected in
            guard
                let value = selected.first,
                let unit = AppSettingsManager.TemperatureUnit(rawValue: value)
            else { return }

            AppSettingsManager.shared.setTemperatureUnit(unit)
            self?.temperatureCard.updateSubtitle(unit.rawValue)
            
            NotificationCenter.default.post(
                name: .temperatureUnitChanged,
                object: nil
            )
        }

        present(popup, animated: true)
    }
    
    
    @objc private func openIntervalSelector() {

        let current = AppSettingsManager.shared.getHealthInterval()

        let popup = MultiSelectPopupViewController(
            title: "Health Monitor Interval",
            options: intervalOptions.map { $0.rawValue },
            preselected: [current.rawValue],
            maxSelection: 1
        )

        popup.onConfirm = { [weak self] selected in
            guard
                let self = self,
                let value = selected.first,
                let interval = AppSettingsManager.HealthInterval(rawValue: value)
            else { return }

            // 1️⃣ Save locally
            AppSettingsManager.shared.setHealthInterval(interval)
            self.intervalCard.updateSubtitle(interval.rawValue)

            // 2️⃣ Push to ring
            self.updateRingHealthMonitoring(interval)

            // Show a user-friendly toast informing user of new interval
            Toast.show(message: "Health monitor interval set to \(interval.rawValue)", in: self.view)
        }

        present(popup, animated: true)
    }
    
    private func updateRingHealthMonitoring(
        _ interval: AppSettingsManager.HealthInterval
    ) {

        guard YCProduct.shared.currentPeripheral != nil else {
            print("⚠️ No connected device, skip monitoring update")
            return
        }

        let minutes = intervalToMinutes(interval)

        YCProduct.setDeviceHealthMonitoringMode(
            isEnable: true,
            interval: minutes
        ) { state, _ in

            DispatchQueue.main.async {
                if state == .succeed {
                    print("✅ Ring monitoring updated to \(minutes) min")
                } else {
                    print("❌ Failed to update ring monitoring: \(state)")
                }
            }
        }
    }

    private func intervalToMinutes(
        _ interval: AppSettingsManager.HealthInterval
    ) -> UInt8 {

        switch interval {
        case .min15: return 15
        case .min30: return 30
        case .min45: return 45
        case .min60: return 60
        }
    }
    
    private func applySavedSettings() {

        let temp = AppSettingsManager.shared.getTemperatureUnit()
        temperatureCard.updateSubtitle(temp.rawValue)

        let interval = AppSettingsManager.shared.getHealthInterval()
        intervalCard.updateSubtitle(interval.rawValue)
    }


    // MARK: - Firmware
    private func setupFirmwareSection() {

        firmwareIcon.image = UIImage(systemName: "cpu")
        firmwareIcon.tintColor = .black

        firmwareLabel.text = "FirmWareManagement"
        firmwareLabel.font = .systemFont(ofSize: 14)

        firmwareValueLabel.text = "--"
        firmwareValueLabel.font = .boldSystemFont(ofSize: 14)

        [firmwareIcon, firmwareLabel, firmwareValueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            firmwareIcon.topAnchor.constraint(equalTo: intervalCard.bottomAnchor, constant: 28),
            firmwareIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -80),

            firmwareLabel.centerYAnchor.constraint(equalTo: firmwareIcon.centerYAnchor),
            firmwareLabel.leadingAnchor.constraint(equalTo: firmwareIcon.trailingAnchor, constant: 8),

            firmwareValueLabel.centerYAnchor.constraint(equalTo: firmwareIcon.centerYAnchor),
            firmwareValueLabel.leadingAnchor.constraint(equalTo: firmwareLabel.trailingAnchor, constant: 8)
        ])
    }

    // MARK: - Unpair
    private func setupUnpairButton() {

        unpairButton.setTitle("UnPair", for: .normal)
        unpairButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        unpairButton.backgroundColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
        unpairButton.setTitleColor(.black, for: .normal)
        unpairButton.layer.cornerRadius = 12
        unpairButton.translatesAutoresizingMaskIntoConstraints = false
        unpairButton.addTarget(self, action: #selector(unpairTapped), for: .touchUpInside)

        contentView.addSubview(unpairButton)

        NSLayoutConstraint.activate([
            unpairButton.topAnchor.constraint(equalTo: firmwareIcon.bottomAnchor, constant: 24),
            unpairButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            unpairButton.widthAnchor.constraint(equalToConstant: 160),
            unpairButton.heightAnchor.constraint(equalToConstant: 44),
            unpairButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Actions
    @objc private func unpairTapped() {
        showUnpairConfirmation()
    }
    
    private func showUnpairConfirmation() {

        let alert = UIAlertController(
            title: "Unpair Device",
            message: "Are you sure you want to unpair this device?",
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        let unpair = UIAlertAction(title: "UnPair", style: .destructive) { [weak self] _ in
            self?.performUnpair()
        }

        alert.addAction(cancel)
        alert.addAction(unpair)

        present(alert, animated: true)
    }
    
    private func performUnpair() {

        // Disconnect BLE (no UI dependency)
        YCProduct.disconnectDevice { _, _ in }

        // Clear saved device
        DeviceSessionManager.shared.clearDevice()

        // Go back to Device root (Bind screen)
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - BLE State
    @objc private func deviceStateChanged(_ notification: Notification) {

        guard
            let info = notification.userInfo as? [String: Any],
            let state = info[YCProduct.connecteStateKey] as? YCProductState
        else { return }

        switch state {

        case .connected:
//            populateDeviceInfo()
            populateConnectedDeviceInfo()
            fetchAndUpdateDeviceBasicInfo()

        case .disconnected:
            // Sometimes the SDK emits transient 'disconnected' while the peripheral object
            // is still available. If the current peripheral matches the saved device,
            // treat this as a transient event and keep the connected UI (update battery).
            if let peripheral = YCProduct.shared.currentPeripheral {
                let currentMac = peripheral.macAddress.uppercased()
                let savedMac = DeviceSessionManager.shared.connectedDeviceMac()?.uppercased()
                if let saved = savedMac, saved == currentMac {
                    print("⚠️ Received disconnected for same peripheral (\(currentMac)). Preserving connected UI and refreshing info.")
                    populateConnectedDeviceInfo()
                    fetchAndUpdateDeviceBasicInfo()
                } else {
                    print("❌ Device disconnected (different peripheral) - start blinking")
                    startBlinking()
                }
            } else {
                print("❌ Device disconnected (no currentPeripheral) - start blinking")
                startBlinking()
            }

        default:
            break
        }
    }
    
    // MARK: - Battery from SDK
    private func fetchAndUpdateDeviceBasicInfo() {

        YCProduct.queryDeviceBasicInfo { [weak self] state, response in
            guard let self = self else { return }

            DispatchQueue.main.async {

                guard
                    state == .succeed,
                    let info = response as? YCDeviceBasicInfo
                else {
                    // fallback
                    self.firmwareValueLabel.text = "--"
                    self.updateBatteryUI(power: nil, status: nil)
                    return
                }

                // ✅ Battery
                self.updateBatteryUI(
                    power: Int(info.batteryPower),
                    status: info.batterystatus
                )

                // ✅ Firmware
                self.updateFirmware(info.mcuFirmware)
            }
        }
    }
    
    private func updateFirmware(_ version: YCDeviceVersionInfo?) {

        guard let version = version else {
            firmwareValueLabel.text = "--"
            return
        }

//        let text = String(describing: version)
        
        // replace later with actual
        firmwareValueLabel.text = "1.13"
    }
    
    // MARK: - Battery UI
    private func updateBatteryUI(
        power: Int?,
        status: YCDeviceBatterystate?
    ) {

        guard let power = power else {
            batteryLabel.text = "--"
            batteryView.image = UIImage(systemName: "battery.0")
            batteryView.tintColor = .lightGray
            return
        }

        batteryLabel.text = "\(power)%"

        // Charging has priority
        if status == .charging {
            batteryView.image = UIImage(systemName: "battery.100.bolt")
            batteryView.tintColor = .systemBlue
            return
        }

        if status == .full {
            batteryView.image = UIImage(systemName: "battery.100")
            batteryView.tintColor = .systemGreen
            return
        }

        switch power {
        case 61...100:
            batteryView.image = UIImage(systemName: "battery.100")
            batteryView.tintColor = .systemGreen

        case 21...60:
            batteryView.image = UIImage(systemName: "battery.50")
            batteryView.tintColor = .systemOrange

        default:
            batteryView.image = UIImage(systemName: "battery.25")
            batteryView.tintColor = .systemRed
        }
    }
    
    // MARK: - Connection Label Animation
    private func startBlinking() {
        guard !isBlinking else { return }
        isBlinking = true

        connectionLabel.text = "Connecting…"
        connectionLabel.alpha = 1.0

        UIView.animate(
            withDuration: 0.8,
            delay: 0,
            options: [.autoreverse, .repeat, .allowUserInteraction],
            animations: {
                self.connectionLabel.alpha = 0.2
            }
        )
    }

    private func stopBlinkingConnected() {
        isBlinking = false
        connectionLabel.layer.removeAllAnimations()
        connectionLabel.alpha = 1.0
        connectionLabel.text = "Connected"
    }

}

extension Notification.Name {
    static let temperatureUnitChanged = Notification.Name("temperatureUnitChanged")
    static let healthIntervalChanged = Notification.Name("healthIntervalChanged")
}


import UIKit
import YCProductSDK
import CoreBluetooth

class ConnectedDeviceViewController: AppBaseViewController {

    // MARK: - Colors
    private let bgColor     = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
    private let primaryBlue = UIColor(red: 13/255,  green: 153/255, blue: 255/255, alpha: 1)

    // MARK: - UI
    private let scrollView   = UIScrollView()
    private let contentView  = UIView()

    // Device card subviews
    private let deviceNameLabel   = UILabel()
    private let connectionLabel   = UILabel()
    private let macLabel          = UILabel()
    private let batteryIconView   = UIImageView()
    private let batteryLabel      = UILabel()

    // Firmware row
    private let firmwareValueLabel = UILabel()

    // MARK: - Connection UI State
    private var isBlinking   = false
    private var isUnpairing  = false   // blocks BLE callbacks from overriding "Disconnecting…"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Device")
        view.backgroundColor = bgColor
        buildUI()
        // Show standard loader while fetching device info from the SDK
        if DeviceSessionManager.shared.isDeviceActuallyConnected() {
            Loader.shared.show(on: view, message: "Loading device info…", timeout: 5)
        }
        populateCachedDeviceInfo()
        fetchAndUpdateDeviceBasicInfo()

        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceStateChanged(_:)),
            name: YCProduct.deviceStateNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(temperatureUnitChangedNotification(_:)),
            name: .temperatureUnitChanged, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Build UI
    private func buildUI() {
        scrollView.backgroundColor = bgColor
        scrollView.alwaysBounceVertical = true
        scrollView.delaysContentTouches = false
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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        let deviceCard   = buildDeviceCard()
        let healthCard   = makeNavCard(
            badgeBG: UIColor(red: 232/255, green: 234/255, blue: 254/255, alpha: 1),
            iconName: "gear",
            iconTint: UIColor(red: 83/255, green: 109/255, blue: 254/255, alpha: 1),
            title: "Health Settings",
            subtitle: "Monitor interval, targets & units",
            action: #selector(openHealthSettings)
        )
        let deviceSetCard = makeNavCard(
            badgeBG: UIColor(red: 232/255, green: 245/255, blue: 233/255, alpha: 1),
            iconName: "cpu",
            iconTint: UIColor(red: 102/255, green: 187/255, blue: 106/255, alpha: 1),
            title: "Device Settings",
            subtitle: "Reset ring & firmware updates",
            action: #selector(openDeviceSettings)
        )
        let firmwareRow  = buildFirmwareRow()
        let unpairBtn    = buildUnpairButton()
        let versionLbl   = buildVersionLabel()

        [deviceCard, healthCard, deviceSetCard, firmwareRow, unpairBtn, versionLbl]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            deviceCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            deviceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            deviceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            healthCard.topAnchor.constraint(equalTo: deviceCard.bottomAnchor, constant: 16),
            healthCard.leadingAnchor.constraint(equalTo: deviceCard.leadingAnchor),
            healthCard.trailingAnchor.constraint(equalTo: deviceCard.trailingAnchor),
            healthCard.heightAnchor.constraint(equalToConstant: 70),

            deviceSetCard.topAnchor.constraint(equalTo: healthCard.bottomAnchor, constant: 12),
            deviceSetCard.leadingAnchor.constraint(equalTo: deviceCard.leadingAnchor),
            deviceSetCard.trailingAnchor.constraint(equalTo: deviceCard.trailingAnchor),
            deviceSetCard.heightAnchor.constraint(equalToConstant: 70),

            firmwareRow.topAnchor.constraint(equalTo: deviceSetCard.bottomAnchor, constant: 28),
            firmwareRow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            unpairBtn.topAnchor.constraint(equalTo: firmwareRow.bottomAnchor, constant: 24),
            unpairBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            unpairBtn.widthAnchor.constraint(equalToConstant: 160),
            unpairBtn.heightAnchor.constraint(equalToConstant: 44),

            versionLbl.topAnchor.constraint(equalTo: unpairBtn.bottomAnchor, constant: 20),
            versionLbl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            versionLbl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }

    // MARK: - Device Card
    private func buildDeviceCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 10

        let ringIV = UIImageView(image: UIImage(named: "hearto_ring"))
        ringIV.contentMode = .scaleAspectFit
        ringIV.clipsToBounds = true
        ringIV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ringIV.widthAnchor.constraint(equalToConstant: 100),
            ringIV.heightAnchor.constraint(equalToConstant: 100),
        ])

        // Name
        deviceNameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        deviceNameLabel.textColor = .black
        deviceNameLabel.textAlignment = .left
        deviceNameLabel.text = "Device"

        // Connection status
        connectionLabel.font = .systemFont(ofSize: 14)
        connectionLabel.textColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)
        connectionLabel.textAlignment = .left

        // MAC
        macLabel.font = .systemFont(ofSize: 13)
        macLabel.textColor = .darkGray
        macLabel.textAlignment = .left
        macLabel.text = "--"

        // Battery — icon on left, percentage next to it
        batteryIconView.image = UIImage(systemName: "battery.100")
        batteryIconView.tintColor = UIColor(red: 117/255, green: 249/255, blue: 76/255, alpha: 1)
        batteryIconView.contentMode = .scaleAspectFit
        batteryIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            batteryIconView.widthAnchor.constraint(equalToConstant: 36),
            batteryIconView.heightAnchor.constraint(equalToConstant: 22),
        ])

        batteryLabel.font = .systemFont(ofSize: 14)
        batteryLabel.textColor = .black
        batteryLabel.text = "--"

        let battRow = UIStackView(arrangedSubviews: [batteryIconView, batteryLabel])
        battRow.axis = .horizontal
        battRow.spacing = 4
        battRow.alignment = .center

        // All 4 rows start at the same left edge
        let infoStack = UIStackView(arrangedSubviews: [deviceNameLabel, connectionLabel, macLabel, battRow])
        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoStack.alignment = .fill

        let hStack = UIStackView(arrangedSubviews: [ringIV, infoStack])
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return card
    }

    // MARK: - Nav Card
    private func makeNavCard(badgeBG: UIColor, iconName: String, iconTint: UIColor,
                              title: String, subtitle: String, action: Selector) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 6
        card.isUserInteractionEnabled = true

        let badge = UIView()
        badge.backgroundColor = badgeBG
        badge.layer.cornerRadius = 22
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([badge.widthAnchor.constraint(equalToConstant: 44), badge.heightAnchor.constraint(equalToConstant: 44)])

        let iconIV = UIImageView(image: UIImage(systemName: iconName))
        iconIV.tintColor = iconTint
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(iconIV)
        NSLayoutConstraint.activate([
            iconIV.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 22),
            iconIV.heightAnchor.constraint(equalToConstant: 22),
        ])

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 16, weight: .bold)
        titleLbl.textColor = .black

        let subLbl = UILabel()
        subLbl.text = subtitle
        subLbl.font = .systemFont(ofSize: 12)
        subLbl.textColor = UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1)

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis = .vertical
        textStack.spacing = 3

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([chevron.widthAnchor.constraint(equalToConstant: 10), chevron.heightAnchor.constraint(equalToConstant: 16)])

        let hStack = UIStackView(arrangedSubviews: [badge, textStack, chevron])
        hStack.axis = .horizontal
        hStack.spacing = 14
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 13),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -13),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])

        let tap = UITapGestureRecognizer(target: self, action: action)
        card.addGestureRecognizer(tap)
        return card
    }

    // MARK: - Firmware Row
    private func buildFirmwareRow() -> UIView {
        let chipIV = UIImageView(image: UIImage(systemName: "cpu"))
        chipIV.tintColor = .black
        chipIV.contentMode = .scaleAspectFit
        chipIV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([chipIV.widthAnchor.constraint(equalToConstant: 28), chipIV.heightAnchor.constraint(equalToConstant: 28)])

        let fwLabel = UILabel()
        fwLabel.text = "FirmWareManagement"
        fwLabel.font = .systemFont(ofSize: 14, weight: .bold)

        firmwareValueLabel.text = "--"
        firmwareValueLabel.font = .systemFont(ofSize: 14, weight: .bold)

        let row = UIStackView(arrangedSubviews: [chipIV, fwLabel, firmwareValueLabel])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    // MARK: - Unpair Button
    private func buildUnpairButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("UnPair", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = primaryBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 22
        btn.addTarget(self, action: #selector(unpairTapped), for: .touchUpInside)
        return btn
    }

    // MARK: - App Version
    private func buildVersionLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text = "App Version: \(appVersion())"
        lbl.font = .systemFont(ofSize: 13, weight: .semibold)
        lbl.textColor = UIColor(red: 50/255, green: 80/255, blue: 120/255, alpha: 1)
        lbl.textAlignment = .center
        return lbl
    }

    private func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: - Populate
    private func populateCachedDeviceInfo() {
        deviceNameLabel.text = DeviceSessionManager.shared.connectedDeviceName() ?? "Device"
        macLabel.text = DeviceSessionManager.shared.connectedDeviceMac() ?? "--"

        if DeviceSessionManager.shared.isDeviceActuallyConnected() {
            stopBlinkingConnected()
            fetchAndUpdateDeviceBasicInfo()
        } else {
            startBlinking()
            updateBatteryUI(power: nil, status: nil)
            firmwareValueLabel.text = "--"
        }
    }

    private func populateConnectedDeviceInfo() {
        let peripheral = YCProduct.shared.currentPeripheral
        deviceNameLabel.text = peripheral?.name
            ?? DeviceSessionManager.shared.connectedDeviceName()
            ?? "Device"
        macLabel.text = peripheral?.macAddress.uppercased()
            ?? DeviceSessionManager.shared.connectedDeviceMac()
            ?? "--"
        stopBlinkingConnected()
    }

    // MARK: - BLE Notifications
    @objc private func deviceStateChanged(_ notification: Notification) {
        guard !isUnpairing else { return }   // ignore all BLE events while unpair is in progress
        guard
            let info = notification.userInfo as? [String: Any],
            let state = info[YCProduct.connecteStateKey] as? YCProductState
        else { return }

        switch state {
        case .connected:
            populateConnectedDeviceInfo()
            fetchAndUpdateDeviceBasicInfo()
        case .disconnected:
            if let peripheral = YCProduct.shared.currentPeripheral {
                let current = peripheral.macAddress.uppercased()
                let saved   = DeviceSessionManager.shared.connectedDeviceMac()?.uppercased()
                if let saved = saved, saved == current {
                    populateConnectedDeviceInfo()
                    fetchAndUpdateDeviceBasicInfo()
                } else {
                    startBlinking()
                }
            } else {
                startBlinking()
            }
        default:
            break
        }
    }

    @objc private func temperatureUnitChangedNotification(_ notification: Notification) {
        let unit = AppSettingsManager.shared.getTemperatureUnit()
        let name = unit == .fahrenheit ? "Fahrenheit (°F)" : "Celsius (°C)"
        Toast.show(message: "Temperature unit set to \(name)", in: self.view)
    }

    // MARK: - Battery from SDK
    private func fetchAndUpdateDeviceBasicInfo() {
        YCProduct.queryDeviceBasicInfo { [weak self] state, response in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideLoadingOverlay()
                guard state == .succeed, let info = response as? YCDeviceBasicInfo else {
                    self.firmwareValueLabel.text = "--"
                    self.updateBatteryUI(power: nil, status: nil)
                    return
                }
                let batteryLevel = Int(info.batteryPower)
                self.updateBatteryUI(power: batteryLevel, status: info.batterystatus)
                DeviceInfoManager.shared.saveBattery(batteryLevel)
                self.updateFirmware(info.mcuFirmware)
            }
        }
    }

    // MARK: - Loading Overlay
    private func hideLoadingOverlay() {
        Loader.shared.hide()
    }

    private func updateFirmware(_ version: YCDeviceVersionInfo?) {
        let firmwareVersion = "1.13"    // replace with actual SDK value when available
        firmwareValueLabel.text = firmwareVersion
        DeviceInfoManager.shared.saveFirmwareVersion(firmwareVersion)
    }

    // MARK: - Battery UI
    private func updateBatteryUI(power: Int?, status: YCDeviceBatterystate?) {
        guard let power = power else {
            batteryLabel.text = "--"
            batteryIconView.image = UIImage(systemName: "battery.0")
            batteryIconView.tintColor = .lightGray
            return
        }

        if status == .charging {
            batteryLabel.text = "\(power)%"
            batteryIconView.image = UIImage(systemName: "battery.100.bolt")
            batteryIconView.tintColor = .systemBlue
            return
        }
        if status == .full {
            batteryLabel.text = "\(power)%"
            batteryIconView.image = UIImage(systemName: "battery.100")
            batteryIconView.tintColor = UIColor(red: 117/255, green: 249/255, blue: 76/255, alpha: 1)
            return
        }
        batteryLabel.text = "\(power)%"
        switch power {
        case 61...100:
            batteryIconView.image = UIImage(systemName: "battery.100")
            batteryIconView.tintColor = UIColor(red: 117/255, green: 249/255, blue: 76/255, alpha: 1)
        case 21...60:
            batteryIconView.image = UIImage(systemName: "battery.50")
            batteryIconView.tintColor = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)
        default:
            batteryIconView.image = UIImage(systemName: "battery.25")
            batteryIconView.tintColor = .systemRed
        }
    }

    // MARK: - Connection Animation
    private func startBlinking() {
        guard !isBlinking else { return }
        isBlinking = true
        connectionLabel.text = "Connecting…"
        connectionLabel.textColor = UIColor(red: 255/255, green: 167/255, blue: 38/255, alpha: 1)
        connectionLabel.alpha = 1.0
        UIView.animate(withDuration: 0.8, delay: 0,
                       options: [.autoreverse, .repeat, .allowUserInteraction]) {
            self.connectionLabel.alpha = 0.2
        }
    }

    private func stopBlinkingConnected() {
        isBlinking = false
        connectionLabel.layer.removeAllAnimations()
        connectionLabel.alpha = 1.0
        connectionLabel.text = "Connected"
        connectionLabel.textColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)
    }

    // MARK: - Navigation Actions
    @objc private func openHealthSettings() {
        navigationController?.pushViewController(HealthSettingsViewController(), animated: true)
    }

    @objc private func openDeviceSettings() {
        navigationController?.pushViewController(DeviceSettingsViewController(), animated: true)
    }

    // MARK: - Unpair
    @objc private func unpairTapped() {
        let alert = UIAlertController(
            title: "Unpair Device",
            message: "Are you sure you want to unpair this device?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unpair", style: .destructive) { [weak self] _ in
            self?.performUnpair()
        })
        present(alert, animated: true)
    }

    private func performUnpair() {
        isUnpairing = true

        // Update status label immediately so user sees feedback
        connectionLabel.text = "Disconnecting…"
        connectionLabel.textColor = .systemOrange
        connectionLabel.layer.removeAllAnimations()

        // Fire disconnect + clear session immediately in the background
        YCProduct.disconnectDevice { _, _ in }
        DeviceSessionManager.shared.clearDevice()

        // Show loader for 3 s, then pop — gives BLE stack time to clean up gracefully
        Loader.shared.show(on: view, message: "Disconnecting…", timeout: 3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            Loader.shared.hide()
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension Notification.Name {
    static let temperatureUnitChanged = Notification.Name("temperatureUnitChanged")
    static let healthIntervalChanged  = Notification.Name("healthIntervalChanged")
}


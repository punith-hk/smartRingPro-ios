import UIKit
import YCProductSDK

class HealthSettingsViewController: AppBaseViewController {

    // MARK: - Colors
    private let bgColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

    // MARK: - Subtitle Labels (for live update)
    private weak var tempSubLbl: UILabel?
    private weak var intervalSubLbl: UILabel?
    private weak var stepsSubLbl: UILabel?
    private weak var sleepSubLbl: UILabel?

    // MARK: - Options
    private let temperatureOptions: [AppSettingsManager.TemperatureUnit] = [.celsius, .fahrenheit]
    private let intervalOptions: [AppSettingsManager.HealthInterval] = [.min15, .min30, .min45, .min60]

    private let stepsOptions: [Int] = [
        1_000, 2_000, 3_000, 4_000, 5_000,
        6_000, 7_000, 7_500, 8_000, 9_000,
        10_000, 11_000, 12_000, 12_500, 15_000, 20_000
    ]

    // Sleep options: 4h to 12h in 30-min steps
    private let sleepOptions: [Int] = stride(from: 240, through: 720, by: 30).map { $0 }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Health Settings")
        view.backgroundColor = bgColor
        buildUI()
    }

    // MARK: - Build UI
    private func buildUI() {
        let scroll = UIScrollView()
        scroll.backgroundColor = bgColor
        scroll.alwaysBounceVertical = true
        scroll.delaysContentTouches = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
        content.backgroundColor = bgColor
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])

        // Page title
        let pageTitleLbl = UILabel()
        pageTitleLbl.text = "Health Settings"
        pageTitleLbl.font = .systemFont(ofSize: 22, weight: .bold)
        pageTitleLbl.textColor = .black
        pageTitleLbl.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(pageTitleLbl)

        // Cards
        let tempUnit    = AppSettingsManager.shared.getTemperatureUnit()
        let tempCardV   = makeSettingCard(
            badgeBG: UIColor(red: 255/255, green: 243/255, blue: 224/255, alpha: 1),
            iconName: "thermometer",
            iconTint: UIColor(red: 255/255, green: 152/255, blue: 0/255, alpha: 1),
            title: "Temperature Unit",
            subtitle: tempUnit.rawValue,
            subtitleRef: &tempSubLbl,
            action: #selector(openTempUnitPicker)
        )

        let interval     = AppSettingsManager.shared.getHealthInterval()
        let intervalCardV = makeSettingCard(
            badgeBG: UIColor(red: 232/255, green: 234/255, blue: 254/255, alpha: 1),
            iconName: "clock.fill",
            iconTint: UIColor(red: 83/255, green: 109/255, blue: 254/255, alpha: 1),
            title: "Health Monitor Interval",
            subtitle: interval.rawValue,
            subtitleRef: &intervalSubLbl,
            action: #selector(openIntervalPicker)
        )

        let stepsFormatted = formatSteps(AppSettingsManager.shared.getStepsTarget())
        let stepsCardV     = makeSettingCard(
            badgeBG: UIColor(red: 232/255, green: 245/255, blue: 233/255, alpha: 1),
            iconName: "figure.walk",
            iconTint: UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1),
            title: "Daily Steps Target",
            subtitle: stepsFormatted,
            subtitleRef: &stepsSubLbl,
            action: #selector(openStepsPicker)
        )

        let sleepFormatted = formatSleep(AppSettingsManager.shared.getSleepTargetMinutes())
        let sleepCardV     = makeSettingCard(
            badgeBG: UIColor(red: 237/255, green: 231/255, blue: 246/255, alpha: 1),
            iconName: "moon.fill",
            iconTint: UIColor(red: 94/255, green: 53/255, blue: 177/255, alpha: 1),
            title: "Daily Sleep Target",
            subtitle: sleepFormatted,
            subtitleRef: &sleepSubLbl,
            action: #selector(openSleepPicker)
        )

        let stack = UIStackView(arrangedSubviews: [tempCardV, intervalCardV, stepsCardV, sleepCardV])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        [tempCardV, intervalCardV, stepsCardV, sleepCardV].forEach {
            $0.heightAnchor.constraint(equalToConstant: 72).isActive = true
        }

        NSLayoutConstraint.activate([
            pageTitleLbl.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            pageTitleLbl.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),

            stack.topAnchor.constraint(equalTo: pageTitleLbl.bottomAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Setting Card Factory
    private func makeSettingCard(
        badgeBG: UIColor, iconName: String, iconTint: UIColor,
        title: String, subtitle: String,
        subtitleRef: inout UILabel?,
        action: Selector
    ) -> UIView {

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.isUserInteractionEnabled = true

        let badge = UIView()
        badge.backgroundColor = badgeBG
        badge.layer.cornerRadius = 22
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([badge.widthAnchor.constraint(equalToConstant: 44),
                                     badge.heightAnchor.constraint(equalToConstant: 44)])

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
        titleLbl.font = .systemFont(ofSize: 14, weight: .bold)
        titleLbl.textColor = .black

        let subLbl = UILabel()
        subLbl.text = subtitle
        subLbl.font = .systemFont(ofSize: 12)
        subLbl.textColor = UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1)
        subtitleRef = subLbl

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis = .vertical
        textStack.spacing = 3

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([chevron.widthAnchor.constraint(equalToConstant: 10),
                                     chevron.heightAnchor.constraint(equalToConstant: 16)])

        let hStack = UIStackView(arrangedSubviews: [badge, textStack, chevron])
        hStack.axis = .horizontal
        hStack.spacing = 14
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        return card
    }

    // MARK: - Picker Actions
    @objc private func openTempUnitPicker() {
        let current = AppSettingsManager.shared.getTemperatureUnit()
        let options = temperatureOptions.map { $0.rawValue }
        let popup = MultiSelectPopupViewController(
            title: "Temperature Unit",
            options: options,
            preselected: [current.rawValue],
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            guard let self = self,
                  let value = selected.first,
                  let unit = AppSettingsManager.TemperatureUnit(rawValue: value) else { return }
            AppSettingsManager.shared.setTemperatureUnit(unit)
            self.tempSubLbl?.text = unit.rawValue
            Toast.show(message: "Temperature unit set to \(unit.rawValue)", in: self.view)
            NotificationCenter.default.post(name: .temperatureUnitChanged, object: nil)
        }
        present(popup, animated: true)
    }

    @objc private func openIntervalPicker() {
        guard DeviceSessionManager.shared.isDeviceActuallyConnected() else {
            Toast.show(message: "Device not connected", in: view)
            return
        }
        let current = AppSettingsManager.shared.getHealthInterval()
        let options = intervalOptions.map { $0.rawValue }
        let popup = MultiSelectPopupViewController(
            title: "Monitor Interval",
            options: options,
            preselected: [current.rawValue],
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            guard let self = self,
                  let value = selected.first,
                  let interval = AppSettingsManager.HealthInterval(rawValue: value) else { return }
            AppSettingsManager.shared.setHealthInterval(interval)
            self.intervalSubLbl?.text = interval.rawValue
            self.pushIntervalToRing(interval)
            NotificationCenter.default.post(name: .healthIntervalChanged, object: nil)
        }
        present(popup, animated: true)
    }

    @objc private func openStepsPicker() {
        let current = AppSettingsManager.shared.getStepsTarget()
        let options = stepsOptions.map { formatSteps($0) }
        let currentFormatted = formatSteps(current)
        let popup = MultiSelectPopupViewController(
            title: "Daily Steps Target",
            options: options,
            preselected: [currentFormatted],
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            guard let self = self, let value = selected.first else { return }
            if let idx = options.firstIndex(of: value) {
                let steps = self.stepsOptions[idx]
                AppSettingsManager.shared.setStepsTarget(steps)
                let formatted = self.formatSteps(steps)
                self.stepsSubLbl?.text = formatted
                Toast.show(message: "Daily steps target set to \(formatted)", in: self.view)
            }
        }
        present(popup, animated: true)
    }

    @objc private func openSleepPicker() {
        let current = AppSettingsManager.shared.getSleepTargetMinutes()
        let options = sleepOptions.map { formatSleep($0) }
        let currentFormatted = formatSleep(current)
        let popup = MultiSelectPopupViewController(
            title: "Daily Sleep Target",
            options: options,
            preselected: [currentFormatted],
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            guard let self = self, let value = selected.first else { return }
            if let idx = options.firstIndex(of: value) {
                let minutes = self.sleepOptions[idx]
                AppSettingsManager.shared.setSleepTargetMinutes(minutes)
                let formatted = self.formatSleep(minutes)
                self.sleepSubLbl?.text = formatted
                Toast.show(message: "Daily sleep target set to \(formatted)", in: self.view)
            }
        }
        present(popup, animated: true)
    }

    // MARK: - Ring Sync
    private func pushIntervalToRing(_ interval: AppSettingsManager.HealthInterval) {
        guard YCProduct.shared.currentPeripheral != nil else { return }
        let minutes: UInt8
        switch interval {
        case .min15: minutes = 15
        case .min30: minutes = 30
        case .min45: minutes = 45
        case .min60: minutes = 60
        }
        YCProduct.setDeviceHealthMonitoringMode(isEnable: true, interval: minutes) { state, _ in
            DispatchQueue.main.async {
                if state == .succeed {
                    Toast.show(message: "Monitoring interval updated to \(minutes) min", in: self.view)
                }
            }
        }
    }

    // MARK: - Formatters
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: steps)) ?? "\(steps)") + " steps"
    }

    private func formatSleep(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

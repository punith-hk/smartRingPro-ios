import UIKit
import YCProductSDK

class DeviceSettingsViewController: AppBaseViewController {

    // MARK: - Colors
    private let bgColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

    // MARK: - Subtitle Labels (for firmware version)
    private weak var resetSubLbl: UILabel?
    private weak var firmwareSubLbl: UILabel?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Device Settings")
        view.backgroundColor = bgColor
        buildUI()
    }

    // MARK: - Build UI
    private func buildUI() {
        let scroll = UIScrollView()
        scroll.backgroundColor = bgColor
        scroll.alwaysBounceVertical = true
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
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])

        // Page title
        let pageTitleLbl = UILabel()
        pageTitleLbl.text = "Device Settings"
        pageTitleLbl.font = .systemFont(ofSize: 22, weight: .bold)
        pageTitleLbl.textColor = .black
        pageTitleLbl.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(pageTitleLbl)

        // Firmware version
        let currentFirmware = DeviceInfoManager.shared.getFirmwareVersion()
        let firmwareDisplay = "Current: \(currentFirmware)"

        let resetCard    = makeActionCard(
            badgeBG: UIColor(red: 255/255, green: 235/255, blue: 238/255, alpha: 1),
            iconName: "arrow.counterclockwise",
            iconTint: UIColor(red: 244/255, green: 67/255, blue: 54/255, alpha: 1),
            title: "Reset Ring",
            subtitle: "Restore factory settings",
            subtitleRef: &resetSubLbl,
            action: #selector(resetRingTapped)
        )

        let firmwareCard = makeActionCard(
            badgeBG: UIColor(red: 232/255, green: 245/255, blue: 233/255, alpha: 1),
            iconName: "arrow.down.circle.fill",
            iconTint: UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1),
            title: "Update Firmware",
            subtitle: firmwareDisplay,
            subtitleRef: &firmwareSubLbl,
            action: #selector(updateFirmwareTapped)
        )

        let cardStack = UIStackView(arrangedSubviews: [resetCard, firmwareCard])
        cardStack.axis = .vertical
        cardStack.spacing = 14
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(cardStack)

        [resetCard, firmwareCard].forEach {
            $0.heightAnchor.constraint(equalToConstant: 72).isActive = true
        }

        // Info banner (shown when disconnected)
        let infoBanner = buildInfoBanner()
        let isConnected = DeviceSessionManager.shared.isDeviceActuallyConnected()
        infoBanner.isHidden = isConnected
        content.addSubview(infoBanner)

        NSLayoutConstraint.activate([
            pageTitleLbl.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            pageTitleLbl.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),

            cardStack.topAnchor.constraint(equalTo: pageTitleLbl.bottomAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),

            infoBanner.topAnchor.constraint(equalTo: cardStack.bottomAnchor, constant: 16),
            infoBanner.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            infoBanner.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            infoBanner.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Action Card Factory
    private func makeActionCard(
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

    // MARK: - Info Banner
    private func buildInfoBanner() -> UIView {
        let banner = UIView()
        banner.backgroundColor = UIColor(red: 227/255, green: 242/255, blue: 253/255, alpha: 1)
        banner.layer.cornerRadius = 10

        let iconIV = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        iconIV.tintColor = UIColor(red: 13/255, green: 153/255, blue: 255/255, alpha: 1)
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([iconIV.widthAnchor.constraint(equalToConstant: 20),
                                     iconIV.heightAnchor.constraint(equalToConstant: 20)])

        let lbl = UILabel()
        lbl.text = "Device must be connected to perform these actions"
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = UIColor(red: 13/255, green: 153/255, blue: 255/255, alpha: 1)
        lbl.numberOfLines = 0

        let hStack = UIStackView(arrangedSubviews: [iconIV, lbl])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: banner.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -14),
            hStack.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
        ])
        return banner
    }

    // MARK: - Actions
    @objc private func resetRingTapped() {
        guard DeviceSessionManager.shared.isDeviceActuallyConnected() else {
            showNotConnectedAlert()
            return
        }
        let alert = UIAlertController(
            title: "Reset Ring",
            message: "This will restore the device to factory settings. All data on the ring will be erased. Continue?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes, Reset", style: .destructive) { [weak self] _ in
            self?.performReset()
        })
        present(alert, animated: true)
    }

    @objc private func updateFirmwareTapped() {
        guard DeviceSessionManager.shared.isDeviceActuallyConnected() else {
            showNotConnectedAlert()
            return
        }
        let currentFirmware = DeviceInfoManager.shared.getFirmwareVersion()
        let alert = UIAlertController(
            title: "Update Firmware",
            message: "Firmware update functionality will be available soon.\n\nCurrent Version: \(currentFirmware)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showNotConnectedAlert() {
        let alert = UIAlertController(
            title: "Device Not Connected",
            message: "Please connect your ring first to perform this action.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Factory Reset
    private func performReset() {
        let loading = UIAlertController(
            title: nil,
            message: "Resetting device, please wait…",
            preferredStyle: .alert
        )
        present(loading, animated: true)

        YCProduct.setDeviceReset { [weak self] state, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                loading.dismiss(animated: true) {
                    guard let self = self else { return }
                    if state == .succeed {
                        Toast.show(message: "Ring reset successful", in: self.view)
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        Toast.show(message: "Reset failed. Please try again.", in: self.view)
                    }
                }
            }
        }
    }
}

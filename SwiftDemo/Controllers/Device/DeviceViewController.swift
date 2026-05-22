import UIKit

class DeviceViewController: AppBaseViewController {

    // MARK: - Colors
    private let bgColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Device")
        showHamburger()
        view.backgroundColor = bgColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only build the bind UI when not connected and this VC is the top VC.
        // The connected-state redirect is handled in viewDidAppear (after the
        // transition animation finishes) to avoid nav-bar corruption.
        if !DeviceSessionManager.shared.isDeviceConnected() {
            buildBindUI()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Redirect to ConnectedDeviceVC AFTER the current transition finishes.
        // Calling setViewControllers inside viewWillAppear (during an active
        // animation) was creating the nav-bar jump on every push/pop.
        if DeviceSessionManager.shared.isDeviceConnected() {
            showConnectedDevice()
        }
    }

    // MARK: - Connected State
    private func showConnectedDevice() {
        let connectedVC = ConnectedDeviceViewController()
        navigationController?.setViewControllers([self, connectedVC], animated: false)
    }

    // MARK: - Not-Connected (Bind) UI
    private func buildBindUI() {
        // Remove any old bind UI
        view.subviews.forEach { $0.removeFromSuperview() }

        let scroll = UIScrollView()
        scroll.backgroundColor = bgColor
        scroll.delaysContentTouches = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
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

        // Bind card
        let card = UIView()
        card.backgroundColor = UIColor(red: 1/255, green: 174/255, blue: 214/255, alpha: 1)
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.shadowRadius = 10
        card.isUserInteractionEnabled = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(bindDeviceTapped))
        card.addGestureRecognizer(tap)

        let ringIV = UIImageView(image: UIImage(named: "smart_ring") ?? UIImage(systemName: "dot.radiowaves.left.and.right"))
        ringIV.contentMode = .scaleAspectFit
        ringIV.tintColor = .white
        ringIV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ringIV.widthAnchor.constraint(equalToConstant: 64),
            ringIV.heightAnchor.constraint(equalToConstant: 64),
        ])

        let titleLbl = UILabel()
        titleLbl.text = "Bind the Device"
        titleLbl.font = .systemFont(ofSize: 20, weight: .bold)
        titleLbl.textColor = .white

        let subLbl = UILabel()
        subLbl.text = "Connect your ring to start monitoring"
        subLbl.font = .systemFont(ofSize: 14, weight: .regular)
        subLbl.textColor = UIColor.white.withAlphaComponent(0.85)
        subLbl.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView(arrangedSubviews: [ringIV, textStack])
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
        ])

        // App version
        let versionLbl = UILabel()
        versionLbl.text = "App Version: \(appVersion())"
        versionLbl.font = .systemFont(ofSize: 13, weight: .semibold)
        versionLbl.textColor = UIColor(red: 50/255, green: 80/255, blue: 120/255, alpha: 1)
        versionLbl.textAlignment = .center
        versionLbl.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(card)
        content.addSubview(versionLbl)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: content.topAnchor, constant: 30),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 30),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -30),

            versionLbl.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 32),
            versionLbl.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            versionLbl.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32),
        ])
    }

    @objc private func bindDeviceTapped() {
        let searchVC = SearchDeviceViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - Helpers
    private func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}


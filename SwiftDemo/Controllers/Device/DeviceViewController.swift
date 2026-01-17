import UIKit

class DeviceViewController: AppBaseViewController {

    // MARK: - UI
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Device")
        showHamburger()

        view.backgroundColor = UIColor(
            red: 0.30,
            green: 0.60,
            blue: 0.95,
            alpha: 1
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if DeviceSessionManager.shared.isDeviceConnected() {
            showConnectedDevice()
        } else {
            showBindDevice()
        }
    }

    private func showBindDevice() {
        setupUI()
    }

    private func showConnectedDevice() {
        let connectedVC = ConnectedDeviceViewController()
        navigationController?.setViewControllers([self, connectedVC], animated: false)
    }

    private func setupUI() {

        // Avoid duplicate UI on reappear
        view.subviews.forEach {
            if $0 == cardView { $0.removeFromSuperview() }
        }

        // Card
        cardView.backgroundColor = UIColor(
            red: 0.40,
            green: 0.80,
            blue: 0.85,
            alpha: 1
        )
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.18
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        // Title
        titleLabel.text = "Bind the device"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left

        // Subtitle
        subtitleLabel.text = "You have not bound any device yet"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 2

        // Stack
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 6
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        cardView.addSubview(textStack)

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(bindDeviceTapped))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true

        // Constraints
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.heightAnchor.constraint(equalToConstant: 130),

            textStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20)
        ])
    }

    @objc private func bindDeviceTapped() {
        let searchVC = SearchDeviceViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }
}

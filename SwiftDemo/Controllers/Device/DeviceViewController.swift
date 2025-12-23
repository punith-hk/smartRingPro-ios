import UIKit

class DeviceViewController: AppBaseViewController {

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

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

        // Card
        cardView.backgroundColor = UIColor(
            red: 0.40,
            green: 0.80,
            blue: 0.85,
            alpha: 1
        )
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        // Title
        titleLabel.text = "Bind the device"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "you have not bound any device yet"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .black
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(bindDeviceTapped))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true

        // Constraints
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }

    @objc private func bindDeviceTapped() {
        let searchVC = SearchDeviceViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }

}

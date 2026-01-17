import UIKit
import MapKit

final class LinkedAccountDetailsViewController: AppBaseViewController {

    // MARK: - Input
    var linkedAccountId: Int!
    var linkedAccountName: String!

    // MARK: - Data
    private var lastRingData: LastRingDataResponse?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MAIN WHITE CARD
    private let mainCard = UIView()

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()

    private let mapView = MKMapView()

    private let healthStack = UIStackView()
    private let sportsStack = UIStackView()

    private let disassociateButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Account"
        setupUI()
        fetchLastRingData()
    }

    // MARK: - API
    private func fetchLastRingData() {
        LinkedAccountService.shared.getLastRingData(userId: linkedAccountId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    self?.bindData(response)
                }
            }
        }
    }

    // MARK: - UI
    private func setupUI() {

        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

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

        setupMainCard()
        setupProfile()
        setupMap()
        setupHealthIndicators()
        setupSportsOverview()
        setupDisassociateButton()
    }

    // MARK: - MAIN CARD
    private func setupMainCard() {
        mainCard.backgroundColor = .white
        mainCard.layer.cornerRadius = 18
        mainCard.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainCard)

        NSLayoutConstraint.activate([
            mainCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - PROFILE
    private func setupProfile() {

        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray4
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .darkGray
        infoLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [nameLabel, infoLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        mainCard.addSubview(profileImageView)
        mainCard.addSubview(textStack)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: mainCard.topAnchor, constant: 16),
            profileImageView.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),

            textStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - MAP
    private func setupMap() {
        mapView.layer.cornerRadius = 12
        mapView.isScrollEnabled = false
        mapView.translatesAutoresizingMaskIntoConstraints = false

        mainCard.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }

    // MARK: - HEALTH
    private func setupHealthIndicators() {

        let title = sectionTitle("Health indicators")

        healthStack.axis = .vertical
        healthStack.spacing = 0
        healthStack.translatesAutoresizingMaskIntoConstraints = false

        mainCard.addSubview(title)
        mainCard.addSubview(healthStack)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 16),

            healthStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            healthStack.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor),
            healthStack.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor)
        ])
    }

    // MARK: - SPORTS
    private func setupSportsOverview() {

        let title = sectionTitle("Today's Sports Overview")

        sportsStack.axis = .horizontal
        sportsStack.spacing = 12
        sportsStack.distribution = .fillEqually
        sportsStack.translatesAutoresizingMaskIntoConstraints = false

        mainCard.addSubview(title)
        mainCard.addSubview(sportsStack)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: healthStack.bottomAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 16),

            sportsStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            sportsStack.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: 16),
            sportsStack.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -16),
            sportsStack.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - DISASSOCIATE
    private func setupDisassociateButton() {

        disassociateButton.setTitle("Disassociation", for: .normal)
        disassociateButton.backgroundColor = .systemRed
        disassociateButton.setTitleColor(.white, for: .normal)
        disassociateButton.layer.cornerRadius = 10
        disassociateButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(disassociateButton)

        NSLayoutConstraint.activate([
            disassociateButton.topAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: 24),
            disassociateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            disassociateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            disassociateButton.heightAnchor.constraint(equalToConstant: 44),
            disassociateButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - DATA BIND
    private func bindData(_ response: LastRingDataResponse) {

        nameLabel.text = linkedAccountName
        infoLabel.text = "33 years old • Male\nHeight: 170cm  Weight: 60kg"

        healthStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sportsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        response.data.forEach {
            let displayValue = formattedValue(for: $0.type, rawValue: "\($0.value)")

            healthStack.addArrangedSubview(
                infoRow(title: formatType($0.type), value: displayValue)
            )
        }

        sportsStack.addArrangedSubview(statBox(title: "Step count", value: "0"))
        sportsStack.addArrangedSubview(statBox(title: "mile", value: "0.00"))
        sportsStack.addArrangedSubview(statBox(title: "Calories", value: "0 kcal"))
    }

    // MARK: - HELPERS
    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func infoRow(title: String, value: String) -> UIView {

        let left = UILabel()
        left.text = title
        left.font = .systemFont(ofSize: 14)

        let right = UILabel()
        right.text = value
        right.font = .systemFont(ofSize: 14, weight: .medium)
        right.textAlignment = .right

        let s = UIStackView(arrangedSubviews: [left, right])
        s.axis = .horizontal
        s.distribution = .fillEqually

        let v = UIView()
        v.addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            s.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            s.topAnchor.constraint(equalTo: v.topAnchor),
            s.bottomAnchor.constraint(equalTo: v.bottomAnchor),
            v.heightAnchor.constraint(equalToConstant: 36)
        ])

        v.backgroundColor = UIColor(white: 0.96, alpha: 1)
        return v
    }

    private func statBox(title: String, value: String) -> UIView {

        let v = UIView()
        v.backgroundColor = UIColor(white: 0.95, alpha: 1)
        v.layer.cornerRadius = 12

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .darkGray

        let s = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        s.axis = .vertical
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(s)
        NSLayoutConstraint.activate([
            s.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            s.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            v.heightAnchor.constraint(equalToConstant: 72)
        ])

        return v
    }

    private func formatType(_ type: String) -> String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func formattedValue(for type: String, rawValue: String) -> String {

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type.lowercased() {

        case "heart_rate":
            return "\(value) times/min"

        case "hrv":
            return "\(value) ms"

        case "blood_oxygen":
            return "\(value)%"

        case "blood_sugar":
            return "\(value) mg/dL"

        case "blood_pressure":
            return "\(value) mmHg"

        case "temperature":
            return "\(value) °C"

        case "sleep":
            // API gives minutes (e.g. 432)
            if let minutes = Int(value) {
                let h = minutes / 60
                let m = minutes % 60
                return "\(h)h \(m)m"
            }
            return value

        default:
            return value
        }
    }

}

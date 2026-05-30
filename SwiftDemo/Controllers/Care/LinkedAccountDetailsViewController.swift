import UIKit
import MapKit

final class LinkedAccountDetailsViewController: AppBaseViewController {

    // MARK: - Input
    var linkedAccountId: Int!
    var linkedAccountName: String!
    var linkedAccountRelation: String?

    // MARK: - Data
    private var lastRingData: LastRingDataResponse?
    private var profileData: ProfileDataResponse.ProfileData?

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()
    private let mapView     = MKMapView()
    private let disassociateButton = UIButton(type: .system)

    // Dynamic label refs for profile card
    private var ageGenderLabel = UILabel()
    private var heightWeightLabel = UILabel()
    private var bloodGroupValueLabel = UILabel()
    private var patientIdValueLabel  = UILabel()
    private var allergyValueLabel    = UILabel()

    // Medical card labels
    private var conditionsLabel   = UILabel()
    private var medicationsLabel  = UILabel()

    // Vitals grid stack
    private var vitalsGridStack = UIStackView()

    // Activity grid stack
    private var stepsValueLabel    = UILabel()
    private var caloriesValueLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Linked Account"
        setupUI()
        fetchData()
    }

    // MARK: - Fetch
    private func fetchData() {
        LinkedAccountService.shared.getLastRingData(userId: linkedAccountId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let r) = result { self?.bindRingData(r) }
            }
        }
        ProfileService.shared.getUserProfile(userId: linkedAccountId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let r) = result { self?.bindProfile(r.data) }
            }
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.99, alpha: 1)

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

        let profileCard  = buildProfileCard()
        let medicalCard  = buildMedicalCard()
        let vitalsCard   = buildVitalsCard()
        let activityCard = buildActivityCard()
        let locationSection = buildLocationSection()

        buildDisassociateButton()

        contentView.addSubview(profileCard)
        contentView.addSubview(medicalCard)
        contentView.addSubview(vitalsCard)
        contentView.addSubview(activityCard)
        contentView.addSubview(locationSection)
        contentView.addSubview(disassociateButton)

        NSLayoutConstraint.activate([
            profileCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            profileCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            medicalCard.topAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: 12),
            medicalCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            medicalCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            vitalsCard.topAnchor.constraint(equalTo: medicalCard.bottomAnchor, constant: 12),
            vitalsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            vitalsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            activityCard.topAnchor.constraint(equalTo: vitalsCard.bottomAnchor, constant: 12),
            activityCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            activityCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            locationSection.topAnchor.constraint(equalTo: activityCard.bottomAnchor, constant: 12),
            locationSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            disassociateButton.topAnchor.constraint(equalTo: locationSection.bottomAnchor, constant: 20),
            disassociateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            disassociateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            disassociateButton.heightAnchor.constraint(equalToConstant: 48),
            disassociateButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Profile Card
    private func buildProfileCard() -> UIView {
        let card = whiteCard()

        // Avatar circle
        let avatar = makeAvatarView(name: linkedAccountName ?? "")

        // Name
        let nameLabel = UILabel()
        nameLabel.text = linkedAccountName ?? ""
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Relation (blue)
        let relLabel = UILabel()
        relLabel.text = linkedAccountRelation ?? "Family member"
        relLabel.font = .systemFont(ofSize: 14, weight: .medium)
        relLabel.textColor = UIColor(red: 0.00, green: 0.47, blue: 0.83, alpha: 1)
        relLabel.translatesAutoresizingMaskIntoConstraints = false

        // Age/gender
        ageGenderLabel.text = "-- · --"
        ageGenderLabel.font = .systemFont(ofSize: 13)
        ageGenderLabel.textColor = UIColor(white: 0.4, alpha: 1)
        ageGenderLabel.translatesAutoresizingMaskIntoConstraints = false

        // Height/weight
        heightWeightLabel.text = "-- · --"
        heightWeightLabel.font = .systemFont(ofSize: 13)
        heightWeightLabel.textColor = UIColor(white: 0.4, alpha: 1)
        heightWeightLabel.translatesAutoresizingMaskIntoConstraints = false

        // Separator
        let sep = makeSeparator()

        // 3-column grid
        let gridRow = makeThreeColumnGrid()

        card.addSubview(avatar)
        card.addSubview(nameLabel)
        card.addSubview(relLabel)
        card.addSubview(ageGenderLabel)
        card.addSubview(heightWeightLabel)
        card.addSubview(sep)
        card.addSubview(gridRow)

        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 60),
            avatar.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            relLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            relLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            relLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            ageGenderLabel.topAnchor.constraint(equalTo: relLabel.bottomAnchor, constant: 2),
            ageGenderLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            ageGenderLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            heightWeightLabel.topAnchor.constraint(equalTo: ageGenderLabel.bottomAnchor, constant: 2),
            heightWeightLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            heightWeightLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            sep.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 14),
            sep.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            sep.heightAnchor.constraint(equalToConstant: 1),

            gridRow.topAnchor.constraint(equalTo: sep.bottomAnchor),
            gridRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            gridRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            gridRow.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    private func makeAvatarView(name: String) -> UIView {
        let colors: [UIColor] = [
            UIColor(red: 0.13, green: 0.47, blue: 0.71, alpha: 1),
            UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1),
            UIColor(red: 0.00, green: 0.59, blue: 0.53, alpha: 1),
        ]
        let color = colors[abs(name.hashValue) % colors.count]
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = String(name.prefix(1)).uppercased()
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }

    private func makeThreeColumnGrid() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Blood group
        let bgBlock = makeGridBlock()
        bloodGroupValueLabel = bgBlock.valueLabel
        bloodGroupValueLabel.text = "--"
        bloodGroupValueLabel.textColor = UIColor(red: 0.85, green: 0.23, blue: 0.19, alpha: 1)
        bgBlock.titleLabel.text = "Blood Group"
        let bgView = bgBlock.view

        // Patient ID
        let pidBlock = makeGridBlock()
        patientIdValueLabel = pidBlock.valueLabel
        patientIdValueLabel.text = "--"
        pidBlock.titleLabel.text = "Patient ID"
        let pidView = pidBlock.view

        // Allergy
        let algBlock = makeGridBlock()
        allergyValueLabel = algBlock.valueLabel
        allergyValueLabel.text = "--"
        algBlock.titleLabel.text = "Allergy"
        let algView = algBlock.view

        // Vertical dividers
        let div1 = makeSeparator(vertical: true)
        let div2 = makeSeparator(vertical: true)

        container.addSubview(bgView)
        container.addSubview(div1)
        container.addSubview(pidView)
        container.addSubview(div2)
        container.addSubview(algView)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: container.topAnchor),
            bgView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bgView.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            div1.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            div1.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            div1.leadingAnchor.constraint(equalTo: bgView.trailingAnchor),
            div1.widthAnchor.constraint(equalToConstant: 1),

            pidView.topAnchor.constraint(equalTo: container.topAnchor),
            pidView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            pidView.leadingAnchor.constraint(equalTo: div1.trailingAnchor),
            pidView.widthAnchor.constraint(equalTo: bgView.widthAnchor),

            div2.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            div2.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            div2.leadingAnchor.constraint(equalTo: pidView.trailingAnchor),
            div2.widthAnchor.constraint(equalToConstant: 1),

            algView.topAnchor.constraint(equalTo: container.topAnchor),
            algView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            algView.leadingAnchor.constraint(equalTo: div2.trailingAnchor),
            algView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            algView.widthAnchor.constraint(equalTo: bgView.widthAnchor),

            container.heightAnchor.constraint(equalToConstant: 64)
        ])

        return container
    }

    private func makeGridBlock() -> (view: UIView, valueLabel: UILabel, titleLabel: UILabel) {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let val = UILabel()
        val.font = .systemFont(ofSize: 16, weight: .semibold)
        val.textAlignment = .center
        val.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.font = .systemFont(ofSize: 11)
        title.textColor = UIColor(white: 0.5, alpha: 1)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(val)
        view.addSubview(title)

        NSLayoutConstraint.activate([
            val.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            val.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            val.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            title.topAnchor.constraint(equalTo: val.bottomAnchor, constant: 2),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            title.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
        return (view, val, title)
    }

    // MARK: - Medical Card
    private func buildMedicalCard() -> UIView {
        let card = whiteCard()

        let header = UILabel()
        header.text = "Medical Information"
        header.font = .systemFont(ofSize: 16, weight: .bold)
        header.translatesAutoresizingMaskIntoConstraints = false

        let condTitle = UILabel()
        condTitle.text = "Existing Conditions"
        condTitle.font = .systemFont(ofSize: 12)
        condTitle.textColor = UIColor(white: 0.5, alpha: 1)
        condTitle.translatesAutoresizingMaskIntoConstraints = false

        conditionsLabel.text = "--"
        conditionsLabel.font = .systemFont(ofSize: 14)
        conditionsLabel.numberOfLines = 0
        conditionsLabel.translatesAutoresizingMaskIntoConstraints = false

        let sep = makeSeparator()

        let medTitle = UILabel()
        medTitle.text = "Current Medications"
        medTitle.font = .systemFont(ofSize: 12)
        medTitle.textColor = UIColor(white: 0.5, alpha: 1)
        medTitle.translatesAutoresizingMaskIntoConstraints = false

        medicationsLabel.text = "--"
        medicationsLabel.font = .systemFont(ofSize: 14)
        medicationsLabel.numberOfLines = 0
        medicationsLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(header)
        card.addSubview(condTitle)
        card.addSubview(conditionsLabel)
        card.addSubview(sep)
        card.addSubview(medTitle)
        card.addSubview(medicationsLabel)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            condTitle.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            condTitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            condTitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            conditionsLabel.topAnchor.constraint(equalTo: condTitle.bottomAnchor, constant: 4),
            conditionsLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            conditionsLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            sep.topAnchor.constraint(equalTo: conditionsLabel.bottomAnchor, constant: 12),
            sep.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            sep.heightAnchor.constraint(equalToConstant: 1),

            medTitle.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 12),
            medTitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            medTitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            medicationsLabel.topAnchor.constraint(equalTo: medTitle.bottomAnchor, constant: 4),
            medicationsLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            medicationsLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            medicationsLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    // MARK: - Vitals Card
    private func buildVitalsCard() -> UIView {
        let card = whiteCard()

        let header = UILabel()
        header.text = "Real-time Health Vitals"
        header.font = .systemFont(ofSize: 16, weight: .bold)
        header.translatesAutoresizingMaskIntoConstraints = false

        vitalsGridStack.axis = .vertical
        vitalsGridStack.spacing = 8
        vitalsGridStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(header)
        card.addSubview(vitalsGridStack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            vitalsGridStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            vitalsGridStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            vitalsGridStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            vitalsGridStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    // MARK: - Activity Card
    private func buildActivityCard() -> UIView {
        let card = whiteCard()

        let header = UILabel()
        header.text = "Today's Activity"
        header.font = .systemFont(ofSize: 16, weight: .bold)
        header.translatesAutoresizingMaskIntoConstraints = false

        stepsValueLabel.text = "0"
        caloriesValueLabel.text = "0"

        let stepsCell    = makeActivityCell(valueLabel: stepsValueLabel,    unit: "steps",  icon: "👟", title: "Steps",    bg: UIColor(white: 0.96, alpha: 1))
        let caloriesCell = makeActivityCell(valueLabel: caloriesValueLabel, unit: "kcal",   icon: "🔥", title: "Calories", bg: UIColor(red: 1, green: 0.95, blue: 0.93, alpha: 1))

        let row = UIStackView(arrangedSubviews: [stepsCell, caloriesCell])
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(header)
        card.addSubview(row)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            row.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            row.heightAnchor.constraint(equalToConstant: 80)
        ])

        return card
    }

    private func makeActivityCell(valueLabel: UILabel, unit: String, icon: String, title: String, bg: UIColor) -> UIView {
        let cell = UIView()
        cell.backgroundColor = bg
        cell.layer.cornerRadius = 10

        let numLabel = UILabel()
        numLabel.font = .systemFont(ofSize: 20, weight: .bold)
        numLabel.textAlignment = .center
        numLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = .systemFont(ofSize: 13)
        unitLabel.textColor = UIColor(white: 0.4, alpha: 1)
        unitLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueRow = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueRow.axis = .horizontal
        valueRow.spacing = 4
        valueRow.alignment = .firstBaseline
        valueRow.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 14)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = UIColor(white: 0.4, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconRow = UIStackView(arrangedSubviews: [iconLabel, titleLabel])
        iconRow.axis = .horizontal
        iconRow.spacing = 4
        iconRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [valueRow, iconRow])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }

    // MARK: - Location Section
    private func buildLocationSection() -> UIView {
        let card = whiteCard()

        let header = UILabel()
        header.text = "Last Known Location"
        header.font = .systemFont(ofSize: 16, weight: .bold)
        header.translatesAutoresizingMaskIntoConstraints = false

        mapView.layer.cornerRadius = 10
        mapView.clipsToBounds = true
        mapView.isScrollEnabled = false
        mapView.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(header)
        card.addSubview(mapView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            mapView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            mapView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            mapView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            mapView.heightAnchor.constraint(equalToConstant: 200),
            mapView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    // MARK: - Disassociate Button
    private func buildDisassociateButton() {
        disassociateButton.setTitle("Remove Linked Account", for: .normal)
        disassociateButton.setTitleColor(.white, for: .normal)
        disassociateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        disassociateButton.backgroundColor = UIColor(red: 0.87, green: 0.24, blue: 0.24, alpha: 1)
        disassociateButton.layer.cornerRadius = 10
        disassociateButton.translatesAutoresizingMaskIntoConstraints = false
        disassociateButton.addTarget(self, action: #selector(disassociateTapped), for: .touchUpInside)
    }

    @objc private func disassociateTapped() {
        let alert = UIAlertController(
            title: "Remove Linked Account",
            message: "Are you sure you want to remove this linked account?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            Toast.show(message: "Unable to remove linked account. Please try again later.", in: self?.view ?? UIView())
        })
        present(alert, animated: true)
    }

    // MARK: - Data Binding — Ring Data
    private func bindRingData(_ response: LastRingDataResponse) {
        lastRingData = response

        // Vitals
        vitalsGridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let vitalTypes: [(type: String, emoji: String, color: UIColor, bg: UIColor)] = [
            ("heart_rate",    "❤️",  UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 1), UIColor(red: 1, green: 0.93, blue: 0.93, alpha: 1)),
            ("hrv",           "📊",  UIColor(red: 0.13, green: 0.56, blue: 0.27, alpha: 1), UIColor(red: 0.91, green: 1.00, blue: 0.94, alpha: 1)),
            ("blood_pressure","✏️",  UIColor(red: 0.90, green: 0.55, blue: 0.10, alpha: 1), UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)),
            ("blood_oxygen",  "🫁",  UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 1), UIColor(red: 1, green: 0.93, blue: 0.93, alpha: 1)),
            ("blood_sugar",   "💧",  UIColor(red: 0.80, green: 0.55, blue: 0.10, alpha: 1), UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)),
            ("temperature",   "🌡️", UIColor(red: 0.55, green: 0.15, blue: 0.70, alpha: 1), UIColor(red: 0.97, green: 0.91, blue: 1.00, alpha: 1)),
            ("stress",        "🧠",  UIColor(red: 0.20, green: 0.40, blue: 0.80, alpha: 1), UIColor(red: 0.90, green: 0.93, blue: 1.00, alpha: 1)),
            ("sleep",         "😴",  UIColor(red: 0.60, green: 0.45, blue: 0.00, alpha: 1), UIColor(red: 1.00, green: 0.97, blue: 0.82, alpha: 1))
        ]

        // Pair vitals into rows of 2
        var pairBuffer: [UIView] = []
        for vt in vitalTypes {
            if let item = response.data.first(where: { $0.type == vt.type }) {
                let displayValue = formattedValue(for: item.type, rawValue: "\(item.value)")
                let cell = makeVitalCell(emoji: vt.emoji, value: displayValue, label: formatType(item.type), valueColor: vt.color, bg: vt.bg)
                pairBuffer.append(cell)
                if pairBuffer.count == 2 {
                    vitalsGridStack.addArrangedSubview(makeVitalRow(pairBuffer))
                    pairBuffer = []
                }
            }
        }
        if !pairBuffer.isEmpty {
            // pad with empty cell
            pairBuffer.append(UIView())
            vitalsGridStack.addArrangedSubview(makeVitalRow(pairBuffer))
        }

        // Activity
        let steps    = response.data.first(where: { $0.type == "steps" })
        let calories = response.data.first(where: { $0.type == "calories" })
        stepsValueLabel.text    = steps    != nil ? "\(steps!.value)"    : "0"
        caloriesValueLabel.text = calories != nil ? "\(calories!.value)" : "0"

        // Map
        if let loc = response.location,
           let latStr = loc.latitude, let lonStr = loc.longitude,
           let lat = Double(latStr), let lon = Double(lonStr) {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let pin = MKPointAnnotation()
            pin.coordinate = coord
            pin.title = linkedAccountName
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(pin)
            mapView.setRegion(MKCoordinateRegion(center: coord, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: false)
        }
    }

    private func makeVitalRow(_ cells: [UIView]) -> UIView {
        let row = UIStackView(arrangedSubviews: cells)
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        return row
    }

    private func makeVitalCell(emoji: String, value: String, label: String, valueColor: UIColor, bg: UIColor) -> UIView {
        let cell = UIView()
        cell.backgroundColor = bg
        cell.layer.cornerRadius = 10

        let valLabel = UILabel()
        valLabel.text = value
        valLabel.font = .systemFont(ofSize: 16, weight: .bold)
        valLabel.textColor = valueColor
        valLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = emoji
        iconLabel.font = .systemFont(ofSize: 13)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = UIColor(white: 0.4, alpha: 1)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconRow = UIStackView(arrangedSubviews: [iconLabel, nameLabel])
        iconRow.axis = .horizontal
        iconRow.spacing = 4
        iconRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [valLabel, iconRow])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -10),
            cell.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])

        return cell
    }

    // MARK: - Data Binding — Profile
    private func bindProfile(_ p: ProfileDataResponse.ProfileData) {
        profileData = p

        let gender = p.gender ?? "--"
        ageGenderLabel.text = "\(p.age) years · \(gender)"

        let h = p.height ?? "--"
        let w = p.weight ?? "--"
        heightWeightLabel.text = "\(h) cm · \(w) kg"

        bloodGroupValueLabel.text = p.blood_group ?? "--"
        patientIdValueLabel.text  = p.patient_code
        allergyValueLabel.text    = p.allergy == 0 ? "No" : "Yes"

        conditionsLabel.text  = p.existing_diseases  ?? "--"
        medicationsLabel.text = p.existing_medications ?? "--"
    }

    // MARK: - Helpers
    private func whiteCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeSeparator(vertical: Bool = false) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.88, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func formatType(_ type: String) -> String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func formattedValue(for type: String, rawValue: String) -> String {
        let v = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type.lowercased() {
        case "heart_rate":      return "\(v) bpm"
        case "hrv":             return "\(v) ms"
        case "blood_oxygen":    return "\(v)%"
        case "blood_sugar":     return "\(v) mg/dL"
        case "blood_pressure":  return "\(v) mmHg"
        case "temperature":     return "\(v) °F"
        case "stress":          return "\(v) units"
        case "sleep":
            if let mins = Int(v) { return "\(mins / 60)h \(mins % 60)m" }
            return v
        default: return v
        }
    }
}

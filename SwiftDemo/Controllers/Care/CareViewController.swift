import UIKit

enum AssociationStep {
    case enterPhone
    case verifyOtp
}

final class CareViewController: AppBaseViewController,
                               UITableViewDataSource,
                               UITableViewDelegate {

    // MARK: - Data
    private var linkedAccounts: [LinkedAccountInfo] = []
    private let userId: Int = UserDefaults.standard.integer(forKey: "id")

    // MARK: - Filled State UI
    private let filledStateView = UIView()
    private let linkedAccountsLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let tableView = UITableView()

    // MARK: - Empty State UI (ScrollView so content fits any screen)
    private let emptyScrollView = UIScrollView()
    private let emptyContentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Family Care"
        setupUI()
        fetchLinkedAccounts()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.99, alpha: 1) // light blue

        setupFilledState()
        setupEmptyState()
    }

    // MARK: - Filled State
    private func setupFilledState() {
        filledStateView.translatesAutoresizingMaskIntoConstraints = false
        filledStateView.isHidden = true
        view.addSubview(filledStateView)

        // "Linked Accounts" label
        linkedAccountsLabel.text = "Linked Accounts"
        linkedAccountsLabel.font = .systemFont(ofSize: 20, weight: .bold)
        linkedAccountsLabel.textColor = .black
        linkedAccountsLabel.translatesAutoresizingMaskIntoConstraints = false

        // "+ Add" button
        addButton.setTitle("+ Add", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addButton.backgroundColor = UIColor(red: 0.00, green: 0.58, blue: 0.97, alpha: 1)
        addButton.layer.cornerRadius = 14
        addButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addAssociationTapped), for: .touchUpInside)

        // TableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(LinkedAccountCell.self, forCellReuseIdentifier: LinkedAccountCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)

        filledStateView.addSubview(linkedAccountsLabel)
        filledStateView.addSubview(addButton)
        filledStateView.addSubview(tableView)

        NSLayoutConstraint.activate([
            filledStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filledStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filledStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filledStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            linkedAccountsLabel.topAnchor.constraint(equalTo: filledStateView.topAnchor, constant: 16),
            linkedAccountsLabel.leadingAnchor.constraint(equalTo: filledStateView.leadingAnchor, constant: 16),

            addButton.centerYAnchor.constraint(equalTo: linkedAccountsLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: filledStateView.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            tableView.topAnchor.constraint(equalTo: linkedAccountsLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: filledStateView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: filledStateView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: filledStateView.bottomAnchor)
        ])
    }

    // MARK: - Empty State
    private func setupEmptyState() {
        emptyScrollView.translatesAutoresizingMaskIntoConstraints = false
        emptyScrollView.alwaysBounceVertical = true
        emptyContentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyScrollView)
        emptyScrollView.addSubview(emptyContentView)

        NSLayoutConstraint.activate([
            emptyScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyContentView.topAnchor.constraint(equalTo: emptyScrollView.topAnchor),
            emptyContentView.leadingAnchor.constraint(equalTo: emptyScrollView.leadingAnchor),
            emptyContentView.trailingAnchor.constraint(equalTo: emptyScrollView.trailingAnchor),
            emptyContentView.bottomAnchor.constraint(equalTo: emptyScrollView.bottomAnchor),
            emptyContentView.widthAnchor.constraint(equalTo: emptyScrollView.widthAnchor)
        ])

        // ── Hero card ──
        let heroCard = makeHeroCard()
        emptyContentView.addSubview(heroCard)

        // ── How-To card ──
        let howToCard = makeHowToCard()
        emptyContentView.addSubview(howToCard)

        // ── "Link Account Now" button ──
        let linkBtn = UIButton(type: .system)
        linkBtn.setTitle("Link Account Now", for: .normal)
        linkBtn.setTitleColor(.white, for: .normal)
        linkBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        linkBtn.backgroundColor = UIColor(red: 0.00, green: 0.58, blue: 0.97, alpha: 1)
        linkBtn.layer.cornerRadius = 22
        linkBtn.translatesAutoresizingMaskIntoConstraints = false
        linkBtn.addTarget(self, action: #selector(addAssociationTapped), for: .touchUpInside)
        emptyContentView.addSubview(linkBtn)

        // ── Disclaimer label ──
        let disclaimer = UILabel()
        disclaimer.text = "Link the account to view the wearer's health data in real time.\nPlease make sure to obtain the wearer's consent."
        disclaimer.font = .systemFont(ofSize: 12)
        disclaimer.textColor = UIColor(white: 0.4, alpha: 1)
        disclaimer.textAlignment = .center
        disclaimer.numberOfLines = 0
        disclaimer.translatesAutoresizingMaskIntoConstraints = false
        emptyContentView.addSubview(disclaimer)

        NSLayoutConstraint.activate([
            heroCard.topAnchor.constraint(equalTo: emptyContentView.topAnchor, constant: 16),
            heroCard.leadingAnchor.constraint(equalTo: emptyContentView.leadingAnchor, constant: 16),
            heroCard.trailingAnchor.constraint(equalTo: emptyContentView.trailingAnchor, constant: -16),

            howToCard.topAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: 16),
            howToCard.leadingAnchor.constraint(equalTo: emptyContentView.leadingAnchor, constant: 16),
            howToCard.trailingAnchor.constraint(equalTo: emptyContentView.trailingAnchor, constant: -16),

            linkBtn.topAnchor.constraint(equalTo: howToCard.bottomAnchor, constant: 24),
            linkBtn.centerXAnchor.constraint(equalTo: emptyContentView.centerXAnchor),
            linkBtn.widthAnchor.constraint(equalToConstant: 220),
            linkBtn.heightAnchor.constraint(equalToConstant: 44),

            disclaimer.topAnchor.constraint(equalTo: linkBtn.bottomAnchor, constant: 12),
            disclaimer.leadingAnchor.constraint(equalTo: emptyContentView.leadingAnchor, constant: 32),
            disclaimer.trailingAnchor.constraint(equalTo: emptyContentView.trailingAnchor, constant: -32),
            disclaimer.bottomAnchor.constraint(equalTo: emptyContentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Hero Card
    private func makeHeroCard() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(named: "hearto_care"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(imageView)

        // Gradient overlay
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.65).cgColor]
        gradient.locations = [0.3, 1.0]
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(overlayView)
        overlayView.layer.addSublayer(gradient)
        overlayView.layoutIfNeeded()

        let title = UILabel()
        title.text = "No Account Linked Yet"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "Add your loved ones to monitor their health"
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(title)
        card.addSubview(subtitle)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: card.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            card.heightAnchor.constraint(equalToConstant: 220),

            overlayView.topAnchor.constraint(equalTo: card.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            subtitle.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            subtitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            title.bottomAnchor.constraint(equalTo: subtitle.topAnchor, constant: -4),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        // Update gradient frame after layout
        DispatchQueue.main.async {
            gradient.frame = overlayView.bounds
        }

        return card
    }

    // MARK: - How-To Card
    private func makeHowToCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false

        let header = UILabel()
        header.text = "How to Add Your Loved Ones"
        header.font = .systemFont(ofSize: 17, weight: .bold)
        header.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)

        let steps = [
            "Ensure your family member has registered on the HEARTO app with their mobile number",
            "Click 'Link account now' button below",
            "Enter their mobile number and get verification code",
            "Ask them for the OTP, enter it and select relationship to complete linking"
        ]

        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 14
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        for (i, text) in steps.enumerated() {
            stepsStack.addArrangedSubview(makeStepRow(number: i + 1, text: text))
        }

        card.addSubview(stepsStack)

        // Orange note box
        let noteBox = UIView()
        noteBox.backgroundColor = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
        noteBox.layer.cornerRadius = 8
        noteBox.translatesAutoresizingMaskIntoConstraints = false

        let noteIcon = UILabel()
        noteIcon.text = "ⓘ"
        noteIcon.textColor = UIColor(red: 0.93, green: 0.60, blue: 0.07, alpha: 1)
        noteIcon.font = .systemFont(ofSize: 14, weight: .bold)
        noteIcon.translatesAutoresizingMaskIntoConstraints = false

        let noteText = UILabel()
        noteText.text = "Note: Once linked, you can monitor their health vitals and receive alerts for any abnormalities."
        noteText.font = .systemFont(ofSize: 12)
        noteText.textColor = UIColor(red: 0.70, green: 0.35, blue: 0.00, alpha: 1)
        noteText.numberOfLines = 0
        noteText.translatesAutoresizingMaskIntoConstraints = false

        noteBox.addSubview(noteIcon)
        noteBox.addSubview(noteText)
        card.addSubview(noteBox)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            stepsStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            stepsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stepsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            noteBox.topAnchor.constraint(equalTo: stepsStack.bottomAnchor, constant: 16),
            noteBox.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            noteBox.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            noteBox.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            noteIcon.topAnchor.constraint(equalTo: noteBox.topAnchor, constant: 10),
            noteIcon.leadingAnchor.constraint(equalTo: noteBox.leadingAnchor, constant: 12),

            noteText.topAnchor.constraint(equalTo: noteBox.topAnchor, constant: 10),
            noteText.leadingAnchor.constraint(equalTo: noteIcon.trailingAnchor, constant: 8),
            noteText.trailingAnchor.constraint(equalTo: noteBox.trailingAnchor, constant: -12),
            noteText.bottomAnchor.constraint(equalTo: noteBox.bottomAnchor, constant: -10)
        ])

        return card
    }

    private func makeStepRow(number: Int, text: String) -> UIView {
        let badge = UILabel()
        badge.text = "\(number)"
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 0.00, green: 0.58, blue: 0.97, alpha: 1)
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(white: 0.2, alpha: 1)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let row = UIView()
        row.addSubview(badge)
        row.addSubview(label)

        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            badge.topAnchor.constraint(equalTo: row.topAnchor),
            badge.widthAnchor.constraint(equalToConstant: 24),
            badge.heightAnchor.constraint(equalToConstant: 24),

            label.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            label.topAnchor.constraint(equalTo: row.topAnchor),
            label.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }

    // MARK: - API
    private func fetchLinkedAccounts() {
        LinkedAccountService.shared.getLinkedAccountData(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let list) = result {
                    self?.linkedAccounts = list
                    self?.updateUIForDataState()
                }
            }
        }
    }

    // MARK: - UI State
    private func updateUIForDataState() {
        let hasData = !linkedAccounts.isEmpty
        filledStateView.isHidden = !hasData
        emptyScrollView.isHidden = hasData
        tableView.reloadData()
    }

    @objc private func addAssociationTapped() {
        let vc = AddAssociationViewController()
        vc.onSuccess = { [weak self] in
            self?.fetchLinkedAccounts()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CareViewController {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        linkedAccounts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: LinkedAccountCell.reuseId,
            for: indexPath
        ) as! LinkedAccountCell

        cell.configure(with: linkedAccounts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let account = linkedAccounts[indexPath.row]
        let vc = LinkedAccountDetailsViewController()
        vc.linkedAccountId = account.id
        vc.linkedAccountName = account.name
        vc.linkedAccountRelation = account.relation
        navigationController?.pushViewController(vc, animated: true)
    }
}

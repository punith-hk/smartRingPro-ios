import UIKit

// MARK: - NotificationsViewController

final class NotificationsViewController: UIViewController {

    // MARK: - Properties
    private let userId = UserDefaultsManager.shared.userId
    private var items: [NotificationItem] = []

    // MARK: - UI
    private let tableView   = UITableView(frame: .zero, style: .plain)
    private let loadingView = UIView()
    private let emptyView   = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = UIColor(red: 242/255, green: 244/255, blue: 247/255, alpha: 1)
        setupTableView()
        setupLoadingView()
        setupEmptyView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchNotifications()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseId)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.isHidden   = true
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLoadingView() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)
        spinner.startAnimating()

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading notifications..."
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center

        loadingView.addSubview(stack)
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            loadingView.widthAnchor.constraint(equalTo: view.widthAnchor),
            loadingView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func setupEmptyView() {
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true

        let icon = UIImageView(image: UIImage(systemName: "bell.slash"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1)
        icon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No notifications yet"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)
        titleLabel.textAlignment = .center

        let subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "You don't have any notifications at the moment"
        subLabel.font = .systemFont(ofSize: 14)
        subLabel.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center

        emptyView.addSubview(stack)
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            icon.widthAnchor.constraint(equalToConstant: 80),
            icon.heightAnchor.constraint(equalToConstant: 80),
            stack.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: emptyView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor)
        ])
    }

    // MARK: - Data Fetch

    private func showLoading() {
        loadingView.isHidden = false
        tableView.isHidden   = true
        emptyView.isHidden   = true
    }

    private func showList() {
        loadingView.isHidden = true
        tableView.isHidden   = false
        emptyView.isHidden   = true
    }

    private func showEmpty() {
        loadingView.isHidden = true
        tableView.isHidden   = true
        emptyView.isHidden   = false
    }

    private func fetchNotifications() {
        guard userId > 0 else { showEmpty(); return }

        // Use cache if still valid
        if NotificationCache.shared.isValid {
            items = NotificationCache.shared.all
            tableView.reloadData()
            items.isEmpty ? showEmpty() : showList()
            return
        }

        showLoading()
        NotificationService.shared.getNotifications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.items = response.data
                    NotificationCache.shared.update(response.data)
                    self.tableView.reloadData()
                    self.updateNavBadge()
                    response.data.isEmpty ? self.showEmpty() : self.showList()
                case .failure:
                    self.items.isEmpty ? self.showEmpty() : self.showList()
                }
            }
        }
    }

    private func updateNavBadge() {
        // Walk up to find AppBaseViewController to update badge
        if let base = navigationController?.viewControllers.first(where: { $0 is AppBaseViewController }) as? AppBaseViewController {
            base.updateNotificationBadge(count: NotificationCache.shared.unreadCount)
        }
    }

    // MARK: - Mark as Read

    private func markAsRead(item: NotificationItem, at indexPath: IndexPath) {
        guard item.isUnread else { return }
        NotificationService.shared.markAsRead(notificationId: item.id, userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .success = result {
                    self.items[indexPath.row].status = 1
                    NotificationCache.shared.markRead(id: item.id)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    self.updateNavBadge()
                }
            }
        }
    }

    // MARK: - Detail Dialog

    private func showDetail(for item: NotificationItem, at indexPath: IndexPath) {
        markAsRead(item: item, at: indexPath)
        let vc = NotificationDetailViewController(item: item)
        if #available(iOS 15.0, *) {
            vc.modalPresentationStyle = .pageSheet
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
        } else {
            vc.modalPresentationStyle = .formSheet
        }
        present(vc, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseId, for: indexPath) as! NotificationCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDetail(for: items[indexPath.row], at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        110
    }
}

// MARK: - NotificationCell

final class NotificationCell: UITableViewCell {

    static let reuseId = "NotificationCell"

    // Card
    private let card = UIView()

    // Unread dot
    private let dot = UIView()

    // Content
    private let titleLabel   = UILabel()
    private let messageLabel = UILabel()
    private let vitalsRow    = UIStackView()
    private let timeLabel    = UILabel()

    // Chips
    private let chipHR  = NotificationChip(color: UIColor(red: 229/255, green: 57/255,  blue: 53/255,  alpha: 1),
                                           bgColor: UIColor(red: 229/255, green: 57/255,  blue: 53/255,  alpha: 0.1))
    private let chipO2  = NotificationChip(color: UIColor(red: 21/255,  green: 101/255, blue: 192/255, alpha: 1),
                                           bgColor: UIColor(red: 21/255,  green: 101/255, blue: 192/255, alpha: 0.1))
    private let chipBP  = NotificationChip(color: UIColor(red: 46/255,  green: 125/255, blue: 50/255,  alpha: 1),
                                           bgColor: UIColor(red: 46/255,  green: 125/255, blue: 50/255,  alpha: 0.1))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build UI

    private func buildUI() {
        // Card container
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 12
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowOffset  = CGSize(width: 0, height: 3)
        card.layer.shadowRadius  = 6
        card.layer.masksToBounds = false
        contentView.addSubview(card)

        // Unread dot
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = UIColor(red: 13/255, green: 153/255, blue: 255/255, alpha: 1)
        dot.layer.cornerRadius = 4.5
        card.addSubview(dot)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        card.addSubview(titleLabel)

        // Message
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
        messageLabel.numberOfLines = 2
        card.addSubview(messageLabel)

        // Vitals chips row
        vitalsRow.translatesAutoresizingMaskIntoConstraints = false
        vitalsRow.axis = .horizontal
        vitalsRow.spacing = 6
        vitalsRow.alignment = .center
        vitalsRow.addArrangedSubview(chipHR)
        vitalsRow.addArrangedSubview(chipO2)
        vitalsRow.addArrangedSubview(chipBP)
        // spacer so chips stay left-aligned
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        vitalsRow.addArrangedSubview(spacer)
        card.addSubview(vitalsRow)

        // Timestamp
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
        timeLabel.textAlignment = .right
        card.addSubview(timeLabel)

        // Layout
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            dot.widthAnchor.constraint(equalToConstant: 9),
            dot.heightAnchor.constraint(equalToConstant: 9),
            dot.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            dot.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            vitalsRow.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            vitalsRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            vitalsRow.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            timeLabel.topAnchor.constraint(equalTo: vitalsRow.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - Configure

    func configure(with item: NotificationItem) {
        // Background color
        card.backgroundColor = item.isUnread
            ? UIColor(red: 224/255, green: 243/255, blue: 255/255, alpha: 1)   // #E0F3FF
            : .white

        // Dot visibility
        dot.isHidden = !item.isUnread

        // Text
        titleLabel.text   = item.resolvedTitle
        messageLabel.text = item.message
        timeLabel.text    = item.formattedTime

        // Vitals chips
        let vitals = item.parsedVitals
        configureChip(chipHR,
                      text: vitals["heart_rate"].map { "❤️ \($0) bpm" },
                      key: "heart_rate", vitals: vitals)
        configureChip(chipO2,
                      text: vitals["blood_oxygen"].map { "🩸 \($0)%" },
                      key: "blood_oxygen", vitals: vitals)
        configureChip(chipBP,
                      text: vitals["blood_pressure"].map { "🫀 \($0)" },
                      key: "blood_pressure", vitals: vitals)

        vitalsRow.isHidden = vitals.isEmpty
    }

    private func configureChip(_ chip: NotificationChip, text: String?, key: String, vitals: [String: String]) {
        if let t = text {
            chip.setText(t)
            chip.isHidden = false
        } else {
            chip.isHidden = true
        }
    }
}

// MARK: - NotificationChip

final class NotificationChip: UIView {

    private let label = UILabel()

    init(color: UIColor, bgColor: UIColor) {
        super.init(frame: .zero)
        backgroundColor = bgColor
        layer.cornerRadius = 10
        clipsToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = color
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func setText(_ text: String) { label.text = text }
}

// MARK: - NotificationDetailViewController

final class NotificationDetailViewController: UIViewController {

    private let item: NotificationItem

    init(item: NotificationItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        let detailView = NotificationDetailView(item: item)
        detailView.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(detailView)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            detailView.topAnchor.constraint(equalTo: scroll.topAnchor),
            detailView.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            detailView.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }
}

// MARK: - NotificationDetailView

final class NotificationDetailView: UIView {

    private let vitalLabels: [(key: String, label: String, unit: String)] = [
        ("heart_rate",    "❤️  Heart Rate",    "bpm"),
        ("blood_oxygen",  "🩸 Blood Oxygen",   "%"),
        ("blood_pressure","🫀 Blood Pressure",  "mmHg"),
        ("blood_sugar",   "🍬 Blood Sugar",     "mg/dL"),
        ("temperature",   "🌡️ Temperature",     "°C"),
        ("hrv",           "📈 HRV",             "ms")
    ]

    init(item: NotificationItem) {
        super.init(frame: .zero)
        buildUI(item: item)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI(item: NotificationItem) {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill

        // Title
        let titleLbl = UILabel()
        titleLbl.text = item.resolvedTitle
        titleLbl.font = .systemFont(ofSize: 18, weight: .bold)
        titleLbl.textColor = .black
        titleLbl.numberOfLines = 0
        stack.addArrangedSubview(titleLbl)

        // Divider
        stack.addArrangedSubview(makeDivider())

        // Message
        let msgLbl = UILabel()
        msgLbl.text = item.message
        msgLbl.font = .systemFont(ofSize: 15)
        msgLbl.textColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
        msgLbl.numberOfLines = 0
        stack.addArrangedSubview(msgLbl)

        // Timestamp
        let timeLbl = UILabel()
        timeLbl.text = item.formattedTime
        timeLbl.font = .systemFont(ofSize: 13)
        timeLbl.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
        stack.addArrangedSubview(timeLbl)

        // Vitals
        let vitals = item.parsedVitals
        if !vitals.isEmpty {
            stack.addArrangedSubview(makeDivider())

            let vitalHeader = UILabel()
            vitalHeader.text = "Vital Signs"
            vitalHeader.font = .systemFont(ofSize: 14, weight: .semibold)
            vitalHeader.textColor = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
            stack.addArrangedSubview(vitalHeader)

            for entry in vitalLabels {
                guard let value = vitals[entry.key] else { continue }
                let row = makeVitalRow(label: entry.label, value: "\(value) \(entry.unit)")
                stack.addArrangedSubview(row)
            }
        }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func makeVitalRow(label: String, value: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8

        let labelLbl = UILabel()
        labelLbl.text = label
        labelLbl.font = .systemFont(ofSize: 14)
        labelLbl.textColor = .black
        labelLbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .systemFont(ofSize: 14, weight: .bold)
        valueLbl.textColor = .black
        valueLbl.textAlignment = .right

        row.addArrangedSubview(labelLbl)
        row.addArrangedSubview(valueLbl)
        return row
    }
}

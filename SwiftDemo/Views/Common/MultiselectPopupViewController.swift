import UIKit

final class MultiSelectPopupViewController: UIViewController {

    // MARK: - Configuration
    private let titleText: String
    private let options: [String]
    private let maxSelection: Int?
    private var selectedItems: [String]   // 🔥 ARRAY (ORDERED)

    var onConfirm: (([String]) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UI
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let cancelButton = UIButton(type: .system)
    private let okButton = UIButton(type: .system)

    // MARK: - Init
    init(
        title: String,
        options: [String],
        preselected: [String] = [],
        maxSelection: Int? = nil
    ) {
        self.titleText = title
        self.options = options
        self.selectedItems = preselected
        self.maxSelection = maxSelection
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupContainer()
        setupHeader()
        setupTable()
        setupFooter()
    }

    // MARK: - Background
    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    // MARK: - Container
    private func setupContainer() {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 14
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        ])
    }

    // MARK: - Header
    private func setupHeader() {
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Table
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(MultiSelectCell.self, forCellReuseIdentifier: MultiSelectCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.tableFooterView = UIView()

        containerView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -72)
        ])
    }

    // MARK: - Footer
    private func setupFooter() {
        let footerStack = UIStackView(arrangedSubviews: [cancelButton, okButton])
        footerStack.axis = .horizontal
        footerStack.spacing = 16
        footerStack.distribution = .fillEqually
        footerStack.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        okButton.setTitle("OK", for: .normal)
        okButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        okButton.setTitleColor(.white, for: .normal)
        okButton.layer.cornerRadius = 8
        okButton.addTarget(self, action: #selector(okTapped), for: .touchUpInside)

        containerView.addSubview(footerStack)

        NSLayoutConstraint.activate([
            footerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            footerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            footerStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            footerStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true) { self.onCancel?() }
    }

    @objc private func okTapped() {
        dismiss(animated: true) { self.onConfirm?(self.selectedItems) }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MultiSelectPopupViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: MultiSelectCell.reuseId,
            for: indexPath
        ) as! MultiSelectCell

        let value = options[indexPath.row]
        let isSelected = selectedItems.contains(value)

        // ✅ Disable ONLY for multi-select mode
        let isDisabled =
            maxSelection != nil &&
            maxSelection! > 1 &&
            selectedItems.count >= maxSelection! &&
            !isSelected

        cell.configure(
            title: value,
            selected: isSelected,
            disabled: isDisabled
        )

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let value = options[indexPath.row]

        // ✅ SINGLE SELECT MODE
        if maxSelection == 1 {
            selectedItems = [value]

            dismiss(animated: true) {
                self.onConfirm?(self.selectedItems)
            }
            return
        }

        // ✅ MULTI SELECT MODE
        if !selectedItems.contains(value) {
            if let limit = maxSelection, selectedItems.count >= limit {
                return
            }
            selectedItems.append(value)
        }

        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let value = options[indexPath.row]
        selectedItems.removeAll { $0 == value }
        tableView.reloadData()
    }
}

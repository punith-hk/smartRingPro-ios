import UIKit

final class DiseasePickerViewController: UIViewController {

    var onConfirm: (([String]) -> Void)?

    private var entries: [String]
    private let maxEntries = 5

    // MARK: - UI
    private let containerView  = UIView()
    private let titleLabel     = UILabel()
    private let rowsStack      = UIStackView()
    private let addButton      = UIButton(type: .system)
    private let cancelButton   = UIButton(type: .system)
    private let updateButton   = UIButton(type: .system)

    private let navBlue = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)

    // MARK: - Init
    init(current: [String]) {
        self.entries = current.isEmpty ? [""] : current
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupContainer()
        refreshRows()
    }

    // MARK: - Background
    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if !containerView.frame.contains(loc) { dismiss(animated: true) }
    }

    // MARK: - Container
    private func setupContainer() {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        titleLabel.text = "Existing Diseases"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        rowsStack.axis    = .vertical
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(rowsStack)

        addButton.setTitle("＋ Add Disease", for: .normal)
        addButton.setTitleColor(navBlue, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addRowTapped), for: .touchUpInside)
        containerView.addSubview(addButton)

        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.88, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(divider)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemGray, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        updateButton.setTitle("Update", for: .normal)
        updateButton.setTitleColor(navBlue, for: .normal)
        updateButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        updateButton.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
        updateButton.translatesAutoresizingMaskIntoConstraints = false

        let footerStack = UIStackView(arrangedSubviews: [cancelButton, updateButton])
        footerStack.axis         = .horizontal
        footerStack.distribution = .fillEqually
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(footerStack)

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            rowsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            rowsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            rowsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            addButton.topAnchor.constraint(equalTo: rowsStack.bottomAnchor, constant: 10),
            addButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            divider.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            footerStack.topAnchor.constraint(equalTo: divider.bottomAnchor),
            footerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            footerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            footerStack.heightAnchor.constraint(equalToConstant: 48),
            footerStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    // MARK: - Rows
    private func refreshRows() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for index in entries.indices {
            rowsStack.addArrangedSubview(makeRow(at: index))
        }
        addButton.isHidden = entries.count >= maxEntries
    }

    private func makeRow(at index: Int) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let nameField = UITextField()
        nameField.placeholder     = "Disease name"
        nameField.text            = entries[index]
        nameField.tag             = index
        nameField.borderStyle     = .roundedRect
        nameField.font            = .systemFont(ofSize: 14)
        nameField.autocorrectionType = .no
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)

        let delBtn = UIButton(type: .system)
        delBtn.setImage(UIImage(systemName: "trash"), for: .normal)
        delBtn.tintColor = .systemRed
        delBtn.tag       = index
        delBtn.translatesAutoresizingMaskIntoConstraints = false
        delBtn.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)

        row.addSubview(nameField)
        row.addSubview(delBtn)

        NSLayoutConstraint.activate([
            delBtn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            delBtn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            delBtn.widthAnchor.constraint(equalToConstant: 32),
            delBtn.heightAnchor.constraint(equalToConstant: 36),

            nameField.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            nameField.trailingAnchor.constraint(equalTo: delBtn.leadingAnchor, constant: -6),
            nameField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameField.heightAnchor.constraint(equalToConstant: 36),
        ])

        return row
    }

    // MARK: - Actions
    @objc private func nameChanged(_ sender: UITextField) {
        guard sender.tag < entries.count else { return }
        entries[sender.tag] = sender.text ?? ""
    }

    @objc private func deleteTapped(_ sender: UIButton) {
        guard sender.tag < entries.count else { return }
        view.endEditing(true)
        entries.remove(at: sender.tag)
        if entries.isEmpty { entries.append("") }
        refreshRows()
    }

    @objc private func addRowTapped() {
        guard entries.count < maxEntries else { return }
        view.endEditing(true)
        entries.append("")
        refreshRows()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func updateTapped() {
        view.endEditing(true)
        let result = entries.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        dismiss(animated: true) { self.onConfirm?(result) }
    }
}

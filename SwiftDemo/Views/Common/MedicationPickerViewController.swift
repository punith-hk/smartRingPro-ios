import UIKit

final class MedicationPickerViewController: UIViewController {

    var onConfirm: (([MedicationEntry]) -> Void)?

    private var entries: [MedicationEntry]
    private let maxEntries = 5

    // MARK: - UI
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let addButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let updateButton = UIButton(type: .system)
    private var containerCenterY: NSLayoutConstraint!

    private let navBlue = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)
    private let timingGreen = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1)

    // MARK: - Init
    init(current: [MedicationEntry]) {
        if current.isEmpty {
            self.entries = [MedicationEntry(name: "", morning: false, afternoon: false, night: false)]
        } else {
            self.entries = current
        }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupContainer()
        refreshRows()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if !containerView.frame.contains(loc) {
            dismiss(animated: true)
        }
    }

    private func setupContainer() {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Title
        titleLabel.text = "Existing Medication"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Rows stack directly in container
        rowsStack.axis = .vertical
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(rowsStack)

        // Add button
        addButton.setTitle("＋ Add Medication", for: .normal)
        addButton.setTitleColor(navBlue, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addRowTapped), for: .touchUpInside)
        containerView.addSubview(addButton)

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.88, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(divider)

        // Footer
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
        footerStack.axis = .horizontal
        footerStack.distribution = .fillEqually
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(footerStack)

        containerCenterY = containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        NSLayoutConstraint.activate([
            // Container
            containerCenterY,
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Rows stack
            rowsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            rowsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            rowsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Add button
            addButton.topAnchor.constraint(equalTo: rowsStack.bottomAnchor, constant: 10),
            addButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            // Divider
            divider.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            // Footer
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
        let entry = entries[index]

        // Card container
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.97, alpha: 1)
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let doneBar = makeDoneToolbar()

        // Name field (75%)
        let nameField = UITextField()
        nameField.placeholder = "Medication name"
        nameField.text = entry.name
        nameField.tag = index * 10 + 1
        nameField.font = .systemFont(ofSize: 14)
        nameField.borderStyle = .roundedRect
        nameField.autocorrectionType = .no
        nameField.inputAccessoryView = doneBar
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)

        // Dosage field (25%)
        let dosageField = UITextField()
        dosageField.placeholder = "Dosage"
        dosageField.text = entry.dosage
        dosageField.tag = index * 10 + 5
        dosageField.font = .systemFont(ofSize: 14)
        dosageField.borderStyle = .roundedRect
        dosageField.autocorrectionType = .no
        dosageField.inputAccessoryView = makeDoneToolbar()
        dosageField.translatesAutoresizingMaskIntoConstraints = false
        dosageField.addTarget(self, action: #selector(dosageChanged(_:)), for: .editingChanged)

        // Delete button
        let delBtn = UIButton(type: .system)
        delBtn.setImage(UIImage(systemName: "trash"), for: .normal)
        delBtn.tintColor = .systemRed
        delBtn.tag = index
        delBtn.translatesAutoresizingMaskIntoConstraints = false
        delBtn.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)

        // Separator between input row and timing row
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.88, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false

        // Timing label
        let timingLabel = UILabel()
        timingLabel.text = "Timing"
        timingLabel.font = .systemFont(ofSize: 11, weight: .medium)
        timingLabel.textColor = .systemGray
        timingLabel.translatesAutoresizingMaskIntoConstraints = false

        // Full-text timing toggle buttons
        let mBtn = makeToggle(title: "Morning",   isOn: entry.morning,   tag: index * 10 + 2)
        let aBtn = makeToggle(title: "Afternoon", isOn: entry.afternoon, tag: index * 10 + 3)
        let nBtn = makeToggle(title: "Night",     isOn: entry.night,     tag: index * 10 + 4)

        let timingStack = UIStackView(arrangedSubviews: [mBtn, aBtn, nBtn])
        timingStack.axis = .horizontal
        timingStack.spacing = 8
        timingStack.distribution = .fillEqually
        timingStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(nameField)
        card.addSubview(dosageField)
        card.addSubview(delBtn)
        card.addSubview(separator)
        card.addSubview(timingLabel)
        card.addSubview(timingStack)

        NSLayoutConstraint.activate([
            // Delete — top right
            delBtn.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            delBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            delBtn.widthAnchor.constraint(equalToConstant: 30),
            delBtn.heightAnchor.constraint(equalToConstant: 34),

            // Dosage — 25%, left of delete
            dosageField.centerYAnchor.constraint(equalTo: delBtn.centerYAnchor),
            dosageField.trailingAnchor.constraint(equalTo: delBtn.leadingAnchor, constant: -6),
            dosageField.heightAnchor.constraint(equalToConstant: 34),

            // Name — 75% (3× dosage width), left of dosage
            nameField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            nameField.centerYAnchor.constraint(equalTo: delBtn.centerYAnchor),
            nameField.trailingAnchor.constraint(equalTo: dosageField.leadingAnchor, constant: -6),
            nameField.heightAnchor.constraint(equalToConstant: 34),
            nameField.widthAnchor.constraint(equalTo: dosageField.widthAnchor, multiplier: 3),

            // Separator
            separator.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            // Timing label
            timingLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            timingLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),

            // Timing buttons
            timingStack.topAnchor.constraint(equalTo: timingLabel.bottomAnchor, constant: 6),
            timingStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            timingStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            timingStack.heightAnchor.constraint(equalToConstant: 36),
            timingStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
        ])

        return card
    }

    private func makeToggle(title: String, isOn: Bool, tag: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.tag = tag
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 1.5
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        applyToggleStyle(btn, isOn: isOn)
        btn.addTarget(self, action: #selector(toggleTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func applyToggleStyle(_ btn: UIButton, isOn: Bool) {
        if isOn {
            btn.backgroundColor = timingGreen
            btn.setTitleColor(.white, for: .normal)
            btn.layer.borderColor = timingGreen.cgColor
        } else {
            btn.backgroundColor = .white
            btn.setTitleColor(timingGreen, for: .normal)
            btn.layer.borderColor = timingGreen.cgColor
        }
    }

    // MARK: - Actions

    @objc private func nameChanged(_ sender: UITextField) {
        let index = sender.tag / 10
        guard index < entries.count else { return }
        entries[index].name = sender.text ?? ""
    }

    @objc private func dosageChanged(_ sender: UITextField) {
        let index = sender.tag / 10
        guard index < entries.count else { return }
        entries[index].dosage = sender.text ?? ""
    }

    @objc private func toggleTapped(_ sender: UIButton) {
        let index = sender.tag / 10
        let slot = sender.tag % 10
        guard index < entries.count else { return }
        switch slot {
        case 2:
            entries[index].morning.toggle()
            applyToggleStyle(sender, isOn: entries[index].morning)
        case 3:
            entries[index].afternoon.toggle()
            applyToggleStyle(sender, isOn: entries[index].afternoon)
        case 4:
            entries[index].night.toggle()
            applyToggleStyle(sender, isOn: entries[index].night)
        default:
            break
        }
    }

    @objc private func deleteTapped(_ sender: UIButton) {
        guard sender.tag < entries.count else { return }
        // Flush any in-flight text edits before deletion
        view.endEditing(true)
        entries.remove(at: sender.tag)
        if entries.isEmpty {
            entries.append(MedicationEntry(name: "", morning: false, afternoon: false, night: false))
        }
        refreshRows()
    }

    @objc private func addRowTapped() {
        guard entries.count < maxEntries else { return }
        view.endEditing(true)
        entries.append(MedicationEntry(name: "", morning: false, afternoon: false, night: false))
        refreshRows()
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let kbFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let kbTop = view.bounds.height - kbFrame.height
        let containerMidY = containerView.bounds.height / 2
        // Keep 12pt gap between container bottom and keyboard top
        let desiredCenter = kbTop - containerView.bounds.height - 12 + containerMidY
        let maxOffset = view.bounds.height / 2 - containerMidY - 16
        containerCenterY.constant = max(-maxOffset, desiredCenter - view.bounds.height / 2)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) else { return }
        containerCenterY.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    private func makeDoneToolbar() -> UIToolbar {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        bar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        bar.items = [flex, done]
        return bar
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func updateTapped() {
        view.endEditing(true)
        let filtered = entries.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        onConfirm?(filtered)
        dismiss(animated: true)
    }
}

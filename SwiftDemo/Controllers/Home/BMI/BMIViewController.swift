import UIKit

final class BMIViewController: AppBaseViewController {

    // MARK: - UI

    private let scrollView  = UIScrollView()
    private let contentView = UIView()
    private let meterView   = BMIMeterView()
    private var meterHeightConstraint: NSLayoutConstraint!

    private let heightRow   = BMIPickerRowView()
    private let weightRow   = BMIPickerRowView()
    private let updateBtn   = UIButton(type: .system)

    // MARK: - State

    private var selectedHeight: Int = 0
    private var selectedWeight: Int = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Body Mass Index")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

        setupScrollView()
        buildUI()
        meterView.isOpaque = false
        meterView.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedValues()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Size the meter view height to match its computed needs
        let w = meterView.bounds.width
        if w > 1 {
            let needed = meterView.neededHeight(for: w)
            if abs(meterHeightConstraint.constant - needed) > 1 {
                meterHeightConstraint.constant = needed
            }
        }
    }

    // MARK: - Scroll view / content setup

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - Build UI

    private func buildUI() {
        let card = makeCard()

        // "BMI Meter" card title
        let cardTitle = makeLabel("BMI Meter", font: .systemFont(ofSize: 16, weight: .semibold), color: .black)

        // Meter view
        meterView.translatesAutoresizingMaskIntoConstraints = false
        // Estimate the meter width (screen - card padding 16*2 - meter inset 12*2) so the
        // initial height is already correct on the very first layout pass — no blank gap.
        let estimatedMeterW = UIScreen.main.bounds.width - 2 * 16 - 2 * 12
        meterHeightConstraint = meterView.heightAnchor.constraint(
            equalToConstant: meterView.neededHeight(for: estimatedMeterW))
        meterHeightConstraint.isActive = true

        // Picker rows
        heightRow.configure(title: "Height", unit: "CM")
        weightRow.configure(title: "Weight", unit: "KG")
        heightRow.onTap = { [weak self] in self?.showHeightPicker() }
        weightRow.onTap = { [weak self] in self?.showWeightPicker() }

        // Update button
        updateBtn.setTitle("Update", for: .normal)
        updateBtn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        updateBtn.backgroundColor = UIColor(red: 13/255, green: 153/255, blue: 255/255, alpha: 1)
        updateBtn.setTitleColor(.white, for: .normal)
        updateBtn.layer.cornerRadius = 14
        updateBtn.translatesAutoresizingMaskIntoConstraints = false
        updateBtn.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)

        // Add card subviews
        card.addSubview(cardTitle)
        card.addSubview(meterView)
        cardTitle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardTitle.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            meterView.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 8),
            meterView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            meterView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            meterView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        // Add all views to contentView
        [card, heightRow, weightRow, updateBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        let pad: CGFloat = 16
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: pad),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            heightRow.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 16),
            heightRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            heightRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            heightRow.heightAnchor.constraint(equalToConstant: 56),

            weightRow.topAnchor.constraint(equalTo: heightRow.bottomAnchor, constant: 12),
            weightRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            weightRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            weightRow.heightAnchor.constraint(equalToConstant: 56),

            updateBtn.topAnchor.constraint(equalTo: weightRow.bottomAnchor, constant: 24),
            updateBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            updateBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            updateBtn.heightAnchor.constraint(equalToConstant: 52),
            updateBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    // MARK: - Card helper

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 6
        return v
    }

    private func makeLabel(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textColor = color
        return l
    }

    // MARK: - Data

    private func loadSavedValues() {
        // Prefer profile-fetched data (saved via UserDefaultsManager when Profile screen loads)
        let h = UserDefaultsManager.shared.profileHeight
        let w = UserDefaultsManager.shared.profileWeight

        selectedHeight = h > 0 ? Int(h) : 170
        selectedWeight = w > 0 ? Int(w) : 65

        updateDisplay()
    }

    private func updateDisplay() {
        heightRow.setValue("\(selectedHeight)")
        weightRow.setValue("\(selectedWeight)")

        let bmi = computeBMI()
        meterView.bmi       = CGFloat(bmi)
        meterView.heightCm  = selectedHeight
        meterView.weightKg  = selectedWeight
    }

    private func computeBMI() -> Double {
        guard selectedHeight > 0, selectedWeight > 0 else { return 0 }
        let hM = Double(selectedHeight) / 100.0
        return Double(selectedWeight) / (hM * hM)
    }

    // MARK: - Pickers

    private func showHeightPicker() {
        let options = (100...250).map { "\($0) cm" }
        let preselected = selectedHeight >= 100 && selectedHeight <= 250
            ? ["\(selectedHeight) cm"] : ["\(170) cm"]

        let popup = MultiSelectPopupViewController(
            title: "Select Height (CM)",
            options: options,
            preselected: preselected,
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            guard let self, let first = selected.first,
                  let value = Int(first.components(separatedBy: " ").first ?? "") else { return }
            self.selectedHeight = value
            self.updateDisplay()
        }
        present(popup, animated: true)
    }

    private func showWeightPicker() {
        let options = (20...200).map { "\($0) kg" }
        let preselected = selectedWeight >= 20 && selectedWeight <= 200
            ? ["\(selectedWeight) kg"] : ["\(65) kg"]

        let popup = MultiSelectPopupViewController(
            title: "Select Weight (KG)",
            options: options,
            preselected: preselected,
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            guard let self, let first = selected.first,
                  let value = Int(first.components(separatedBy: " ").first ?? "") else { return }
            self.selectedWeight = value
            self.updateDisplay()
        }
        present(popup, animated: true)
    }

    // MARK: - Update action

    @objc private func updateTapped() {
        // 1. Save to local (UserDefaultsManager keeps both user_height/user_weight keys in sync)
        UserDefaultsManager.shared.profileHeight = Double(selectedHeight)
        UserDefaultsManager.shared.profileWeight = Double(selectedWeight)

        // 2. Refresh UI immediately
        updateDisplay()
        NotificationCenter.default.post(name: .bmiDataUpdated, object: nil)

        // 3. Sync to server using the same pattern as ProfileViewController
        let loggedInUserId = UserDefaultsManager.shared.userId
        guard loggedInUserId > 0 else {
            Toast.show(message: "BMI updated locally", in: view)
            return
        }

        let profileUserId = UserDefaultsManager.shared.profileUserId

        var params: [String: String] = [:]
        params["user_id"] = String(profileUserId > 0 ? profileUserId : loggedInUserId)
        params["id"]      = String(loggedInUserId)
        params["height"]  = String(selectedHeight)
        params["weight"]  = String(selectedWeight)
        params["status"]  = "1"
        params["allergy"] = "0"

        Loader.shared.show(on: view, message: "Updating...", timeout: 5)

        ProfileService.shared.saveUserProfile(
            userId: loggedInUserId,
            params: params,
            profileImage: nil
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                Loader.shared.hide()
                switch result {
                case .success(let response):
                    Toast.show(message: response.message, in: self.view)
                case .failure:
                    Toast.show(message: "BMI saved locally", in: self.view)
                }
            }
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let bmiDataUpdated = Notification.Name("com.app.bmiDataUpdated")
}

// MARK: - BMIPickerRowView

/// A tappable row showing a label + value + chevron inside a white rounded card.
final class BMIPickerRowView: UIView {

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevron    = UIImageView(image: UIImage(systemName: "chevron.right"))

    private var unitSuffix: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor    = .white
        layer.cornerRadius = 12
        layer.shadowColor  = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        titleLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .black

        valueLabel.font      = .systemFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        valueLabel.textAlignment = .right

        chevron.tintColor    = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        chevron.contentMode  = .scaleAspectFit

        [titleLabel, valueLabel, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 9),
            chevron.heightAnchor.constraint(equalToConstant: 15),

            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    func configure(title: String, unit: String) {
        titleLabel.text = title
        unitSuffix = " \(unit)"
    }

    func setValue(_ value: String) {
        valueLabel.text = value + unitSuffix
    }

    @objc private func didTap() { onTap?() }
}

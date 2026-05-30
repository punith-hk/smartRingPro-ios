import UIKit

final class AddAssociationViewController: AppBaseViewController {

    var onSuccess: (() -> Void)?

    // MARK: - State
    private var receiverId: Int?
    private var countdownTimer: Timer?
    private var secondsRemaining: Int = 60
    private let userId: Int = UserDefaults.standard.integer(forKey: "id")
    private var otpFieldsVisible = false

    // MARK: - UI  (all in a vertical stack so hidden views collapse)
    private let scrollView   = UIScrollView()
    private let contentView  = UIView()
    private let mainStack    = UIStackView()

    private let howToCard     = UIView()
    private let phoneField    = UITextField()
    private let resendLabel   = UILabel()
    private let otpField      = UITextField()
    private let relationField = UITextField()
    private let sendCodeBtn   = UIButton(type: .system)
    private let confirmBtn    = UIButton(type: .system)

    // Wrappers that need to be hidden/shown (hiding wrapper collapses stack spacing)
    private var otpFieldWrapper: UIView!
    private var relationFieldWrapper: UIView!
    private var sendCodeWrapper: UIView!
    private var confirmWrapper: UIView!

    // MARK: - Data
    private let relationOptions = [
        "Father", "Mother", "Sister", "Brother",
        "Grandma", "Grandpa", "Uncle", "Aunt", "Friends"
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Association"
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.99, alpha: 1)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
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

        // Main vertical stack
        mainStack.axis = .vertical
        mainStack.spacing = 14
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        // Build each element and add to stack
        otpFieldWrapper      = makeField(otpField, placeholder: "Enter verification code", keyboardType: .numberPad)
        relationFieldWrapper = makeRelationField()
        sendCodeWrapper      = makeSendCodeButton()
        confirmWrapper       = makeConfirmButton()

        mainStack.addArrangedSubview(buildHowToCard())
        mainStack.addArrangedSubview(makeField(phoneField, placeholder: "Enter the mobile number", keyboardType: .numberPad))
        mainStack.addArrangedSubview(resendLabel)
        mainStack.addArrangedSubview(otpFieldWrapper)
        mainStack.addArrangedSubview(relationFieldWrapper)
        mainStack.addArrangedSubview(sendCodeWrapper)
        mainStack.addArrangedSubview(confirmWrapper)

        // Initial state: hide step-2 wrappers (wrapper hidden = stack collapses spacing)
        resendLabel.isHidden         = true
        otpFieldWrapper.isHidden     = true
        relationFieldWrapper.isHidden = true
        confirmWrapper.isHidden      = true
    }

    // MARK: - How-To Card
    private func buildHowToCard() -> UIView {
        howToCard.backgroundColor = .white
        howToCard.layer.cornerRadius = 16
        howToCard.layer.shadowColor = UIColor.black.cgColor
        howToCard.layer.shadowOpacity = 0.06
        howToCard.layer.shadowRadius = 8
        howToCard.layer.shadowOffset = CGSize(width: 0, height: 2)

        let titleLbl = UILabel()
        titleLbl.text = "Add Your Loved Ones"
        titleLbl.font = .systemFont(ofSize: 17, weight: .bold)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        howToCard.addSubview(titleLbl)

        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 14
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        let stepTexts = [
            "Enter their registered mobile number below and send verification code",
            "Ask them for the OTP, enter it and select relationship to complete linking"
        ]
        for (i, text) in stepTexts.enumerated() {
            stepsStack.addArrangedSubview(makeStepRow(number: i + 1, text: text))
        }
        howToCard.addSubview(stepsStack)

        // Orange note box
        let noteBox = UIView()
        noteBox.backgroundColor = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
        noteBox.layer.cornerRadius = 8
        noteBox.translatesAutoresizingMaskIntoConstraints = false

        let noteIcon = UILabel()
        noteIcon.text = "ⓘ"
        noteIcon.textColor = UIColor(red: 0.93, green: 0.60, blue: 0.07, alpha: 1)
        noteIcon.font = .systemFont(ofSize: 14, weight: .bold)
        noteIcon.setContentHuggingPriority(.required, for: .horizontal)
        noteIcon.translatesAutoresizingMaskIntoConstraints = false

        let noteTxt = UILabel()
        noteTxt.text = "Note: Once linked, you can monitor their health vitals and receive alerts for any abnormalities."
        noteTxt.font = .systemFont(ofSize: 12)
        noteTxt.textColor = UIColor(red: 0.70, green: 0.35, blue: 0.00, alpha: 1)
        noteTxt.numberOfLines = 0
        noteTxt.translatesAutoresizingMaskIntoConstraints = false

        noteBox.addSubview(noteIcon)
        noteBox.addSubview(noteTxt)
        howToCard.addSubview(noteBox)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: howToCard.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: howToCard.leadingAnchor, constant: 16),
            titleLbl.trailingAnchor.constraint(equalTo: howToCard.trailingAnchor, constant: -16),

            stepsStack.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 16),
            stepsStack.leadingAnchor.constraint(equalTo: howToCard.leadingAnchor, constant: 16),
            stepsStack.trailingAnchor.constraint(equalTo: howToCard.trailingAnchor, constant: -16),

            noteBox.topAnchor.constraint(equalTo: stepsStack.bottomAnchor, constant: 14),
            noteBox.leadingAnchor.constraint(equalTo: howToCard.leadingAnchor, constant: 16),
            noteBox.trailingAnchor.constraint(equalTo: howToCard.trailingAnchor, constant: -16),
            noteBox.bottomAnchor.constraint(equalTo: howToCard.bottomAnchor, constant: -16),

            noteIcon.topAnchor.constraint(equalTo: noteBox.topAnchor, constant: 10),
            noteIcon.leadingAnchor.constraint(equalTo: noteBox.leadingAnchor, constant: 12),

            noteTxt.topAnchor.constraint(equalTo: noteBox.topAnchor, constant: 10),
            noteTxt.leadingAnchor.constraint(equalTo: noteIcon.trailingAnchor, constant: 8),
            noteTxt.trailingAnchor.constraint(equalTo: noteBox.trailingAnchor, constant: -12),
            noteTxt.bottomAnchor.constraint(equalTo: noteBox.bottomAnchor, constant: -10)
        ])

        return howToCard
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

    // MARK: - Field helpers
    private func makeField(_ field: UITextField, placeholder: String, keyboardType: UIKeyboardType) -> UIView {
        field.placeholder = placeholder
        field.backgroundColor = .white
        field.layer.cornerRadius = 10
        field.keyboardType = keyboardType
        field.setHorizontalPadding(left: 14)

        let wrapper = UIView()
        field.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(field)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: wrapper.topAnchor),
            field.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            field.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            field.heightAnchor.constraint(equalToConstant: 48)
        ])
        return wrapper
    }

    private func makeRelationField() -> UIView {
        relationField.placeholder = "Select Relationship"
        relationField.backgroundColor = .white
        relationField.layer.cornerRadius = 10
        relationField.setHorizontalPadding(left: 14, right: 44)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = UIColor(white: 0.4, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 12, y: 14, width: 16, height: 16)
        let chevronContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        chevronContainer.addSubview(chevron)
        relationField.rightView = chevronContainer
        relationField.rightViewMode = .always

        let tap = UITapGestureRecognizer(target: self, action: #selector(openRelationSelector))
        relationField.addGestureRecognizer(tap)

        let wrapper = UIView()
        relationField.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(relationField)
        NSLayoutConstraint.activate([
            relationField.topAnchor.constraint(equalTo: wrapper.topAnchor),
            relationField.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            relationField.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            relationField.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            relationField.heightAnchor.constraint(equalToConstant: 48)
        ])
        return wrapper
    }

    private func makeSendCodeButton() -> UIView {
        sendCodeBtn.setTitle("Send Verification Code", for: .normal)
        sendCodeBtn.setTitleColor(.white, for: .normal)
        sendCodeBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        sendCodeBtn.backgroundColor = UIColor(red: 0.00, green: 0.58, blue: 0.97, alpha: 1)
        sendCodeBtn.layer.cornerRadius = 20
        sendCodeBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        sendCodeBtn.addTarget(self, action: #selector(sendOtpTapped), for: .touchUpInside)

        let wrapper = UIView()
        sendCodeBtn.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(sendCodeBtn)
        NSLayoutConstraint.activate([
            sendCodeBtn.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 6),
            sendCodeBtn.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -6),
            sendCodeBtn.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            sendCodeBtn.heightAnchor.constraint(equalToConstant: 40)
        ])
        return wrapper
    }

    private func makeConfirmButton() -> UIView {
        confirmBtn.setTitle("Confirm Association", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        confirmBtn.backgroundColor = UIColor(red: 0.00, green: 0.58, blue: 0.97, alpha: 1)
        confirmBtn.layer.cornerRadius = 22
        confirmBtn.addTarget(self, action: #selector(verifyOtpTapped), for: .touchUpInside)

        let wrapper = UIView()
        confirmBtn.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(confirmBtn)
        NSLayoutConstraint.activate([
            confirmBtn.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
            confirmBtn.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -8),
            confirmBtn.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            confirmBtn.widthAnchor.constraint(equalToConstant: 220),
            confirmBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        return wrapper
    }

    // MARK: - Resend Label setup (called once in setupUI via the label being added to stack)
    private func configureResendLabel() {
        resendLabel.font = .systemFont(ofSize: 13)
        resendLabel.textColor = UIColor(white: 0.3, alpha: 1)
        resendLabel.isUserInteractionEnabled = true
    }

    // MARK: - Reveal OTP fields after success
    private func revealOtpFields() {
        otpFieldsVisible = true

        // Disable phone field
        phoneField.isEnabled  = false
        phoneField.textColor  = UIColor(white: 0.5, alpha: 1)

        // Hide send button wrapper, show step-2 wrappers with animation
        UIView.animate(withDuration: 0.25) {
            self.sendCodeWrapper.isHidden        = true
            self.resendLabel.isHidden            = false
            self.otpFieldWrapper.isHidden        = false
            self.relationFieldWrapper.isHidden   = false
            self.confirmWrapper.isHidden         = false
            self.mainStack.layoutIfNeeded()
        }

        startCountdown()
    }

    // MARK: - Countdown
    private func startCountdown() {
        secondsRemaining = 60
        countdownTimer?.invalidate()
        updateResendLabel()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsRemaining -= 1
            self.updateResendLabel()
            if self.secondsRemaining <= 0 { self.countdownTimer?.invalidate() }
        }
    }

    private func updateResendLabel() {
        if secondsRemaining > 0 {
            resendLabel.attributedText = nil
            resendLabel.text = "Resend OTP in \(secondsRemaining) seconds"
            resendLabel.textColor = UIColor(white: 0.3, alpha: 1)
            resendLabel.gestureRecognizers?.forEach { resendLabel.removeGestureRecognizer($0) }
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.systemBlue,
                .font: UIFont.boldSystemFont(ofSize: 13)
            ]
            resendLabel.attributedText = NSAttributedString(string: "Resend OTP", attributes: attrs)
            resendLabel.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(resendOtpTapped))
            )
        }
    }

    @objc private func resendOtpTapped() {
        guard let phone = phoneField.text, phone.count >= 10 else { return }
        requestOtp(phone: phone)
    }

    // MARK: - Actions
    @objc private func sendOtpTapped() {
        view.endEditing(true)
        let phone = phoneField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard phone.count == 10 else {
            Toast.show(message: "Enter valid 10-digit mobile number", in: view)
            return
        }
        requestOtp(phone: phone)
    }

    private func requestOtp(phone: String) {
        Loader.shared.show(on: view)
        LinkedAccountService.shared.addLinkedAccount(userId: userId, phoneNumber: phone) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                Loader.shared.hide()
                switch result {
                case .success(let response):
                    Toast.show(message: response.message, in: self.view)
                    self.view.endEditing(true)
                    if response.message.lowercased().contains("already") { return }
                    guard let receiverId = response.receiver_id else { return }
                    self.receiverId = receiverId
                    self.revealOtpFields()
                case .failure:
                    Toast.show(message: "Failed to send OTP", in: self.view)
                }
            }
        }
    }

    @objc private func verifyOtpTapped() {
        guard
            let otpText  = otpField.text, let otp = Int(otpText),
            let relation = relationField.text, !relation.isEmpty,
            let receiverId = receiverId
        else {
            Toast.show(message: "Fill all fields", in: view)
            return
        }

        Loader.shared.show(on: view)
        LinkedAccountService.shared.verifyCaretakerOtp(
            userId: userId, receiverId: receiverId, otp: otp, relation: relation
        ) { [weak self] result in
            DispatchQueue.main.async {
                Loader.shared.hide()
                switch result {
                case .success(let response):
                    Toast.show(message: response.message, in: self?.view ?? UIView())
                    self?.onSuccess?()
                    self?.navigationController?.popViewController(animated: true)
                case .failure:
                    Toast.show(message: "OTP verification failed", in: self?.view ?? UIView())
                }
            }
        }
    }

    // MARK: - Relation Selector
    @objc private func openRelationSelector() {
        let sheet = UIAlertController(title: "Select Relationship", message: nil, preferredStyle: .actionSheet)
        for option in relationOptions {
            sheet.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.relationField.text = option
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

extension UITextField {

    func setHorizontalPadding(left: CGFloat = 0, right: CGFloat = 0) {
        if left > 0 {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: left, height: 1))
            self.leftView  = v
            self.leftViewMode = .always
        }
        if right > 0 {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: right, height: 1))
            self.rightView  = v
            self.rightViewMode = .always
        }
    }
}

import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {

    private let cardView = UIView()
    private let nameField = UITextField()
    private let mobileField = UITextField()
    private let sendOtpButton = UIButton(type: .system)
    private let loginLabel = UILabel()

    // MARK: - Referral
    private var referralCode: String?
    private let referralLinkLabel = UILabel()
    private let referralTagView = UIView()
    private let referralCodeLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
        setupTextFields()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1)
        navigationItem.title = ""

        // Card
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 10
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Register"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Create your account to get started with HEARTO"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .black
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        // Name Field
        nameField.placeholder = "Full Name"
        nameField.borderStyle = .roundedRect
        nameField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameField)

        // Mobile Field
        mobileField.placeholder = "Mobile Number"
        mobileField.keyboardType = .numberPad
        mobileField.borderStyle = .roundedRect
        mobileField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mobileField)

        // "or" divider
        let dividerStack = makeDivider()
        cardView.addSubview(dividerStack)

        // Already have an account label
        loginLabel.attributedText = makeLoginText()
        loginLabel.textAlignment = .center
        loginLabel.isUserInteractionEnabled = true
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(loginLabel)

        let loginTap = UITapGestureRecognizer(target: self, action: #selector(loginTapped))
        loginLabel.addGestureRecognizer(loginTap)

        // Register Button
        sendOtpButton.setTitle("Register", for: .normal)
        sendOtpButton.setTitleColor(.white, for: .normal)
        sendOtpButton.backgroundColor = .systemGreen
        sendOtpButton.layer.cornerRadius = 10
        sendOtpButton.translatesAutoresizingMaskIntoConstraints = false
        sendOtpButton.addTarget(self, action: #selector(sendOtpTapped), for: .touchUpInside)
        cardView.addSubview(sendOtpButton)

        // Referral link label
        referralLinkLabel.attributedText = NSAttributedString(
            string: "Have a referral code?",
            attributes: [
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )
        referralLinkLabel.isUserInteractionEnabled = true
        referralLinkLabel.translatesAutoresizingMaskIntoConstraints = false
        referralLinkLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(showReferralDialog))
        )
        cardView.addSubview(referralLinkLabel)

        // Referral code chip (shown after code applied)
        referralTagView.backgroundColor = UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1)
        referralTagView.layer.cornerRadius = 14
        referralTagView.isHidden = true
        referralTagView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(referralTagView)

        referralCodeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        referralCodeLabel.textColor = .systemBlue
        referralCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        referralTagView.addSubview(referralCodeLabel)

        let removeBtn = UIButton(type: .system)
        removeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        removeBtn.tintColor = .systemBlue
        removeBtn.translatesAutoresizingMaskIntoConstraints = false
        removeBtn.addTarget(self, action: #selector(removeReferralCode), for: .touchUpInside)
        referralTagView.addSubview(removeBtn)

        NSLayoutConstraint.activate([
            referralCodeLabel.leadingAnchor.constraint(equalTo: referralTagView.leadingAnchor, constant: 12),
            referralCodeLabel.centerYAnchor.constraint(equalTo: referralTagView.centerYAnchor),
            removeBtn.leadingAnchor.constraint(equalTo: referralCodeLabel.trailingAnchor, constant: 8),
            removeBtn.trailingAnchor.constraint(equalTo: referralTagView.trailingAnchor, constant: -10),
            removeBtn.centerYAnchor.constraint(equalTo: referralTagView.centerYAnchor),
            removeBtn.widthAnchor.constraint(equalToConstant: 20),
            removeBtn.heightAnchor.constraint(equalToConstant: 20)
        ])

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),

            nameField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            nameField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),
            nameField.heightAnchor.constraint(equalToConstant: 48),

            mobileField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            mobileField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            mobileField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            mobileField.heightAnchor.constraint(equalToConstant: 48),

            sendOtpButton.topAnchor.constraint(equalTo: mobileField.bottomAnchor, constant: 24),
            sendOtpButton.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            sendOtpButton.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            sendOtpButton.heightAnchor.constraint(equalToConstant: 48),

            referralLinkLabel.topAnchor.constraint(equalTo: sendOtpButton.bottomAnchor, constant: 14),
            referralLinkLabel.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            referralLinkLabel.heightAnchor.constraint(equalToConstant: 28),

            referralTagView.topAnchor.constraint(equalTo: sendOtpButton.bottomAnchor, constant: 14),
            referralTagView.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            referralTagView.heightAnchor.constraint(equalToConstant: 28),

            dividerStack.topAnchor.constraint(equalTo: referralLinkLabel.bottomAnchor, constant: 14),
            dividerStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            dividerStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),

            loginLabel.topAnchor.constraint(equalTo: dividerStack.bottomAnchor, constant: 16),
            loginLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            loginLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -40)
        ])
    }

    private func setupTextFields() {
        mobileField.delegate = self
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        let allowed = CharacterSet.decimalDigits
        let charSet = CharacterSet(charactersIn: string)
        if !allowed.isSuperset(of: charSet) { return false }

        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 10
    }

    @objc private func sendOtpTapped() {
        let name = nameField.text ?? ""
        let mobile = mobileField.text ?? ""

        guard !name.isEmpty else {
            showAlert("Please enter name")
            return
        }

        guard mobile.count == 10 else {
            showAlert("Mobile number must be 10 digits")
            return
        }

        Loader.shared.show(on: view, message: "Sending OTP...", timeout: 10)

        AuthService.shared.register(mobile: mobile, name: name) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                Loader.shared.hide()

                switch result {
                case .success(let response):

                    if response.response == 0 {
                        // ✅ SAME AS ANDROID
                        Toast.show(message: response.formattedMessage(), in: self.view)

                        let otpVC = OtpVerifyViewController(
                            userId: response.user_id ?? 0,
                            mobileNumber: mobile
                        )

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.navigationController?.pushViewController(otpVC, animated: true)
                        }

                    } else {
                        Toast.show(message: response.formattedMessage(), in: self.view)
                    }

                case .failure:
                    self.showAlert("Registration failed. Please try again.")
                }
            }
        }
    }


    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    private func makeLoginText() -> NSAttributedString {
        let normalText = "Already have an account? "
        let signInText = "Sign In"

        let fullText = NSMutableAttributedString(
            string: normalText,
            attributes: [
                .foregroundColor: UIColor.gray,
                .font: UIFont.systemFont(ofSize: 18)
            ]
        )
        fullText.append(NSAttributedString(
            string: signInText,
            attributes: [
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.boldSystemFont(ofSize: 18)
            ]
        ))
        return fullText
    }

    // MARK: - Or Divider
    private func makeDivider() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let leftLine = UIView()
        leftLine.backgroundColor = UIColor(white: 0.75, alpha: 1)
        leftLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        leftLine.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let orLabel = UILabel()
        orLabel.text = "or"
        orLabel.font = .boldSystemFont(ofSize: 18)
        orLabel.textColor = .black
        orLabel.setContentHuggingPriority(.required, for: .horizontal)

        let rightLine = UIView()
        rightLine.backgroundColor = UIColor(white: 0.75, alpha: 1)
        rightLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        rightLine.setContentHuggingPriority(.defaultLow, for: .horizontal)

        container.addArrangedSubview(leftLine)
        container.addArrangedSubview(orLabel)
        container.addArrangedSubview(rightLine)

        NSLayoutConstraint.activate([
            leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor)
        ])

        return container
    }

    @objc private func loginTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Referral Code
    @objc private func showReferralDialog() {
        let alert = UIAlertController(
            title: "Have a referral code?",
            message: "Have a referral code from a friend? Enter it below to get 20% off on your first treatment.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "Enter referral code"
            tf.autocapitalizationType = .allCharacters
            tf.returnKeyType = .done
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { [weak self, weak alert] _ in
            guard
                let self = self,
                let code = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                !code.isEmpty
            else { return }
            self.referralCode = code
            self.referralCodeLabel.text = code
            self.referralLinkLabel.isHidden = true
            self.referralTagView.isHidden = false
        })
        present(alert, animated: true)
    }

    @objc private func removeReferralCode() {
        referralCode = nil
        referralTagView.isHidden = true
        referralLinkLabel.isHidden = false
    }
}

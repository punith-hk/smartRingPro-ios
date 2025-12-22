import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {

    private let cardView = UIView()
    private let nameField = UITextField()
    private let mobileField = UITextField()
    private let sendOtpButton = UIButton(type: .system)
    private let loginLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
        setupTextFields()
    }

    private func setupUI() {
        view.backgroundColor = .systemBlue
        navigationItem.title = ""

        // Card
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 360)
        ])

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Patient registration"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Name Field
        nameField.placeholder = "Name"
        nameField.borderStyle = .roundedRect
        nameField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameField)

        // Mobile Field
        mobileField.placeholder = "Mobile number"
        mobileField.keyboardType = .numberPad
        mobileField.borderStyle = .roundedRect
        mobileField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mobileField)

        // Already have an account label
        loginLabel.attributedText = makeLoginText()
        loginLabel.textAlignment = .center
        loginLabel.isUserInteractionEnabled = true
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(loginLabel)

        let loginTap = UITapGestureRecognizer(target: self, action: #selector(loginTapped))
        loginLabel.addGestureRecognizer(loginTap)

        // Send OTP Button
        sendOtpButton.setTitle("Send OTP", for: .normal)
        sendOtpButton.setTitleColor(.white, for: .normal)
        sendOtpButton.backgroundColor = .systemGreen
        sendOtpButton.layer.cornerRadius = 10
        sendOtpButton.translatesAutoresizingMaskIntoConstraints = false
        sendOtpButton.addTarget(self, action: #selector(sendOtpTapped), for: .touchUpInside)
        cardView.addSubview(sendOtpButton)

        // ✅ FIXED CONSTRAINTS
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            mobileField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            mobileField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            mobileField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            mobileField.heightAnchor.constraint(equalToConstant: 44),

            // Label BELOW mobile
            loginLabel.topAnchor.constraint(equalTo: mobileField.bottomAnchor, constant: 12),
            loginLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            // Button BELOW label (more spacing)
            sendOtpButton.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 24),
            sendOtpButton.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            sendOtpButton.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            sendOtpButton.heightAnchor.constraint(equalToConstant: 48)
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

        Loader.shared.show(on: view)

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
        NSAttributedString(
            string: "Already have an account?",
            attributes: [
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
    }

    @objc private func loginTapped() {
        navigationController?.popViewController(animated: true)
    }
}

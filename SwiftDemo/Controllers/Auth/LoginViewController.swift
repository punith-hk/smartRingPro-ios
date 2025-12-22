import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    private let cardView = UIView()
    private let mobileField = UITextField()
    private let signInButton = UIButton(type: .system)
    private let signUpLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
        setupTextField()
    }

    // MARK: - UI
    private func setupUI() {

        view.backgroundColor = .systemBlue
        navigationItem.title = ""
        navigationController?.setNavigationBarHidden(true, animated: false)


        // Card
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 300)
        ])

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Login"
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "We'll send a confirmation code to your phone"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .gray
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        // Mobile Field
        mobileField.placeholder = "Mobile Number"
        mobileField.keyboardType = .numberPad
        mobileField.borderStyle = .none
        mobileField.font = .systemFont(ofSize: 16)
        mobileField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mobileField)

        let underline = UIView()
        underline.backgroundColor = .lightGray
        underline.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(underline)

        // Sign In Button
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.backgroundColor = .systemGreen
        signInButton.layer.cornerRadius = 10
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        cardView.addSubview(signInButton)

        // Sign Up Label (Attributed)
        signUpLabel.attributedText = makeSignUpText()
        signUpLabel.textAlignment = .center
        signUpLabel.isUserInteractionEnabled = true
        signUpLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(signUpLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(signUpTapped))
        signUpLabel.addGestureRecognizer(tap)

        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            mobileField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            mobileField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            mobileField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            mobileField.heightAnchor.constraint(equalToConstant: 40),

            underline.topAnchor.constraint(equalTo: mobileField.bottomAnchor, constant: 2),
            underline.leadingAnchor.constraint(equalTo: mobileField.leadingAnchor),
            underline.trailingAnchor.constraint(equalTo: mobileField.trailingAnchor),
            underline.heightAnchor.constraint(equalToConstant: 1),

            signInButton.topAnchor.constraint(equalTo: underline.bottomAnchor, constant: 24),
            signInButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            signInButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            signInButton.heightAnchor.constraint(equalToConstant: 48),

            signUpLabel.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 16),
            signUpLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            signUpLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Sign Up Text
    private func makeSignUpText() -> NSAttributedString {
        let normalText = "Don't have an account? "
        let signUpText = "Sign Up"

        let fullText = NSMutableAttributedString(
            string: normalText,
            attributes: [.foregroundColor: UIColor.darkGray]
        )

        let signUpAttr = NSAttributedString(
            string: signUpText,
            attributes: [
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )

        fullText.append(signUpAttr)
        return fullText
    }

    // MARK: - TextField
    private func setupTextField() {
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

    // MARK: - Actions
    @objc private func signInTapped() {
        hideKeyboard()

        let mobile = mobileField.text ?? ""
        guard mobile.count == 10 else {
            showAlert("Please enter a valid 10-digit mobile number")
            return
        }

        // 🔥 SHOW LOADER
        Loader.shared.show(on: view)

        AuthService.shared.login(mobile: mobile) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                // 🔥 HIDE LOADER
                Loader.shared.hide()

                switch result {
                case .success(let response):
                    if response.response == 0 {
                        Toast.show(message: "OTP has been sent", in: self.view)

                           let otpVC = OtpVerifyViewController(
                               userId: response.user_id ?? 0,
                               mobileNumber: mobile
                           )

                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                               self.navigationController?.pushViewController(otpVC, animated: true)
                           }
                    } else {
                        self.showAlert(response.formattedMessage())
                    }

                case .failure:
                    self.showAlert("Something went wrong. Please try again.")
                }
            }
        }
    }


    @objc private func signUpTapped() {
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }

    // MARK: - Keyboard
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Alert
    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

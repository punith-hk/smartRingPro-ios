import UIKit
import YCProductSDK

class OtpVerifyViewController: UIViewController, UITextFieldDelegate {

    private let userId: Int
    private let mobileNumber: String

    private let cardView = UIView()
    private let otpField = UITextField()
    private let submitButton = UIButton(type: .system)
    private let resendLabel = UILabel()

    private var timer: Timer?
    private var remainingSeconds = 90

    // MARK: - Init
    init(userId: Int, mobileNumber: String) {
        self.userId = userId
        self.mobileNumber = mobileNumber
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupKeyboardDismiss()
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)

        let navColor = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navColor
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

        navigationItem.title = "Verify Your Number"
        navigationItem.backButtonTitle = ""
    }


    // MARK: - UI
    private func setupUI() {

        view.backgroundColor = UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1)
        navigationItem.title = "Let’s verify your number"

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

        // Title inside card
        let titleLabel = UILabel()
        titleLabel.text = "Verify Your Number"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Info Label
        let infoLabel = UILabel()
        infoLabel.text = "OTP sent to your mobile number \(mobileNumber)"
        infoLabel.numberOfLines = 2
        infoLabel.font = .systemFont(ofSize: 16)
        infoLabel.textColor = .black
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(infoLabel)

        // OTP Field
        otpField.delegate = self
        otpField.placeholder = "● ● ● ● ● ●"
        otpField.keyboardType = .numberPad
        otpField.borderStyle = .roundedRect
        otpField.textAlignment = .center
        otpField.font = .systemFont(ofSize: 22, weight: .semibold)
        otpField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(otpField)

        // Resend Label
        resendLabel.font = .systemFont(ofSize: 13)
        resendLabel.textColor = .gray
        resendLabel.isUserInteractionEnabled = true
        resendLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(resendLabel)

        let resendTap = UITapGestureRecognizer(target: self, action: #selector(resendTapped))
        resendLabel.addGestureRecognizer(resendTap)

        // Verify OTP Button
        submitButton.setTitle("Verify OTP", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .systemGreen
        submitButton.layer.cornerRadius = 10
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        cardView.addSubview(submitButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),

            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 32),
            infoLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -32),

            otpField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 24),
            otpField.leadingAnchor.constraint(equalTo: infoLabel.leadingAnchor),
            otpField.trailingAnchor.constraint(equalTo: infoLabel.trailingAnchor),
            otpField.heightAnchor.constraint(equalToConstant: 52),

            resendLabel.topAnchor.constraint(equalTo: otpField.bottomAnchor, constant: 12),
            resendLabel.leadingAnchor.constraint(equalTo: otpField.leadingAnchor),

            submitButton.topAnchor.constraint(equalTo: resendLabel.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: otpField.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: otpField.trailingAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            submitButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -40)
        ])
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        let allowed = CharacterSet.decimalDigits
        let charSet = CharacterSet(charactersIn: string)
        if !allowed.isSuperset(of: charSet) { return false }

        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 6
    }

    // MARK: - Timer Logic
    private func startTimer() {
        remainingSeconds = 60
        updateResendLabel()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            self.updateResendLabel()
        }
    }

    private func updateResendLabel() {
        if remainingSeconds > 0 {
            let seconds = remainingSeconds % 60
            resendLabel.textColor = .gray
            resendLabel.attributedText = nil
            resendLabel.text = String(format: "Resend code in 00:%02d", seconds)
        } else {
            timer?.invalidate()
            showResendLink()
        }
    }

    private func showResendLink() {
        let text = NSMutableAttributedString(
            string: "Resend OTP",
            attributes: [
                .foregroundColor: UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.boldSystemFont(ofSize: 13)
            ]
        )
        resendLabel.attributedText = text
    }

    // MARK: - Actions
    @objc private func resendTapped() {
        if remainingSeconds > 0 { return }

        Loader.shared.show(on: view, message: "Resending OTP...", timeout: 10)

        AuthService.shared.login(mobile: mobileNumber) { [weak self] result in
            DispatchQueue.main.async {
                Loader.shared.hide()

                switch result {
                case .success(let response):
                    if response.response == 0 {
                        self?.startTimer()
                    } else {
                        self?.showAlert(response.formattedMessage())
                    }
                case .failure:
                    self?.showAlert("Failed to resend OTP")
                }
            }
        }
    }
    
    @objc private func submitTapped() {
        hideKeyboard()

        let otp = otpField.text ?? ""
        guard otp.count == 6 else {
            showAlert("OTP must be 6 digits")
            return
        }

        Loader.shared.show(on: view, message: "Verifying OTP...", timeout: 10)

        AuthService.shared.verifyOtp(userId: userId, otp: otp) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                Loader.shared.hide()

                switch result {
                case .success(let response):

                    if response.response == 0 {

                        // ✅ Save session
                        UserDefaultsManager.shared.saveOtpResponse(response)

                        // ✅ Background-fetch profile so side menu shows name + photo immediately
                        let userId = UserDefaultsManager.shared.userId
                        if userId > 0 {
                            ProfileService.shared.getUserProfile(userId: userId) { result in
                                if case .success(let profileResponse) = result {
                                    let data = profileResponse.data
                                    let fullName = "\(data.first_name ?? "") \(data.last_name ?? "")".trimmingCharacters(in: .whitespaces)
                                    DispatchQueue.main.async {
                                        UserDefaultsManager.shared.saveProfileData(
                                            name: fullName,
                                            photoUrl: data.patient_image_url ?? ""
                                        )
                                        NotificationCenter.default.post(
                                            name: .profileDataLoaded,
                                            object: nil,
                                            userInfo: [
                                                "name": fullName,
                                                "phone": data.phone_number,
                                                "imageUrl": data.patient_image_url ?? ""
                                            ]
                                        )
                                    }
                                }
                            }
                        }
                        
                        // ✅ Send FCM token to server
                        FCMService.forceSendTokenToServer { success, message in
                            if success {
                                print("✅ FCM token sent to server after login")
                            } else {
                                print("⚠️ Failed to send FCM token: \(message ?? "unknown")")
                            }
                        }

                        // ✅ Small toast
                        Toast.show(message: "OTP verified successfully", in: self.view)

                        // 🔥 SWITCH ROOT CONTROLLER CORRECTLY
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            
                            // 🔥 BLE INIT
                                    YCProduct.setLogLevel(.normal, saveLevel: .error)
                                    _ = YCProduct.shared
                            
                            // 🚨 REQUEST LOCATION PERMISSION (for emergency health monitoring)
                            LocationManager.shared.requestLocationPermission()

                            let rootVC = SideMenuContainerController()

                            if let sceneDelegate = UIApplication.shared.connectedScenes
                                .first(where: { $0.activationState == .foregroundActive })?
                                .delegate as? SceneDelegate {

                                sceneDelegate.setRootViewController(rootVC)
                            }
                        }

                    } else {
                        self.showAlert(response.message ?? "OTP verification failed")
                    }

                case .failure:
                    self.showAlert("Something went wrong. Please try again.")
                }
            }
        }
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
    
    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

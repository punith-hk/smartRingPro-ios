import UIKit

final class AddAssociationViewController: AppBaseViewController {
    
    var onSuccess: (() -> Void)?

    // MARK: - State
    private var step: AssociationStep = .enterPhone
    private var receiverId: Int?

    private let userId: Int = UserDefaults.standard.integer(forKey: "id")

    // MARK: - UI
    private let phoneField = UITextField()
    private let otpField = UITextField()
    private let relationField = UITextField()

    private let actionButton = UIButton(type: .system)

    // MARK: - Data
    private let relationOptions = ["Father", "Mother", "Brother", "Sister", "Spouse", "Other"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Association"
        setupUI()
        updateUI()
    }

    // MARK: - UI Setup
    private func setupUI() {

        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

        // Phone
        phoneField.placeholder = "Enter phone number"
        phoneField.keyboardType = .numberPad
        phoneField.backgroundColor = .white
        phoneField.layer.cornerRadius = 10
//        phoneField.addLeftPadding(16)
        phoneField.translatesAutoresizingMaskIntoConstraints = false

        // OTP
        otpField.placeholder = "Enter OTP"
        otpField.keyboardType = .numberPad
        otpField.backgroundColor = .white
        otpField.layer.cornerRadius = 10
//        otpField.setLeftPadding(16)
        otpField.translatesAutoresizingMaskIntoConstraints = false

        // Relation
        relationField.placeholder = "Select relation"
        relationField.backgroundColor = .white
        relationField.layer.cornerRadius = 10
//        relationField.setLeftPadding(16)
        relationField.translatesAutoresizingMaskIntoConstraints = false
        relationField.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openRelationSelector))
        )

        // Button
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        actionButton.layer.cornerRadius = 10
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        view.addSubview(phoneField)
        view.addSubview(otpField)
        view.addSubview(relationField)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            phoneField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            phoneField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            phoneField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            phoneField.heightAnchor.constraint(equalToConstant: 48),

            otpField.topAnchor.constraint(equalTo: phoneField.bottomAnchor, constant: 16),
            otpField.leadingAnchor.constraint(equalTo: phoneField.leadingAnchor),
            otpField.trailingAnchor.constraint(equalTo: phoneField.trailingAnchor),
            otpField.heightAnchor.constraint(equalToConstant: 48),

            relationField.topAnchor.constraint(equalTo: otpField.bottomAnchor, constant: 16),
            relationField.leadingAnchor.constraint(equalTo: phoneField.leadingAnchor),
            relationField.trailingAnchor.constraint(equalTo: phoneField.trailingAnchor),
            relationField.heightAnchor.constraint(equalToConstant: 48),

            actionButton.topAnchor.constraint(equalTo: relationField.bottomAnchor, constant: 28),
            actionButton.leadingAnchor.constraint(equalTo: phoneField.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: phoneField.trailingAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - UI State
    private func updateUI() {

        switch step {
        case .enterPhone:
            otpField.isHidden = true
            relationField.isHidden = true
            actionButton.setTitle("Send OTP", for: .normal)

        case .verifyOtp:
            otpField.isHidden = false
            relationField.isHidden = false
            actionButton.setTitle("Confirm", for: .normal)
        }
    }

    // MARK: - Actions
    @objc private func actionTapped() {

        switch step {
        case .enterPhone:
            sendOtpTapped()

        case .verifyOtp:
            verifyOtp()
        }
    }

    private func sendOtp() {

        guard let phone = phoneField.text, phone.count == 10 else {
            Toast.show(message: "Enter valid phone number", in: view)
            return
        }

        LinkedAccountService.shared.addLinkedAccount(
            userId: userId,
            phoneNumber: phone
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.receiverId = response.receiver_id
                    self?.step = .verifyOtp
                    self?.updateUI()
                    Toast.show(message: "OTP sent", in: self?.view ?? UIView())

                case .failure:
                    Toast.show(message: "Failed to send OTP", in: self?.view ?? UIView())
                }
            }
        }
    }
    
    @objc private func sendOtpTapped() {

        view.endEditing(true)   // ✅ CLOSE NUMBER PAD

        let phone = phoneField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard phone.count == 10 else {
            Toast.show(message: "Enter valid mobile number", in: view)
            return
        }

        requestOtp(phone: phone)
    }
    
    private func requestOtp(phone: String) {

        LinkedAccountService.shared.addLinkedAccount(
            userId: userId,
            phoneNumber: phone
        ) { [weak self] result in

            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {

                case .success(let response):

                    // ✅ Always show backend message
                    Toast.show(message: response.message, in: self.view)

                    // ✅ Close keyboard
                    self.view.endEditing(true)

                    // ❌ Already linked → stop flow
                    if response.message.lowercased().contains("already") {
                        return
                    }

                    // ✅ OTP flow only if receiver_id exists
                    guard let receiverId = response.receiver_id else {
                        return
                    }

                    self.receiverId = receiverId
                    self.step = .verifyOtp
                    self.updateUI()

                case .failure:
                    Toast.show(message: "Failed to send OTP", in: self.view)
                }
            }
        }
    }


    private func verifyOtp() {

        guard
            let otpText = otpField.text,
            let otp = Int(otpText),
            let relation = relationField.text,
            !relation.isEmpty,
            let receiverId = receiverId
        else {
            Toast.show(message: "Fill all fields", in: view)
            return
        }

        LinkedAccountService.shared.verifyCaretakerOtp(
            userId: userId,
            receiverId: receiverId,
            otp: otp,
            relation: relation
        ) { [weak self] result in
            DispatchQueue.main.async {
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

    // MARK: - Relation Picker
    @objc private func openRelationSelector() {

        let popup = MultiSelectPopupViewController(
            title: "Select Relation",
            options: relationOptions,
            preselected: relationField.text.map { [$0] } ?? [],
            maxSelection: 1
        )

        popup.onConfirm = { [weak self] selected in
            self?.relationField.text = selected.first
        }

        present(popup, animated: true)
    }
}

extension UITextField {

    func setHorizontalPadding(left: CGFloat = 0, right: CGFloat = 0) {

        if left > 0 {
            let leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: 1))
            self.leftView = leftView
            self.leftViewMode = .always
        }

        if right > 0 {
            let rightView = UIView(frame: CGRect(x: 0, y: 0, width: right, height: 1))
            self.rightView = rightView
            self.rightViewMode = .always
        }
    }
}

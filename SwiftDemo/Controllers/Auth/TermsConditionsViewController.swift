import UIKit

class TermsConditionsViewController: UIViewController {

    // MARK: - Colors
    private let bgColor     = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
    private let primaryBlue = UIColor(red: 13/255,  green: 153/255, blue: 255/255, alpha: 1)

    // MARK: - UI
    private let scrollView    = UIScrollView()
    private let termsTextView = UITextView()
    private let checkbox      = UIButton(type: .custom)
    private let acceptBtn     = UIButton(type: .system)
    private var isChecked     = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildUI()
    }

    // MARK: - Build UI
    private func buildUI() {
        // Root scroll
        let rootScroll = UIScrollView()
        rootScroll.backgroundColor = bgColor
        rootScroll.alwaysBounceVertical = true
        rootScroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootScroll)
        NSLayoutConstraint.activate([
            rootScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let outer = UIStackView()
        outer.axis = .vertical
        outer.spacing = 0
        outer.translatesAutoresizingMaskIntoConstraints = false
        rootScroll.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: rootScroll.contentLayoutGuide.topAnchor),
            outer.bottomAnchor.constraint(equalTo: rootScroll.contentLayoutGuide.bottomAnchor),
            outer.leadingAnchor.constraint(equalTo: rootScroll.contentLayoutGuide.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: rootScroll.contentLayoutGuide.trailingAnchor),
            outer.widthAnchor.constraint(equalTo: rootScroll.frameLayoutGuide.widthAnchor),
        ])

        outer.addArrangedSubview(buildHeader())
        outer.addArrangedSubview(buildMainCard())
        outer.addArrangedSubview(buildAcceptSection())
    }

    // MARK: - Header
    private func buildHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = bgColor

        // Logo card
        let logoCard = UIView()
        logoCard.backgroundColor = .white
        logoCard.layer.cornerRadius = 20
        logoCard.layer.shadowColor = UIColor.black.cgColor
        logoCard.layer.shadowOpacity = 0.15
        logoCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        logoCard.layer.shadowRadius = 8
        logoCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoCard.widthAnchor.constraint(equalToConstant: 88),
            logoCard.heightAnchor.constraint(equalToConstant: 88),
        ])

        let logoIV = UIImageView(image: UIImage(named: "launch_logo") ?? UIImage(systemName: "heart.fill"))
        logoIV.contentMode = .scaleAspectFit
        logoIV.tintColor = primaryBlue
        logoIV.layer.cornerRadius = 16
        logoIV.clipsToBounds = true
        logoIV.translatesAutoresizingMaskIntoConstraints = false
        logoCard.addSubview(logoIV)
        NSLayoutConstraint.activate([
            logoIV.topAnchor.constraint(equalTo: logoCard.topAnchor, constant: 6),
            logoIV.bottomAnchor.constraint(equalTo: logoCard.bottomAnchor, constant: -6),
            logoIV.leadingAnchor.constraint(equalTo: logoCard.leadingAnchor, constant: 6),
            logoIV.trailingAnchor.constraint(equalTo: logoCard.trailingAnchor, constant: -6),
        ])

        let appName  = lbl("HEARTO",                        size: 24, weight: .bold,    color: .black,       align: .center)
        let titleLbl = lbl("USER AGREEMENT & TERMS OF USE", size: 18, weight: .bold,    color: primaryBlue,  align: .center)
        let subLbl   = lbl("Please read carefully before continuing",
                            size: 14, weight: .regular, color: UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1), align: .center)

        titleLbl.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [logoCard, appName, titleLbl, subLbl])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -24),
        ])
        return header
    }

    // MARK: - Main Card
    private func buildMainCard() -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = bgColor

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 6
        card.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrap.topAnchor),
            card.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
        ])

        // Terms text view
        termsTextView.text = termsText()
        termsTextView.font = .systemFont(ofSize: 13)
        termsTextView.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        termsTextView.isEditable = false
        termsTextView.isScrollEnabled = false
        termsTextView.backgroundColor = .clear
        termsTextView.textContainerInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        termsTextView.translatesAutoresizingMaskIntoConstraints = false

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([divider.heightAnchor.constraint(equalToConstant: 1)])

        // Checkbox row
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.tintColor = primaryBlue
        checkbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkbox.widthAnchor.constraint(equalToConstant: 28),
            checkbox.heightAnchor.constraint(equalToConstant: 28),
        ])

        let checkLbl = lbl("I consent to data processing and agree to the Terms & Conditions.",
                            size: 13, weight: .regular, color: .black)
        checkLbl.numberOfLines = 0
        checkLbl.translatesAutoresizingMaskIntoConstraints = false

        let checkRow = UIStackView(arrangedSubviews: [checkbox, checkLbl])
        checkRow.axis = .horizontal
        checkRow.alignment = .center
        checkRow.spacing = 8

        let cardStack = UIStackView(arrangedSubviews: [termsTextView, divider, checkRow])
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return wrap
    }

    // MARK: - Accept Button Section
    private func buildAcceptSection() -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = bgColor

        acceptBtn.setTitle("Accept & Continue", for: .normal)
        acceptBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        acceptBtn.setTitleColor(.white, for: .normal)
        acceptBtn.backgroundColor = primaryBlue
        acceptBtn.layer.cornerRadius = 14
        acceptBtn.alpha = 0.5
        acceptBtn.isEnabled = false
        acceptBtn.translatesAutoresizingMaskIntoConstraints = false
        acceptBtn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        acceptBtn.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)

        wrap.addSubview(acceptBtn)
        NSLayoutConstraint.activate([
            acceptBtn.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 20),
            acceptBtn.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -32),
            acceptBtn.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            acceptBtn.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
        ])
        return wrap
    }

    // MARK: - Actions
    @objc private func checkboxTapped() {
        isChecked.toggle()
        let img = UIImage(systemName: isChecked ? "checkmark.square.fill" : "square")
        checkbox.setImage(img, for: .normal)
        acceptBtn.isEnabled = isChecked
        UIView.animate(withDuration: 0.2) {
            self.acceptBtn.alpha = self.isChecked ? 1.0 : 0.5
        }
    }

    @objc private func acceptTapped() {
        UserDefaultsManager.shared.setTermsAccepted(true)
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
        sceneDelegate.navigateToLogin()
    }

    // MARK: - Helpers
    private func lbl(_ text: String, size: CGFloat, weight: UIFont.Weight,
                      color: UIColor, align: NSTextAlignment = .left) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.textAlignment = align
        l.numberOfLines = 1
        return l
    }

    // MARK: - Terms Text
    private func termsText() -> String {
        return """
USER AGREEMENT / TERMS & CONDITIONS

Effective Date: 10-April-2026
Last Updated: 10-April-2026

1. INTRODUCTION
Welcome to HEARTO ("App"), owned and operated by Hearto Pvt Ltd ("Company", "We", "Us", "Our").

By downloading, installing, accessing, or using the HEARTO App, smart ring device, or associated services ("Services"), you ("User", "You") agree to be bound by this User Agreement / Terms & Conditions ("Agreement").

If you do not agree, you must not use the Services.

2. NATURE OF SERVICES
HEARTO provides:
• Continuous monitoring of physiological vitals such as heart rate, heart rate variability (HRV), SpO₂, temperature, sleep, stress, and activity
• AI-based analysis of collected data
• Alerts and notifications based on detected abnormalities
• Health insights for preventive and proactive awareness

3. IMPORTANT MEDICAL DISCLAIMER

⚠️ NOT A MEDICAL DEVICE
• The HEARTO App and Smart Ring are not certified medical devices under Indian law.
• The vitals and analytics provided are not medically vetted or clinically diagnostic.
• The system has been tested in controlled environments with an approximate accuracy of up to 95%, but results may vary based on individual conditions and usage.

⚠️ NOT A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE
• The Services are intended only for general wellness, awareness, and proactive health monitoring.
• They must not be relied upon for diagnosis, treatment, cure, or prevention of any disease.
• Always consult a qualified medical practitioner for any health concerns.

⚠️ USER RESPONSIBILITY
• You acknowledge that all alerts are indicative and not conclusive medical findings.
• The Company shall not be liable for any decisions made based on such alerts.

4. PROACTIVE ALERT SYSTEM
HEARTO uses AI to detect abnormal patterns in vitals and may generate alerts. These alerts are intended to increase awareness and encourage timely medical consultation. However, alerts may not always be accurate and should not be treated as emergency diagnosis.

5. USER DATA & PRIVACY (INDIA COMPLIANCE)
We collect and process Personal Data (name, email, phone, device identifiers) and Sensitive Personal Data (health vitals, sleep, stress, activity). Such data qualifies as SPDI under the Information Technology Act, 2000, SPDI Rules 2011, and DPDP Act 2023.

6. USER CONSENT
By using the App, you provide explicit consent for collection and processing of personal and health data, AI-based analysis, and to receive alerts and notifications. You may withdraw consent by discontinuing use of the Services.

7. DATA USAGE
We use your data to provide core app functionality, improve algorithms, generate insights, and enhance user experience. We do NOT sell personal data.

8. DATA SECURITY
We implement encryption of data in transit (TLS 1.2+) and at rest, access controls, and industry-standard cybersecurity practices. However, no system is 100% secure.

9. LIMITATION OF LIABILITY
To the maximum extent permitted under Indian law, the Company shall not be liable for any direct, indirect, incidental, or consequential damages arising from use or misuse of the App, inaccurate alerts, or failure to detect a medical condition. Services are provided "as is" and "as available".

10. EMERGENCY DISCLAIMER
HEARTO is NOT an emergency response system. It does not connect directly to hospitals, ambulances, or emergency services. In a medical emergency, immediately contact local emergency services.

11. USER OBLIGATIONS
You agree to provide accurate information, use the device as instructed, not rely solely on the App for critical health decisions, and maintain confidentiality of your account.

12. INTELLECTUAL PROPERTY
All rights including software, algorithms, trademarks, and design are owned by the Company. You may not copy, modify, reverse engineer, or distribute the App.

13. TERMINATION
We reserve the right to suspend or terminate access and modify or discontinue services.

14. GOVERNING LAW & JURISDICTION
This Agreement is governed by the laws of India. Disputes are subject to the exclusive jurisdiction of courts in [City], India.

15. UPDATES TO TERMS
We will notify you of any material changes via in-app notification or email.

16. CONTACT INFORMATION
Hearto Pvt. Ltd.
Email: support@mannaheal.com
Phone: +91 98765 43210

━━━━━━━━━━━━━━━━━━━━
ACKNOWLEDGMENT & CONSENT

By checking the box below, you confirm that you have read, understood, and agree to be bound by this User Agreement and Terms & Conditions.
"""
    }
}

import UIKit

class ReferFriendViewController: AppBaseViewController {

    // MARK: - Constants
    private let referralCode = "HEARTO20"
    private var shareMessage: String {
        "Join HEARTO — the smart health app! Use my referral code \(referralCode) to get 20% off your first treatment. Download now: https://hearto.app"
    }

    // MARK: - Colors
    private let bgColor      = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
    private let primaryBlue  = UIColor(red: 13/255,  green: 153/255, blue: 255/255, alpha: 1)
    private let textPrimary  = UIColor(red: 26/255,  green: 26/255,  blue: 26/255,  alpha: 1)
    private let textGray     = UIColor(red: 68/255,  green: 68/255,  blue: 68/255,  alpha: 1)
    private let copyGreen    = UIColor(red: 0/255,   green: 200/255, blue: 155/255, alpha: 1)

    // Hold a ref to apply dashed border after layout
    private weak var codeContainer: UIView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        buildUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let v = codeContainer {
            addDashedBorder(to: v, color: primaryBlue)
        }
    }

    // MARK: - Build UI
    private func buildUI() {
        let scroll = UIScrollView()
        scroll.backgroundColor = bgColor
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        // Header
        let titleLbl = makeLbl("Refer & Earn", size: 22, weight: .bold, color: textPrimary, align: .center)
        let subLbl   = makeLbl("Invite friends to HEARTO and both of you get 20% off on your first treatment",
                                size: 13, weight: .regular, color: textGray, align: .center)
        subLbl.numberOfLines = 0
        stack.addArrangedSubview(titleLbl)
        stack.addArrangedSubview(subLbl)

        // Cards
        stack.addArrangedSubview(buildReferralCard())
        stack.addArrangedSubview(buildHowItWorksCard())
        stack.addArrangedSubview(buildShareViaCard())

        // Share Invite Button
        let btn = UIButton(type: .system)
        btn.setTitle("SHARE INVITE LINK", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = primaryBlue
        btn.layer.cornerRadius = 14
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        btn.addTarget(self, action: #selector(shareGeneralTapped), for: .touchUpInside)
        stack.addArrangedSubview(btn)
    }

    // MARK: - Referral Code Card
    private func buildReferralCard() -> UIView {
        let card = makeCard()
        let lbl  = makeLbl("Your Referral Code", size: 13, weight: .bold, color: textPrimary)

        // Dashed code container
        let container = UIView()
        container.backgroundColor = UIColor(red: 235/255, green: 248/255, blue: 255/255, alpha: 1)
        container.layer.cornerRadius = 10
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true
        codeContainer = container

        let codeLbl = makeLbl(referralCode, size: 22, weight: .bold, color: primaryBlue)
        codeLbl.translatesAutoresizingMaskIntoConstraints = false

        let copyBtn = UIButton(type: .system)
        copyBtn.setTitle("  Copy", for: .normal)
        copyBtn.setTitleColor(.white, for: .normal)
        copyBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        copyBtn.setImage(UIImage(systemName: "doc.on.doc.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        copyBtn.tintColor = .white
        copyBtn.backgroundColor = copyGreen
        copyBtn.layer.cornerRadius = 8
        copyBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 14)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        copyBtn.addTarget(self, action: #selector(copyCodeTapped), for: .touchUpInside)

        container.addSubview(codeLbl)
        container.addSubview(copyBtn)
        NSLayoutConstraint.activate([
            codeLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            codeLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            copyBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            copyBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
        ])

        let vstack = UIStackView(arrangedSubviews: [lbl, container])
        vstack.axis = .vertical
        vstack.spacing = 12
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return card
    }

    // MARK: - How It Works Card
    private func buildHowItWorksCard() -> UIView {
        let card = makeCard()

        let steps: [(String, String, String, UIColor, UIColor)] = [
            // (number, title, desc, badgeBg, badgeText)
            ("1", "Share your code",   "Send your referral code to friends & family",
             UIColor(red: 232/255, green: 234/255, blue: 255/255, alpha: 1),
             UIColor(red: 83/255,  green: 109/255, blue: 254/255, alpha: 1)),
            ("2", "Friend signs up",   "They register on HEARTO using your code",
             UIColor(red: 232/255, green: 245/255, blue: 233/255, alpha: 1),
             UIColor(red: 76/255,  green: 175/255, blue: 80/255,  alpha: 1)),
            ("3", "Both get rewarded", "You both enjoy 20% off your first treatment",
             UIColor(red: 255/255, green: 243/255, blue: 224/255, alpha: 1),
             UIColor(red: 255/255, green: 160/255, blue: 0/255,   alpha: 1)),
        ]

        let titleLbl = makeLbl("How It Works", size: 13, weight: .bold, color: textPrimary)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let stepStack = UIStackView()
        stepStack.axis = .vertical
        stepStack.spacing = 14
        stepStack.translatesAutoresizingMaskIntoConstraints = false

        for (num, title, desc, badgeBg, badgeColor) in steps {
            stepStack.addArrangedSubview(makeStep(num: num, title: title, desc: desc,
                                                   badgeBg: badgeBg, badgeColor: badgeColor))
        }

        let vstack = UIStackView(arrangedSubviews: [titleLbl, stepStack])
        vstack.axis = .vertical
        vstack.spacing = 16
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return card
    }

    // MARK: - Share Via Card
    private func buildShareViaCard() -> UIView {
        let card = makeCard()
        let titleLbl = makeLbl("Share via", size: 13, weight: .bold, color: textPrimary)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let btnRow = UIStackView()
        btnRow.axis = .horizontal
        btnRow.distribution = .fillEqually
        btnRow.spacing = 8

        let platforms: [(String, String, UIColor, Selector)] = [
            ("whatsapp.fill",            "WhatsApp", UIColor(red: 37/255,  green: 211/255, blue: 102/255, alpha: 1), #selector(shareWhatsAppTapped)),
            ("message.fill",             "SMS",      primaryBlue,                                                     #selector(shareSMSTapped)),
            ("person.2.circle.fill",     "Facebook", UIColor(red: 24/255,  green: 119/255, blue: 242/255, alpha: 1), #selector(shareFacebookTapped)),
            ("square.and.arrow.up.fill", "More",     UIColor(red: 85/255,  green: 85/255,  blue: 85/255,  alpha: 1), #selector(shareGeneralTapped)),
        ]

        for (icon, name, color, action) in platforms {
            btnRow.addArrangedSubview(makePlatformButton(icon: icon, label: name, color: color, action: action))
        }

        let vstack = UIStackView(arrangedSubviews: [titleLbl, btnRow])
        vstack.axis = .vertical
        vstack.spacing = 14
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return card
    }

    // MARK: - Actions
    @objc private func copyCodeTapped() {
        UIPasteboard.general.string = referralCode
        Toast.show(message: "Code copied to clipboard!", in: view)
    }

    @objc private func shareWhatsAppTapped() {
        let encoded = shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "whatsapp://send?text=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            shareGeneral()
        }
    }

    @objc private func shareSMSTapped() {
        if let url = URL(string: "sms:&body=\(shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func shareFacebookTapped() {
        let encoded = shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "fb://compose?text=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            shareGeneral()
        }
    }

    @objc private func shareGeneralTapped() {
        shareGeneral()
    }

    private func shareGeneral() {
        let vc = UIActivityViewController(activityItems: [shareMessage], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    // MARK: - Factory Helpers
    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 14
        v.layer.shadowColor  = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 6
        return v
    }

    private func makeStep(num: String, title: String, desc: String,
                           badgeBg: UIColor, badgeColor: UIColor) -> UIView {
        let badge = UILabel()
        badge.text = num
        badge.font = .systemFont(ofSize: 15, weight: .bold)
        badge.textColor = badgeColor
        badge.textAlignment = .center
        badge.backgroundColor = badgeBg
        badge.layer.cornerRadius = 20
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 40),
            badge.heightAnchor.constraint(equalToConstant: 40),
        ])

        let titleLbl = makeLbl(title, size: 13, weight: .bold,    color: textPrimary)
        let descLbl  = makeLbl(desc,  size: 12, weight: .regular, color: UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1))
        descLbl.numberOfLines = 0

        let text = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        text.axis = .vertical
        text.spacing = 2

        let row = UIStackView(arrangedSubviews: [badge, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        return row
    }

    private func makePlatformButton(icon: String, label name: String,
                                     color: UIColor, action: Selector) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 10
        container.layer.shadowColor  = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowOffset  = CGSize(width: 0, height: 1)
        container.layer.shadowRadius  = 3

        let iv = UIImageView(image: UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate))
        iv.tintColor = color
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false

        let lbl = makeLbl(name, size: 11, weight: .regular, color: textPrimary, align: .center)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let vstack = UIStackView(arrangedSubviews: [iv, lbl])
        vstack.axis = .vertical
        vstack.alignment = .center
        vstack.spacing = 5
        vstack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vstack)
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 28),
            iv.heightAnchor.constraint(equalToConstant: 28),
            vstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            vstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            vstack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: action)
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        return container
    }

    private func makeLbl(_ text: String, size: CGFloat, weight: UIFont.Weight,
                          color: UIColor, align: NSTextAlignment = .left) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.textAlignment = align
        l.numberOfLines = 1
        return l
    }

    private func addDashedBorder(to view: UIView, color: UIColor) {
        // Remove existing dashed layers
        view.layer.sublayers?.removeAll { $0.name == "dashedBorder" }
        let dash = CAShapeLayer()
        dash.name = "dashedBorder"
        dash.strokeColor = color.cgColor
        dash.fillColor = UIColor.clear.cgColor
        dash.lineWidth = 1.5
        dash.lineDashPattern = [6, 4]
        dash.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        dash.frame = view.bounds
        view.layer.addSublayer(dash)
    }
}



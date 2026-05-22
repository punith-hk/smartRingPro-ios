import UIKit

class HelpSupportViewController: AppBaseViewController {

    // MARK: - Colors
    private let bgColor      = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
    private let primaryBlue  = UIColor(red: 13/255,  green: 153/255, blue: 255/255, alpha: 1)
    private let textPrimary  = UIColor(red: 26/255,  green: 26/255,  blue: 26/255,  alpha: 1)
    private let textSecond   = UIColor(red: 85/255,  green: 85/255,  blue: 85/255,  alpha: 1)
    private let textTertiary = UIColor(red: 136/255, green: 136/255, blue: 136/255, alpha: 1)
    private let contactCardBg = UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1)
    private let hoursCardBg   = UIColor(red: 255/255, green: 248/255, blue: 225/255, alpha: 1)

    // MARK: - Screen containers
    private var screenMenu:    UIScrollView!
    private var screenFaq:     UIView!
    private var screenContact: UIView!
    private var screenReport:  UIView!
    private var screenGuide:   UIView!
    private var screenPrivacy: UIView!
    private var allScreens:    [UIView] = []

    // MARK: - Report Issue refs
    private var selectedCategory: String?
    private var selectedImages:   [UIImage] = []
    private let maxImages = 3
    private weak var categoryBtn:         UIButton?
    private weak var descriptionTextView: UITextView?
    private weak var thumbStack:          UIStackView?
    private weak var thumbScrollView:     UIScrollView?
    private weak var uploadHintLbl:       UILabel?

    // MARK: - Category data
    fileprivate struct CatItem { let title: String; let isHeader: Bool; let isHint: Bool }
    private lazy var categoryItems: [CatItem] = {
        var items: [CatItem] = []
        items.append(CatItem(title: "Select a category",          isHeader: false, isHint: true))
        items.append(CatItem(title: "── Ring Issues ──",          isHeader: true,  isHint: false))
        ["Ring Not Connecting", "Ring Not Charging", "Ring Not Pairing / Pairing Failed",
         "Ring Disconnects Frequently", "Ring Not Syncing Data", "Ring Battery Drains Too Fast",
         "Ring Firmware Update Failed", "Ring Not Tracking Heart Rate",
         "Ring Not Tracking Blood Pressure", "Ring Not Tracking Blood Oxygen (SpO2)",
         "Ring Not Tracking ECG", "Ring Not Tracking Sleep", "Ring Not Tracking Steps",
         "Ring Not Tracking Body Temperature", "Ring Display / LED Issue",
         "Ring Physical Damage"]
            .forEach { items.append(CatItem(title: $0, isHeader: false, isHint: false)) }
        items.append(CatItem(title: "── App Issues ──",           isHeader: true,  isHint: false))
        ["App Crashes or Freezes", "App Not Loading Data / Dashboard Empty",
         "Notifications Not Working", "Health Data Not Showing Correctly",
         "ECG Report Not Generating", "Appointment Booking Issue",
         "Doctor / Specialist Not Available", "Profile / Account Settings Issue",
         "Linked Account / Family Member Issue", "Login / Authentication Issue",
         "App Running Slow"]
            .forEach { items.append(CatItem(title: $0, isHeader: false, isHint: false)) }
        items.append(CatItem(title: "── Other ──",                isHeader: true,  isHint: false))
        items.append(CatItem(title: "Other / Not Listed Above",   isHeader: false, isHint: false))
        return items
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        buildAllScreens()
    }

    // MARK: - Build + show all screens
    private func buildAllScreens() {
        screenMenu    = buildMenuScreen()
        screenFaq     = buildSubScreen(title: "Frequently Asked Questions", builder: buildFaqContent)
        screenContact = buildSubScreen(title: "Contact Us",                 builder: buildContactContent)
        screenReport  = buildSubScreen(title: "Report an Issue",            builder: buildReportContent)
        screenGuide   = buildSubScreen(title: "App Guide",                  builder: buildGuideContent)
        screenPrivacy = buildSubScreen(title: "Privacy Policy",             builder: buildPrivacyContent)

        allScreens = [screenMenu, screenFaq, screenContact, screenReport, screenGuide, screenPrivacy]
        for screen in allScreens {
            screen.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(screen)
            NSLayoutConstraint.activate([
                screen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                screen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                screen.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                screen.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
        showScreen(screenMenu)
    }

    private func showScreen(_ screen: UIView) {
        allScreens.forEach { $0.isHidden = true }
        screen.isHidden = false
    }

    // MARK: - Menu Screen
    private func buildMenuScreen() -> UIScrollView {
        let scroll = UIScrollView()
        scroll.backgroundColor = bgColor
        scroll.alwaysBounceVertical = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Header
        let iconBg = UIView()
        iconBg.backgroundColor = primaryBlue.withAlphaComponent(0.18)
        iconBg.layer.cornerRadius = 36

        let iconIV = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        iconIV.tintColor = primaryBlue
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconIV)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 72),
            iconBg.heightAnchor.constraint(equalToConstant: 72),
            iconIV.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 44),
            iconIV.heightAnchor.constraint(equalToConstant: 44),
        ])

        let titleLbl    = makeLabel("Help & Support",        size: 22, weight: .bold,    color: textPrimary, align: .center)
        let subtitleLbl = makeLabel("We're here to help you", size: 14, weight: .regular, color: textPrimary, align: .center)

        let hdrStack = UIStackView(arrangedSubviews: [iconBg, titleLbl, subtitleLbl])
        hdrStack.axis = .vertical
        hdrStack.alignment = .center
        hdrStack.spacing = 10

        let hdrWrap = UIView()
        hdrStack.translatesAutoresizingMaskIntoConstraints = false
        hdrWrap.addSubview(hdrStack)
        NSLayoutConstraint.activate([
            hdrStack.topAnchor.constraint(equalTo: hdrWrap.topAnchor, constant: 24),
            hdrStack.bottomAnchor.constraint(equalTo: hdrWrap.bottomAnchor, constant: -12),
            hdrStack.centerXAnchor.constraint(equalTo: hdrWrap.centerXAnchor),
        ])

        stack.addArrangedSubview(hdrWrap)
        stack.addArrangedSubview(makeMenuCard(icon: "list.bullet.rectangle.portrait.fill",
                                              title: "Frequently Asked Questions",
                                              subtitle: "Find answers to common questions")       { [weak self] in self?.showScreen(self!.screenFaq) })
        stack.addArrangedSubview(makeMenuCard(icon: "message.fill",
                                              title: "Contact Us",
                                              subtitle: "Get in touch with our support team")    { [weak self] in self?.showScreen(self!.screenContact) })
        stack.addArrangedSubview(makeMenuCard(icon: "exclamationmark.circle.fill",
                                              title: "Report an Issue",
                                              subtitle: "Let us know if something isn't working") { [weak self] in self?.showScreen(self!.screenReport) })
        stack.addArrangedSubview(makeMenuCard(icon: "book.fill",
                                              title: "App Guide",
                                              subtitle: "Learn how to use HEARTO")               { [weak self] in self?.showScreen(self!.screenGuide) })
        stack.addArrangedSubview(makeMenuCard(icon: "moon.fill",
                                              title: "Privacy Policy",
                                              subtitle: "Read how we protect your data")         { [weak self] in self?.showScreen(self!.screenPrivacy) })

        let bottomPad = UIView(); bottomPad.heightAnchor.constraint(equalToConstant: 24).isActive = true
        stack.addArrangedSubview(bottomPad)

        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        return scroll
    }

    // MARK: - Sub-screen wrapper (blue header bar + scroll content)
    private func buildSubScreen(title: String, builder: @escaping (UIScrollView) -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = bgColor

        let headerBar = UIView()
        headerBar.backgroundColor = primaryBlue
        headerBar.translatesAutoresizingMaskIntoConstraints = false

        let hdrTitle = makeLabel(title, size: 17, weight: .bold, color: .white, align: .center)
        hdrTitle.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(closeSubScreenTapped), for: .touchUpInside)

        headerBar.addSubview(hdrTitle)
        headerBar.addSubview(closeBtn)
        NSLayoutConstraint.activate([
            headerBar.heightAnchor.constraint(equalToConstant: 56),
            hdrTitle.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            hdrTitle.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            hdrTitle.leadingAnchor.constraint(greaterThanOrEqualTo: headerBar.leadingAnchor, constant: 56),
            hdrTitle.trailingAnchor.constraint(lessThanOrEqualTo: closeBtn.leadingAnchor, constant: -8),
            closeBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 36),
            closeBtn.heightAnchor.constraint(equalToConstant: 36),
        ])

        let contentScroll = UIScrollView()
        contentScroll.backgroundColor = bgColor
        contentScroll.alwaysBounceVertical = true
        contentScroll.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(headerBar)
        container.addSubview(contentScroll)
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: container.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentScroll.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            contentScroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentScroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentScroll.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        builder(contentScroll)
        return container
    }

    // Embed a vertical UIStackView inside a scroll view with 20pt side padding
    private func makeScrollStack(in scroll: UIScrollView, spacing: CGFloat = 12) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        return stack
    }

    // MARK: - FAQ Content
    private func buildFaqContent(_ scroll: UIScrollView) {
        let stack = makeScrollStack(in: scroll, spacing: 10)

        let sections: [(String, [(String, String)])] = [
            ("Ring Issues", [
                ("Why won't my ring connect to the app?",
                 "Ensure Bluetooth is ON. Restart the ring by charging it for 10 seconds. Force-close and reopen the HEARTO app, then tap + Add Device to re-pair."),
                ("My ring battery drains very fast. What can I do?",
                 "Continuous heart rate or SpO2 monitoring consumes extra battery. Try setting measurements to interval mode (e.g. every 5 min) in Device Settings. Also ensure the firmware is up to date."),
                ("Ring firmware update failed. How do I retry?",
                 "Keep the ring on the charger and close to the phone. Go to Device Settings → Firmware Update and tap Retry. Ensure your phone has at least 30% battery and a stable internet connection."),
                ("Health data is not syncing to the dashboard.",
                 "Pull down the dashboard to manually refresh. Make sure the ring is connected (green dot in top bar). If it still doesn't sync, disconnect and reconnect the ring from Device Settings."),
            ]),
            ("App Issues", [
                ("How do I book an appointment with a doctor?",
                 "Tap the Appointments tab at the bottom. Select a specialist, choose a date and time slot, then confirm. You will receive a confirmation notification. Ensure your profile is complete before booking."),
                ("I'm not receiving notifications from the app.",
                 "Go to iOS Settings → HEARTO → Notifications and ensure they are enabled. Also check that Background App Refresh is on for HEARTO so the service can run uninterrupted."),
                ("My ECG report is not generating.",
                 "Keep your finger still on the ring sensor throughout the full 30-second ECG measurement. Ensure the ring is correctly positioned on your finger. After recording, the report generates within a few seconds on the ECG screen."),
                ("How do I add a family member / linked account?",
                 "Go to Profile → Linked Accounts → Add Member. Enter their mobile number and confirm. They will receive a link request. Once accepted, you can switch between linked profiles from the Profile screen."),
            ]),
            ("General", [
                ("Is my health data secure?",
                 "Yes. All data is encrypted in transit (TLS 1.2+) and at rest. We do not sell your personal or health data. Read our full Privacy Policy for details."),
                ("How do I delete my account and data?",
                 "Go to Profile → Account Settings → Delete Account. Confirm with your password. Your data will be permanently removed within 30 days. Alternatively email us at support@mannaheal.com."),
            ]),
        ]

        for (sectionTitle, faqs) in sections {
            stack.addArrangedSubview(makeSectionHeader(sectionTitle))
            for (q, a) in faqs {
                stack.addArrangedSubview(makeFaqCard(question: q, answer: a))
            }
        }
    }

    // MARK: - Contact Content
    private func buildContactContent(_ scroll: UIScrollView) {
        let stack = makeScrollStack(in: scroll, spacing: 12)

        let desc = makeLabel("Reach out to our support team — we're happy to help!",
                             size: 14, weight: .regular, color: textSecond)
        desc.numberOfLines = 0
        stack.addArrangedSubview(desc)

        // Email card
        let emailCard = makeContactCard(
            icon: "message.fill",
            iconColor: primaryBlue,
            bgColor: contactCardBg,
            title: "Email Support",
            detail: "support@mannaheal.com",
            detailColor: primaryBlue
        )
        emailCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(emailTapped)))
        emailCard.isUserInteractionEnabled = true
        stack.addArrangedSubview(emailCard)

        // Phone card
        let phoneCard = makeContactCard(
            icon: "phone.fill",
            iconColor: primaryBlue,
            bgColor: contactCardBg,
            title: "Phone Support",
            detail: "+91 98765 43210",
            detailColor: primaryBlue
        )
        phoneCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(phoneTapped)))
        phoneCard.isUserInteractionEnabled = true
        stack.addArrangedSubview(phoneCard)

        // Hours card
        let hoursCard = makeContactCard(
            icon: "timer",
            iconColor: UIColor(red: 255/255, green: 160/255, blue: 0/255, alpha: 1),
            bgColor: hoursCardBg,
            title: "Support Hours",
            detail: "Mon–Sat: 9:00 AM – 6:00 PM IST",
            detailColor: UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)
        )
        stack.addArrangedSubview(hoursCard)
    }

    // MARK: - Report Content
    private func buildReportContent(_ scroll: UIScrollView) {
        let stack = makeScrollStack(in: scroll, spacing: 16)

        // Category
        stack.addArrangedSubview(makeFormLabel("Issue Category"))

        let btn = UIButton(type: .system)
        btn.setTitle("Select a category", for: .normal)
        btn.setTitleColor(textTertiary, for: .normal)
        btn.contentHorizontalAlignment = .left
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 40)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 10
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.08
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = textTertiary
        chevron.translatesAutoresizingMaskIntoConstraints = false
        btn.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -14),
            chevron.widthAnchor.constraint(equalToConstant: 18),
            chevron.heightAnchor.constraint(equalToConstant: 18),
        ])
        btn.addTarget(self, action: #selector(showCategoryPickerTapped), for: .touchUpInside)
        categoryBtn = btn
        stack.addArrangedSubview(btn)

        // Description
        stack.addArrangedSubview(makeFormLabel("Problem Description"))
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 14)
        tv.textColor = textPrimary
        tv.backgroundColor = .white
        tv.layer.cornerRadius = 10
        tv.layer.shadowColor = UIColor.black.cgColor
        tv.layer.shadowOpacity = 0.08
        tv.layer.shadowOffset = CGSize(width: 0, height: 2)
        tv.layer.shadowRadius = 4
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.heightAnchor.constraint(equalToConstant: 110).isActive = true
        // Placeholder
        tv.text = "Describe the issue in detail..."
        tv.textColor = textTertiary
        tv.delegate = self
        descriptionTextView = tv
        stack.addArrangedSubview(tv)

        // Attach screenshots
        stack.addArrangedSubview(makeFormLabel("Attach Screenshots (optional)"))

        let uploadArea = UIView()
        uploadArea.backgroundColor = .white
        uploadArea.layer.cornerRadius = 10
        uploadArea.layer.borderWidth = 1.5
        uploadArea.layer.borderColor = primaryBlue.withAlphaComponent(0.4).cgColor
        uploadArea.layer.shadowColor = UIColor.black.cgColor
        uploadArea.layer.shadowOpacity = 0.05
        uploadArea.layer.shadowOffset = CGSize(width: 0, height: 1)
        uploadArea.layer.shadowRadius = 3
        uploadArea.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        let uploadStack = UIStackView()
        uploadStack.axis = .vertical
        uploadStack.alignment = .center
        uploadStack.spacing = 6
        uploadStack.translatesAutoresizingMaskIntoConstraints = false

        let uploadIcon = UIImageView(image: UIImage(systemName: "square.and.arrow.up"))
        uploadIcon.tintColor = primaryBlue
        uploadIcon.contentMode = .scaleAspectFit
        uploadIcon.widthAnchor.constraint(equalToConstant: 32).isActive = true
        uploadIcon.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let hintLbl = makeLabel("Tap to upload images (max 3)", size: 12, weight: .regular, color: primaryBlue, align: .center)
        uploadHintLbl = hintLbl

        uploadStack.addArrangedSubview(uploadIcon)
        uploadStack.addArrangedSubview(hintLbl)
        uploadArea.addSubview(uploadStack)
        NSLayoutConstraint.activate([
            uploadStack.centerXAnchor.constraint(equalTo: uploadArea.centerXAnchor),
            uploadStack.topAnchor.constraint(equalTo: uploadArea.topAnchor, constant: 12),
            uploadStack.bottomAnchor.constraint(equalTo: uploadArea.bottomAnchor, constant: -12),
        ])
        uploadArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(uploadImagesTapped)))
        uploadArea.isUserInteractionEnabled = true
        stack.addArrangedSubview(uploadArea)

        // Thumbnail scroll
        let thumbSV = UIScrollView()
        thumbSV.showsHorizontalScrollIndicator = false
        thumbSV.isHidden = true
        thumbSV.heightAnchor.constraint(equalToConstant: 88).isActive = true
        thumbScrollView = thumbSV

        let ts = UIStackView()
        ts.axis = .horizontal
        ts.spacing = 8
        ts.alignment = .center
        ts.translatesAutoresizingMaskIntoConstraints = false
        thumbSV.addSubview(ts)
        NSLayoutConstraint.activate([
            ts.topAnchor.constraint(equalTo: thumbSV.contentLayoutGuide.topAnchor),
            ts.bottomAnchor.constraint(equalTo: thumbSV.contentLayoutGuide.bottomAnchor),
            ts.leadingAnchor.constraint(equalTo: thumbSV.contentLayoutGuide.leadingAnchor),
            ts.trailingAnchor.constraint(equalTo: thumbSV.contentLayoutGuide.trailingAnchor),
            ts.heightAnchor.constraint(equalTo: thumbSV.frameLayoutGuide.heightAnchor),
        ])
        thumbStack = ts
        stack.addArrangedSubview(thumbSV)

        // Submit
        let submitBtn = UIButton(type: .system)
        submitBtn.setTitle("Submit Report", for: .normal)
        submitBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.backgroundColor = primaryBlue
        submitBtn.layer.cornerRadius = 12
        submitBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitBtn.addTarget(self, action: #selector(submitReportTapped), for: .touchUpInside)
        stack.addArrangedSubview(submitBtn)
    }

    // MARK: - App Guide Content
    private func buildGuideContent(_ scroll: UIScrollView) {
        let stack = makeScrollStack(in: scroll, spacing: 10)

        let steps: [(String, String)] = [
            ("Create Your Account",
             "Download HEARTO, open the app and sign up with your mobile number. Complete your profile (name, DOB, gender, height, weight) for accurate health insights."),
            ("Pair Your HEARTO Ring",
             "Enable Bluetooth. On the Dashboard tap the + icon or go to Device Settings → Add Device. Place the ring near your phone and follow the on-screen pairing steps."),
            ("Sync Your Health Data",
             "Once paired, the ring automatically starts tracking heart rate, blood pressure, SpO2, steps, sleep, and ECG. Pull down the dashboard to manually sync latest data."),
            ("View Your Health Dashboard",
             "Navigate using the bottom tabs: Health (Dashboard), Appointments, Device, and Family Care. Tap any health card to view detailed trends and history."),
            ("Book an Appointment",
             "Tap Appointments → Book New Appointment. Choose a specialist, select date/time, and confirm. You'll receive a notification and can manage appointments from the Appointments tab."),
            ("Configure Ring Settings",
             "Go to Device Settings to adjust measurement intervals (15, 30, 45, or 60 min), update firmware, calibrate sensors, or disconnect the ring."),
            ("Add Family Members",
             "From Profile → Linked Accounts, add family members by entering their mobile number. Once accepted, switch between profiles to monitor their health."),
            ("Review Notifications",
             "Enable notifications for health alerts, appointment reminders, and ring battery warnings. Configure sound and vibration in Profile → Settings."),
        ]

        for (index, (title, desc)) in steps.enumerated() {
            stack.addArrangedSubview(makeGuideStep(number: index + 1, title: title, desc: desc))
        }
    }

    // MARK: - Privacy Content
    private func buildPrivacyContent(_ scroll: UIScrollView) {
        let stack = makeScrollStack(in: scroll, spacing: 0)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4

        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.font = .systemFont(ofSize: 14)
        tv.textColor = textPrimary
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.text = privacyPolicyText()

        card.addSubview(tv)
        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: card.topAnchor),
            tv.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            tv.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: card.trailingAnchor),
        ])
        stack.addArrangedSubview(card)
    }

    // MARK: - Actions
    @objc private func emailTapped() {
        let email = "support@mannaheal.com"
        if let url = URL(string: "mailto:\(email)?subject=HEARTO%20App%20Support%20Request") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func phoneTapped() {
        if let url = URL(string: "tel:+919876543210") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func uploadImagesTapped() {
        guard selectedImages.count < maxImages else {
            Toast.show(message: "Maximum \(maxImages) images allowed", in: view); return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func closeSubScreenTapped() {
        showScreen(screenMenu)
    }

    @objc private func showCategoryPickerTapped() {
        showCategoryPicker()
    }

    private func showCategoryPicker() {
        let sheet = CategoryPickerSheet(items: categoryItems) { [weak self] selected in
            guard let self = self else { return }
            self.selectedCategory = selected
            self.categoryBtn?.setTitle(selected, for: .normal)
            self.categoryBtn?.setTitleColor(self.textPrimary, for: .normal)
        }
        sheet.modalPresentationStyle = .pageSheet
        present(sheet, animated: true)
    }

    @objc private func submitReportTapped() {
        guard let cat = selectedCategory, !cat.isEmpty else {
            Toast.show(message: "Please select an issue category", in: view); return
        }
        let desc = descriptionTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isPlaceholder = desc == "Describe the issue in detail..." || desc.isEmpty
        if isPlaceholder {
            Toast.show(message: "Please describe the issue", in: view); return
        }
        // TODO: wire to API endpoint
        Toast.show(message: "Report submitted successfully!", in: view)
        selectedCategory = nil
        categoryBtn?.setTitle("Select a category", for: .normal)
        categoryBtn?.setTitleColor(textTertiary, for: .normal)
        descriptionTextView?.text = "Describe the issue in detail..."
        descriptionTextView?.textColor = textTertiary
        selectedImages.removeAll()
        refreshThumbnails()
        showScreen(screenMenu)
    }

    @objc private func deleteThumbnailTapped(_ sender: UIButton) {
        guard sender.tag < selectedImages.count else { return }
        selectedImages.remove(at: sender.tag)
        refreshThumbnails()
    }

    private func refreshThumbnails() {
        guard let ts = thumbStack, let sv = thumbScrollView, let hint = uploadHintLbl else { return }
        ts.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if selectedImages.isEmpty {
            sv.isHidden = true
            hint.text = "Tap to upload images (max \(maxImages))"
        } else {
            sv.isHidden = false
            hint.text = "\(selectedImages.count)/\(maxImages) image(s) selected"
            for (i, img) in selectedImages.enumerated() {
                let frame = UIView()
                frame.widthAnchor.constraint(equalToConstant: 72).isActive = true
                frame.heightAnchor.constraint(equalToConstant: 72).isActive = true

                let iv = UIImageView(image: img)
                iv.contentMode = .scaleAspectFill
                iv.clipsToBounds = true
                iv.layer.cornerRadius = 8
                iv.translatesAutoresizingMaskIntoConstraints = false
                frame.addSubview(iv)
                NSLayoutConstraint.activate([
                    iv.topAnchor.constraint(equalTo: frame.topAnchor),
                    iv.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
                    iv.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
                    iv.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
                ])

                let delBtn = UIButton(type: .system)
                delBtn.setImage(UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
                delBtn.tintColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)
                delBtn.backgroundColor = .white
                delBtn.layer.cornerRadius = 11
                delBtn.translatesAutoresizingMaskIntoConstraints = false
                delBtn.tag = i
                delBtn.addTarget(self, action: #selector(deleteThumbnailTapped(_:)), for: .touchUpInside)
                frame.addSubview(delBtn)
                NSLayoutConstraint.activate([
                    delBtn.topAnchor.constraint(equalTo: frame.topAnchor, constant: -4),
                    delBtn.trailingAnchor.constraint(equalTo: frame.trailingAnchor, constant: 4),
                    delBtn.widthAnchor.constraint(equalToConstant: 22),
                    delBtn.heightAnchor.constraint(equalToConstant: 22),
                ])

                ts.addArrangedSubview(frame)
            }
        }
    }

    // MARK: - Factory helpers
    private func makeMenuCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 5

        let iconBg = UIView()
        iconBg.backgroundColor = primaryBlue.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 22
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView(image: UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate))
        iv.tintColor = primaryBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iv)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),
            iv.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 24),
            iv.heightAnchor.constraint(equalToConstant: 24),
        ])

        let titleLbl    = makeLabel(title,    size: 15, weight: .semibold, color: textPrimary)
        let subtitleLbl = makeLabel(subtitle, size: 12, weight: .regular,  color: textTertiary)

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        textStack.axis = .vertical
        textStack.spacing = 3

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = textTertiary
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arrow.widthAnchor.constraint(equalToConstant: 14),
            arrow.heightAnchor.constraint(equalToConstant: 14),
        ])

        let row = UIStackView(arrangedSubviews: [iconBg, textStack, arrow])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])

        let tap = UITapGestureRecognizer(target: nil, action: nil)
        tap.addTarget(block: action)
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        return card
    }

    private func makeContactCard(icon: String, iconColor: UIColor, bgColor: UIColor,
                                  title: String, detail: String, detailColor: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = bgColor
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4

        let iconBg = UIView()
        iconBg.backgroundColor = iconColor.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 22
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView(image: UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate))
        iv.tintColor = iconColor
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iv)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),
            iv.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 22),
            iv.heightAnchor.constraint(equalToConstant: 22),
        ])

        let titleLbl  = makeLabel(title,  size: 14, weight: .semibold, color: textPrimary)
        let detailLbl = makeLabel(detail, size: 13, weight: .regular,  color: detailColor)

        let textStack = UIStackView(arrangedSubviews: [titleLbl, detailLbl])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [iconBg, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return card
    }

    private func makeFaqCard(question: String, answer: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4

        let qLbl = makeLabel(question, size: 14, weight: .semibold, color: textPrimary)
        qLbl.numberOfLines = 0

        let aLbl = makeLabel(answer, size: 13, weight: .regular, color: textSecond)
        aLbl.numberOfLines = 0

        let vstack = UIStackView(arrangedSubviews: [qLbl, aLbl])
        vstack.axis = .vertical
        vstack.spacing = 8
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])
        return card
    }

    private func makeSectionHeader(_ text: String) -> UIView {
        let lbl = makeLabel(text, size: 13, weight: .bold, color: primaryBlue)
        let wrap = UIView()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 6),
            lbl.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -2),
            lbl.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 4),
            lbl.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
        ])
        return wrap
    }

    private func makeGuideStep(number: Int, title: String, desc: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 10
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4

        let badge = UILabel()
        badge.text = "\(number)"
        badge.font = .systemFont(ofSize: 15, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = primaryBlue
        badge.layer.cornerRadius = 18
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 36),
            badge.heightAnchor.constraint(equalToConstant: 36),
        ])

        let titleLbl = makeLabel(title, size: 14, weight: .semibold, color: textPrimary)
        let descLbl  = makeLabel(desc,  size: 13, weight: .regular,  color: textSecond)
        descLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        textStack.axis = .vertical
        textStack.spacing = 5

        let row = UIStackView(arrangedSubviews: [badge, textStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])
        return card
    }

    private func makeFormLabel(_ text: String) -> UILabel {
        let lbl = makeLabel(text, size: 14, weight: .regular, color: textPrimary)
        return lbl
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight,
                            color: UIColor, align: NSTextAlignment = .left) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: size, weight: weight)
        lbl.textColor = color
        lbl.textAlignment = align
        lbl.numberOfLines = 1
        return lbl
    }

    private func privacyPolicyText() -> String {
        return """
HEARTO – Privacy Policy & Terms of Use

Last Updated: April 2026

1. INTRODUCTION
Welcome to HEARTO, a smart health monitoring application developed by MannaHeal. By using this app, you agree to the terms outlined in this policy.

2. DATA WE COLLECT
• Health metrics: Heart rate, blood pressure, SpO2, ECG, sleep, steps, body temperature
• Personal information: Name, mobile number, date of birth, gender, profile photo
• Device information: Ring MAC address, firmware version, BLE connection data
• Usage data: App interactions, appointment history, linked accounts

3. HOW WE USE YOUR DATA
• To provide personalised health monitoring and insights
• To connect you with healthcare specialists for appointments
• To sync ring data to our secure cloud servers
• To send health alerts and notifications
• To improve app performance and features

4. DATA SHARING
We do not sell your personal data. We may share data with:
• Licensed healthcare providers for appointment purposes
• Cloud infrastructure providers (under strict confidentiality agreements)
• Legal authorities if required by law

5. DATA SECURITY
All data is encrypted in transit (TLS 1.2+) and at rest. We follow industry-standard security practices to protect your health information.

6. YOUR RIGHTS
• Access or export your health data at any time
• Request deletion of your account and data
• Opt out of non-essential notifications
• Contact us at support@mannaheal.com for any data requests

7. RETENTION
Health data is retained for up to 5 years to support your health history. Account data is deleted within 30 days of account deletion request.

8. CHILDREN'S PRIVACY
This app is not intended for users under 13 years of age.

9. CHANGES TO THIS POLICY
We will notify you of any material changes via in-app notification or email.

10. CONTACT
MannaHeal Pvt. Ltd.
Email: support@mannaheal.com
Phone: +91 98765 43210
"""
    }
}

// MARK: - UITextViewDelegate (placeholder)
extension HelpSupportViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == textTertiary {
            textView.text = ""
            textView.textColor = textPrimary
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Describe the issue in detail..."
            textView.textColor = textTertiary
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension HelpSupportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let img = info[.originalImage] as? UIImage {
            selectedImages.append(img)
            refreshThumbnails()
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIGestureRecognizer action helper
private extension UIGestureRecognizer {
    func addTarget(block: @escaping () -> Void) {
        let wrapper = GestureWrapper(block: block)
        objc_setAssociatedObject(self, &GestureWrapper.key, wrapper, .OBJC_ASSOCIATION_RETAIN)
        addTarget(wrapper, action: #selector(GestureWrapper.invoke))
    }
}

private class GestureWrapper: NSObject {
    static var key = "GestureWrapper"
    private let block: () -> Void
    init(block: @escaping () -> Void) { self.block = block }
    @objc func invoke() { block() }
}

// MARK: - Category Picker Sheet
private class CategoryPickerSheet: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct CatItem { let title: String; let isHeader: Bool; let isHint: Bool }

    private let items: [CatItem]
    private let onSelect: (String) -> Void
    private let tableView = UITableView()
    private let primaryBlue = UIColor(red: 13/255, green: 153/255, blue: 255/255, alpha: 1)

    init(items: [HelpSupportViewController.CatItem], onSelect: @escaping (String) -> Void) {
        self.items = items.map { CatItem(title: $0.title, isHeader: $0.isHeader, isHint: $0.isHint) }
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Select Category"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // skip hint (index 0)
        return items.dropFirst().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row + 1]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if item.isHeader {
            cell.textLabel?.text = item.title
            cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            cell.textLabel?.textColor = .systemGray
            cell.indentationLevel = 0
        } else {
            cell.textLabel?.text = item.title
            cell.textLabel?.font = .systemFont(ofSize: 14)
            cell.textLabel?.textColor = .label
            cell.indentationLevel = 2
        }
        cell.isUserInteractionEnabled = !item.isHeader
        cell.selectionStyle = item.isHeader ? .none : .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row + 1]
        guard !item.isHeader else { return }
        onSelect(item.title)
        dismiss(animated: true)
    }
}


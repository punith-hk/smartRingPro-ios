import UIKit

// MARK: - HealthDashboardV2ViewController

final class HealthDashboardV2ViewController: AppBaseViewController {

    // MARK: - Repositories
    private let heartRateRepo    = HeartRateRepository()
    private let hrvRepo          = HrvRepository()
    private let bpRepo           = BloodPressureRepository()
    private let bloodOxygenRepo  = BloodOxygenRepository()
    private let bloodGlucoseRepo = BloodGlucoseRepository()
    private let temperatureRepo  = TemperatureRepository()
    private let stepsRepo        = StepsRepository()
    private let sleepRepo        = SleepRepository()
    private let ecgRepo          = ECGRecordRepository()

    // MARK: - Scroll
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    // MARK: - Header
    private let headerView  = UIView()
    private let ellipseView = UIView()   // large light-blue oval, top-clipped
    private let topHalfView = UIView()      // light blue top partition with convex bottom
    private let gaugeView   = HealthScoreGaugeView()

    // MARK: - Sync Banner
    private let syncBanner = LastSyncedBannerView()

    // MARK: - Section Containers
    private let cardioSection   = DashboardSectionView(
        title: "Cardiovascular Vitality",
        sectionColor: UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1))
    private let metabolicSection = DashboardSectionView(
        title: "Metabolic & Body",
        sectionColor: UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1))
    private let sleepSection    = DashboardSectionView(
        title: "Sleep & Stress",
        sectionColor: UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1))
    private let insightsSection = DashboardSectionView(
        title: "Insights & Alerts",
        sectionColor: UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1))

    // MARK: - Card References — Cardiovascular
    private var heartRateCard:   DashboardVitalCardV2!
    private var hrvCard:         DashboardVitalCardV2!
    private var ecgCard:         DashboardVitalCardV2!
    private var ecgDetailsCard:  DashboardVitalCardV2!
    private var bloodPressCard:  DashboardVitalCardV2!
    private var bloodOxyCard:    DashboardVitalCardV2!

    // MARK: - Card References — Metabolic
    private var caloriesCard:    DashboardVitalCardV2!
    private var stepsCard:       DashboardVitalCardV2!
    private var bmiCard:         DashboardVitalCardV2!
    private var glucoseCard:     DashboardVitalCardV2!
    private var bodyTempCard:    DashboardVitalCardV2!

    // MARK: - Card References — Sleep
    private var sleepDurationCard: DashboardVitalCardV2!
    private var sleepQualityCard:  DashboardVitalCardV2!
    private var stressCard:        DashboardVitalCardV2!

    // MARK: - Cached Cardio Vitals (used when navigating to CardiovascularStatusViewController)
    private var cachedHR: Int = 0
    private var cachedHRStatus: String = "--"
    private var cachedPrevHR: Int = 0
    private var cachedHRV: Int = 0
    private var cachedHRVStatus: String = "--"
    private var cachedPrevHRV: Int = 0
    private var cachedSBP: Int = 0
    private var cachedDBP: Int = 0
    private var cachedBPStatus: String = "--"
    private var cachedPrevSBP: Int = 0
    private var cachedPrevDBP: Int = 0
    private var cachedSPO2: Int = 0
    private var cachedSPO2Status: String = "--"
    private var cachedPrevSPO2: Int = 0
    private var cachedECGScore: Int = 0
    private var cachedECGStatus: String = "--"
    private var cachedPrevECGScore: Int = 0
    private var cachedLastSyncMillis: Int64 = 0

    // MARK: - Alert Card
    private let alertCard = UIView()
    private let alertIconContainer = UIView()
    private let alertIconView      = UIImageView()
    private let alertTitleLabel    = UILabel()
    private let alertBodyLabel     = UILabel()
    private let alertTimeLabel     = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Health")
        showHamburger()
        view.backgroundColor = .white

        setupScrollView()
        setupHeader()
        buildCardioSection()
        buildMetabolicSection()
        buildSleepSection()
        buildInsightsSection()
        layoutStackInContentView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLocalData()
        if let date = lastSyncDate() {
            syncBanner.markSynced(date: date)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyEllipseClipToHeader()
        applyConvexBottomMask()
    }

    private func applyConvexBottomMask() {
        let b = topHalfView.bounds
        guard b.width > 0, b.height > 0 else { return }
        // Sides stop 40pt above bottom; center bows all the way down → visible convex curve
        let curve: CGFloat = 40
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: b.width, y: 0))
        path.addLine(to: CGPoint(x: b.width, y: b.height - curve))
        path.addQuadCurve(to: CGPoint(x: 0, y: b.height - curve),
                          controlPoint: CGPoint(x: b.width / 2, y: b.height))
        path.close()
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        topHalfView.layer.mask = mask
    }

    // MARK: - ScrollView Setup

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
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

    // MARK: - Header

    private func setupHeader() {
        headerView.backgroundColor = .white
        headerView.layer.cornerRadius = 32
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.clipsToBounds = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)

        // Top-half light blue partition with convex bottom (curve applied in viewDidLayoutSubviews)
        topHalfView.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        topHalfView.translatesAutoresizingMaskIntoConstraints = false
        headerView.insertSubview(topHalfView, at: 0)
        NSLayoutConstraint.activate([
            topHalfView.topAnchor.constraint(equalTo: headerView.topAnchor),
            topHalfView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            topHalfView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            topHalfView.heightAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 0.66),
        ])

        syncBanner.backgroundColor = .clear
        syncBanner.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(syncBanner)
        syncBanner.onSyncTapped = { [weak self] in
            self?.syncBanner.setSyncing(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.syncBanner.setSyncing(false)
                self?.syncBanner.markSynced(date: Date())
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_sync_timestamp")
            }
        }

        gaugeView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(gaugeView)

        // White circle to block light-blue from showing inside/around the gauge arc
        let gaugeInnerMask = UIView()
        gaugeInnerMask.backgroundColor = .white
        gaugeInnerMask.layer.cornerRadius = 125
        gaugeInnerMask.translatesAutoresizingMaskIntoConstraints = false
        headerView.insertSubview(gaugeInnerMask, belowSubview: gaugeView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 270),

            syncBanner.topAnchor.constraint(equalTo: headerView.topAnchor),
            syncBanner.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            syncBanner.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            syncBanner.heightAnchor.constraint(equalToConstant: 28),

            gaugeView.topAnchor.constraint(equalTo: syncBanner.bottomAnchor, constant: 18),
            gaugeView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            gaugeView.widthAnchor.constraint(equalToConstant: 270),
            gaugeView.heightAnchor.constraint(equalToConstant: 250),

            // Position white circle: arc center at gaugeView.top+123, radius=133 (outer arc=121 + 12pt padding)
            gaugeInnerMask.widthAnchor.constraint(equalToConstant: 250),
            gaugeInnerMask.heightAnchor.constraint(equalToConstant: 250),
            gaugeInnerMask.centerXAnchor.constraint(equalTo: gaugeView.centerXAnchor),
            gaugeInnerMask.topAnchor.constraint(equalTo: gaugeView.topAnchor, constant: -2),
        ])
    }

    private func applyEllipseClipToHeader() { /* no-op */ }



    // MARK: - Build Sections

    // ---- Cardiovascular ----
    private func buildCardioSection() {
        // Row 1
        heartRateCard = makeCard(
            icon: UIImage(systemName: "heart.fill"),
            iconTint: UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1),
            iconBg: UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1),
            title: "Heart Rate", value: "--", unit: "BPM")
        heartRateCard.onTap = { [weak self] in
            guard let self = self else { return }
            let vc = CardiovascularStatusViewController()
            vc.vitalType = .heartRate
            self.populateCardioVC(vc)
            self.push(vc)
        }

        hrvCard = makeCard(
            icon: UIImage(systemName: "waveform"),
            iconTint: UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1),
            iconBg: UIColor(red: 0.95, green: 0.88, blue: 1, alpha: 1),
            title: "HRV", value: "--", unit: "ms")
        hrvCard.onTap = { [weak self] in
            guard let self = self else { return }
            let vc = CardiovascularStatusViewController()
            vc.vitalType = .hrv
            self.populateCardioVC(vc)
            self.push(vc)
        }

        ecgCard = makeCard(
            icon: UIImage(systemName: "waveform.path.ecg"),
            iconTint: UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 0.89, blue: 1, alpha: 1),
            title: "ECG", value: "--", unit: "tores")
        ecgCard.onTap = { [weak self] in
            guard let self = self else { return }
            let vc = CardiovascularStatusViewController()
            vc.vitalType = .ecg
            self.populateCardioVC(vc)
            self.push(vc)
        }

        // Row 2
        ecgDetailsCard = makeCard(
            icon: UIImage(systemName: "waveform.path.ecg.rectangle"),
            iconTint: UIColor(red: 1, green: 0.70, blue: 0, alpha: 1),
            iconBg: UIColor(red: 1, green: 0.96, blue: 0.88, alpha: 1),
            title: "ECG Details", value: "--", unit: "")
        ecgDetailsCard.setValueFontSize(14)
        ecgDetailsCard.onTap = { [weak self] in
            guard let self = self else { return }
            let vc = CardiovascularStatusViewController()
            vc.vitalType = .ecg
            self.populateCardioVC(vc)
            self.push(vc)
        }

        bloodPressCard = makeCard(
            icon: UIImage(systemName: "drop.fill"),
            iconTint: UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 1, blue: 0.91, alpha: 1),
            title: "Blood Pressure", value: "--/--", unit: "mmHg")
        bloodPressCard.setUnitBelow()
        bloodPressCard.onTap = { [weak self] in
            guard let self = self else { return }
            let vc = CardiovascularStatusViewController()
            vc.vitalType = .bloodPressure
            self.populateCardioVC(vc)
            self.push(vc)
        }

        bloodOxyCard = makeCard(
            icon: UIImage(systemName: "lungs.fill"),
            iconTint: UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1),
            iconBg: UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1),
            title: "Blood Oxygen", value: "--", unit: "%")
        bloodOxyCard.onTap = { [weak self] in
            guard let self = self else { return }
            let vc = CardiovascularStatusViewController()
            vc.vitalType = .bloodOxygen
            self.populateCardioVC(vc)
            self.push(vc)
        }

        cardioSection.translatesAutoresizingMaskIntoConstraints = false
        cardioSection.addRow(cards: [heartRateCard, hrvCard, ecgCard])
        cardioSection.addRow(cards: [ecgDetailsCard, bloodPressCard, bloodOxyCard])
    }

    // ---- Metabolic ----
    private func buildMetabolicSection() {
        // Row 1
        caloriesCard = makeCard(
            icon: UIImage(systemName: "flame.fill"),
            iconTint: UIColor(red: 0.94, green: 0.33, blue: 0.31, alpha: 1),
            iconBg: UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1),
            title: "Calories", value: "--", unit: "kcal")
        caloriesCard.onTap = { [weak self] in
            self?.push(CaloriesViewController())
        }

        stepsCard = makeCard(
            icon: UIImage(systemName: "figure.walk"),
            iconTint: UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 0.89, blue: 1, alpha: 1),
            title: "Steps", value: "--", unit: "")
        stepsCard.onTap = { [weak self] in
            // Steps VC placeholder
            self?.showPlaceholder(title: "Steps")
        }

        bmiCard = makeCard(
            icon: UIImage(systemName: "scalemass.fill"),
            iconTint: UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 1, blue: 0.91, alpha: 1),
            title: "BMI", value: "--", unit: "kg/m²")
        bmiCard.onTap = { [weak self] in
            self?.showPlaceholder(title: "BMI")
        }

        // Row 2
        glucoseCard = makeCard(
            icon: UIImage(systemName: "drop.fill"),
            iconTint: UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1),
            iconBg: UIColor(red: 1, green: 0.94, blue: 0.88, alpha: 1),
            title: "Blood Glucose", value: "--", unit: "mg/dL")
        glucoseCard.onTap = { [weak self] in
            self?.push(HealthVitalsViewController(vitalType: .bloodGlucose))
        }

        bodyTempCard = makeCard(
            icon: UIImage(systemName: "thermometer"),
            iconTint: UIColor(red: 1, green: 0.60, blue: 0, alpha: 1),
            iconBg: UIColor(red: 1, green: 0.94, blue: 0.88, alpha: 1),
            title: "Body Temp", value: "--", unit: "°C")
        bodyTempCard.onTap = { [weak self] in
            self?.push(HealthVitalsViewController(vitalType: .temperature))
        }

        metabolicSection.translatesAutoresizingMaskIntoConstraints = false
        metabolicSection.setBorder(color: UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1))
        metabolicSection.addRow(cards: [caloriesCard, stepsCard, bmiCard])
        // Third slot in row 2 is empty (spacer auto-added by DashboardSectionView)
        metabolicSection.addRow(cards: [glucoseCard, bodyTempCard])
    }

    // ---- Sleep & Stress ----
    private func buildSleepSection() {
        sleepDurationCard = makeCard(
            icon: UIImage(systemName: "moon.fill"),
            iconTint: UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 0.89, blue: 1, alpha: 1),
            title: "Sleep Duration", value: "--", unit: "")
        sleepDurationCard.onTap = { [weak self] in
            self?.push(SleepViewController())
        }

        sleepQualityCard = makeCard(
            icon: UIImage(systemName: "moon.stars.fill"),
            iconTint: UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 0.89, blue: 1, alpha: 1),
            title: "Sleep Quality", value: "--", unit: "%")
        sleepQualityCard.onTap = { [weak self] in
            self?.push(SleepViewController())
        }

        stressCard = makeCard(
            icon: UIImage(systemName: "brain.head.profile"),
            iconTint: UIColor(white: 0.6, alpha: 1),
            iconBg: UIColor(white: 0.94, alpha: 1),
            title: "Stress", value: "Coming\nSoon", unit: "")
        stressCard.setValueFontSize(14)
        stressCard.updateStatus(text: "Feature coming soon", color: UIColor(white: 0.6, alpha: 1))

        sleepSection.translatesAutoresizingMaskIntoConstraints = false
        sleepSection.addRow(cards: [sleepDurationCard, sleepQualityCard, stressCard])
    }

    // ---- Insights & Alerts ----
    private func buildInsightsSection() {
        insightsSection.translatesAutoresizingMaskIntoConstraints = false
        insightsSection.setBorder(color: UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1))
        insightsSection.layer.masksToBounds = false
        insightsSection.clipsToBounds = false

        let alerts: [(icon: String, iconTint: UIColor, iconBg: UIColor, title: String, body: String, date: String)] = [
            (
                icon: "bell.fill",
                iconTint: UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1),
                iconBg:   UIColor(red: 1,    green: 0.95, blue: 0.88, alpha: 1),
                title: "Health Alert",
                body:  "Low blood oxygen and heart rate detected. Monitor closely and seek medical attention if symptoms worsen.",
                date:  "May 09"
            ),
            (
                icon: "moon.fill",
                iconTint: UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1),
                iconBg:   UIColor(red: 1,    green: 0.88, blue: 0.92, alpha: 1),
                title: "Sleep Needs Improvement",
                body:  "You had 6h 10m of sleep. Aim for better rest tonight!",
                date:  "Last night"
            ),
            (
                icon: "figure.walk",
                iconTint: UIColor(red: 0.40, green: 0.23, blue: 0.72, alpha: 1),
                iconBg:   UIColor(red: 0.93, green: 0.90, blue: 0.98, alpha: 1),
                title: "Keep Moving!",
                body:  "You've taken 1591 steps and burned 62 kcal. You're 15% to your goal!",
                date:  "Today"
            )
        ]

        for alert in alerts {
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 12
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.08
            card.layer.shadowRadius = 6
            card.layer.shadowOffset = CGSize(width: 0, height: 2)
            card.layer.masksToBounds = false
            card.translatesAutoresizingMaskIntoConstraints = false

            let row = makeAlertRow(
                icon: UIImage(systemName: alert.icon),
                iconTint: alert.iconTint,
                iconBg: alert.iconBg,
                title: alert.title,
                body: alert.body,
                date: alert.date
            )
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: card.topAnchor),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            ])

            insightsSection.addContent(card)
        }
    }

    private func makeAlertRow(icon: UIImage?, iconTint: UIColor, iconBg: UIColor,
                              title: String, body: String, date: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isUserInteractionEnabled = true

        let iconBgView = UIView()
        iconBgView.backgroundColor = iconBg
        iconBgView.layer.cornerRadius = 24
        iconBgView.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = iconTint
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBgView.addSubview(iconView)

        let titleLbl = UILabel()
        titleLbl.font = .systemFont(ofSize: 14, weight: .bold)
        titleLbl.textColor = .black
        titleLbl.text = title
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let bodyLbl = UILabel()
        bodyLbl.font = .systemFont(ofSize: 12)
        bodyLbl.textColor = UIColor(white: 0.45, alpha: 1)
        bodyLbl.text = body
        bodyLbl.numberOfLines = 2
        bodyLbl.translatesAutoresizingMaskIntoConstraints = false

        let dateLbl = UILabel()
        dateLbl.font = .systemFont(ofSize: 11)
        dateLbl.textColor = UIColor(white: 0.60, alpha: 1)
        dateLbl.text = date
        dateLbl.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView()
        chevron.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        chevron.tintColor = UIColor(white: 0.65, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        [iconBgView, titleLbl, bodyLbl, dateLbl, chevron].forEach { row.addSubview($0) }

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconBgView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            iconBgView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            iconBgView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconBgView.widthAnchor.constraint(equalToConstant: 48),
            iconBgView.heightAnchor.constraint(equalToConstant: 48),

            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 9),
            chevron.heightAnchor.constraint(equalToConstant: 15),

            titleLbl.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
            titleLbl.leadingAnchor.constraint(equalTo: iconBgView.trailingAnchor, constant: 12),
            titleLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            bodyLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 4),
            bodyLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
            bodyLbl.trailingAnchor.constraint(equalTo: titleLbl.trailingAnchor),

            dateLbl.topAnchor.constraint(equalTo: bodyLbl.bottomAnchor, constant: 4),
            dateLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
            dateLbl.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -14),
        ])

        return row
    }

    // MARK: - Stack Layout in ContentView

    private func layoutStackInContentView() {
        [cardioSection, metabolicSection, sleepSection, insightsSection].forEach {
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardioSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            cardioSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardioSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            metabolicSection.topAnchor.constraint(equalTo: cardioSection.bottomAnchor, constant: 12),
            metabolicSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            metabolicSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            sleepSection.topAnchor.constraint(equalTo: metabolicSection.bottomAnchor, constant: 12),
            sleepSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sleepSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            insightsSection.topAnchor.constraint(equalTo: sleepSection.bottomAnchor, constant: 12),
            insightsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            insightsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            insightsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -80),
        ])
    }

    // MARK: - Data Loading

    private func loadLocalData() {
        // Synchronous reads
        let hr        = Int(heartRateRepo.getLatestEntry()?.bpm           ?? 0)
        let hrv       = Int(hrvRepo.getLatestEntry()?.hrvValue            ?? 0)
        let latestBP  = bpRepo.getLatestEntry()
        let sbp       = Int(latestBP?.systolicValue                       ?? 0)
        let dbp       = Int(latestBP?.diastolicValue                      ?? 0)
        let spo2      = Int(bloodOxygenRepo.getLatestEntry()?.oxygenValue ?? 0)

        // Previous values for trend arrows
        let allHR   = heartRateRepo.getAll()
        let allHRV  = hrvRepo.getAll()
        let allBP   = bpRepo.getAll()
        let allSPO2 = bloodOxygenRepo.getAll()
        cachedPrevHR  = allHR.count  > 1 ? Int(allHR[1].bpm)           : 0
        cachedPrevHRV = allHRV.count > 1 ? Int(allHRV[1].hrvValue)     : 0
        cachedPrevSBP = allBP.count  > 1 ? Int(allBP[1].systolicValue)  : 0
        cachedPrevDBP = allBP.count  > 1 ? Int(allBP[1].diastolicValue) : 0
        cachedPrevSPO2 = allSPO2.count > 1 ? Int(allSPO2[1].oxygenValue) : 0

        // Cache last sync millis
        if let lastSync = allHR.first { cachedLastSyncMillis = Int64(lastSync.timestamp * 1000) }
        let latestStp = stepsRepo.getLatestEntry()
        let steps     = Int(latestStp?.steps                              ?? 0)
        let calories  = Int(latestStp?.calories                           ?? 0)
        let glucose   = bloodGlucoseRepo.getLatestEntry()?.glucoseValue   ?? 0
        let temp      = temperatureRepo.getLatestEntry()?.temperatureValue ?? 0
        let sleepMin  = UserDefaults.standard.integer(forKey: "last_day_sleep_minutes")
        let sleepQual = computeSleepQuality()
        let bmiVal    = computeBMI()

        // Apply non-ECG cards
        applyHeartRate(hr)
        applyHRV(hrv)
        applyBloodPressure(sbp: sbp, dbp: dbp)
        applyBloodOxygen(spo2)
        applyCalories(calories)
        applySteps(steps)
        applyBMI(bmiVal)
        applyGlucose(glucose)
        applyTemperature(temp)
        applySleep(minutes: sleepMin, quality: sleepQual)
        applyLatestNotification()

        // Health score with ecgScore = 0 as placeholder
        applyHealthScore(hr: hr, hrv: hrv, sbp: sbp, dbp: dbp,
                         spo2: spo2, calories: calories, ecgScore: 0)

        // Async ECG — updates ECG cards + recalculates score
        ecgRepo.fetchAllRecords { [weak self] records in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let latest = records.first else { return }
                let score  = HealthScoreCalculator.ecgScore(from: latest)
                let status = HealthScoreCalculator.ecgStatusText(
                    isAfib: latest.isAfib,
                    diagnoseType: latest.diagnoseType,
                    heartRate: latest.heartRate,
                    hrv: latest.hrv)
                // Cache previous ECG score (second record)
                if records.count > 1 {
                    self.cachedPrevECGScore = HealthScoreCalculator.ecgScore(from: records[1])
                }
                self.applyECGData(score: score, statusText: status)
                self.applyHealthScore(hr: hr, hrv: hrv, sbp: sbp, dbp: dbp,
                                      spo2: spo2, calories: calories, ecgScore: score)
            }
        }
    }

    // MARK: - Apply Vital Data

    private func applyHealthScore(hr: Int, hrv: Int, sbp: Int, dbp: Int,
                                  spo2: Int, calories: Int, ecgScore: Int) {
        let result = HealthScoreCalculator.calculate(
            heartRate: hr, hrv: hrv, systolic: sbp, diastolic: dbp,
            spo2: spo2, ecgScore: ecgScore, calories: calories)
        gaugeView.score          = result.score
        gaugeView.yesterdayScore = result.yesterdayScore
    }

    private func applyHeartRate(_ hr: Int) {
        cachedHR = hr
        cachedHRStatus = hrStatus(hr).0
        let text = hr > 0 ? "\(hr)" : "--"
        heartRateCard.updateValue(text, unit: "BPM")
        let (status, color) = hrStatus(hr)
        heartRateCard.updateStatus(text: status, color: color)
    }

    private func applyHRV(_ hrv: Int) {
        cachedHRV = hrv
        cachedHRVStatus = hrvStatus(hrv).0
        let text = hrv > 0 ? "\(hrv)" : "--"
        hrvCard.updateValue(text, unit: "ms")
        let (status, color) = hrvStatus(hrv)
        hrvCard.updateStatus(text: status, color: color)
    }

    private func applyBloodPressure(sbp: Int, dbp: Int) {
        cachedSBP = sbp
        cachedDBP = dbp
        cachedBPStatus = bpStatus(sbp: sbp, dbp: dbp).0
        let text = (sbp > 0 && dbp > 0) ? "\(sbp)/\(dbp)" : "--/--"
        bloodPressCard.updateValue(text, unit: "mmHg")
        let (status, color) = bpStatus(sbp: sbp, dbp: dbp)
        bloodPressCard.updateStatus(text: status, color: color)
    }

    private func applyBloodOxygen(_ spo2: Int) {
        cachedSPO2 = spo2
        cachedSPO2Status = spo2Status(spo2).0
        let text = spo2 > 0 ? "\(spo2)" : "--"
        bloodOxyCard.updateValue(text, unit: "%")
        let (status, color) = spo2Status(spo2)
        bloodOxyCard.updateStatus(text: status, color: color)
    }

    private func applyECGData(score: Int, statusText: String) {
        cachedECGScore = score
        cachedECGStatus = statusText
        ecgCard.updateValue(score > 0 ? "\(score)" : "--", unit: "tores")
        let (ecgCardStatus, ecgColor) = ecgCardStatus(score)
        ecgCard.updateStatus(text: ecgCardStatus, color: ecgColor)

        ecgDetailsCard.updateValue(statusText, unit: "")
        let (detailStatus, detailColor) = ecgDetailsStatus(statusText)
        ecgDetailsCard.updateStatus(text: detailStatus, color: detailColor)
    }

    private func applyCalories(_ cal: Int) {
        let text = cal > 0 ? formattedNumber(cal) : "--"
        caloriesCard.updateValue(text, unit: "kcal")
        let (status, color) = caloriesStatus(cal)
        caloriesCard.updateStatus(text: status, color: color)
    }

    private func applySteps(_ steps: Int) {
        let text = steps > 0 ? formattedNumber(steps) : "--"
        stepsCard.updateValue(text, unit: "")
        let (status, color) = stepsStatus(steps)
        stepsCard.updateStatus(text: status, color: color)
    }

    private func applyBMI(_ bmi: Double) {
        let text = bmi > 0 ? String(format: "%.1f", bmi) : "--"
        bmiCard.updateValue(text, unit: "kg/m²")
        let (status, color) = bmiStatus(bmi)
        bmiCard.updateStatus(text: status, color: color)
    }

    private func applyGlucose(_ glucose: Double) {
        let text = glucose > 0 ? String(format: "%.0f", glucose) : "--"
        glucoseCard.updateValue(text, unit: "mg/dL")
        let (status, color) = glucoseStatus(Int(glucose))
        glucoseCard.updateStatus(text: status, color: color)
    }

    private func applyTemperature(_ temp: Double) {
        let text = temp > 0 ? String(format: "%.1f", temp) : "--"
        bodyTempCard.updateValue(text, unit: "°C")
        let (status, color) = tempStatus(temp)
        bodyTempCard.updateStatus(text: status, color: color)
    }

    private func applySleep(minutes: Int, quality: Int) {
        if minutes > 0 {
            let h = minutes / 60
            let m = minutes % 60
            sleepDurationCard.updateValue("\(h)h \(m)m", unit: "")
        } else {
            sleepDurationCard.updateValue("--", unit: "")
        }
        let (durStatus, durColor) = sleepDurationStatus(minutes)
        sleepDurationCard.updateStatus(text: durStatus, color: durColor)

        sleepQualityCard.updateValue(quality > 0 ? "\(quality)" : "--", unit: "%")
        let (qualStatus, qualColor) = sleepQualityStatus(quality)
        sleepQualityCard.updateStatus(text: qualStatus, color: qualColor)
    }

    private func applyLatestNotification() {
        let defaults = UserDefaults.standard
        let title    = defaults.string(forKey: "notif_latest_title") ?? "No alerts"
        let body     = defaults.string(forKey: "notif_latest_body")  ?? "You have no new health alerts"
        let time     = defaults.double(forKey: "notif_latest_time")
        let vitalKey = defaults.string(forKey: "notif_latest_vital") ?? ""

        alertTitleLabel.text = title
        alertBodyLabel.text  = body
        alertTimeLabel.text  = time > 0 ? relativeTime(from: Date(timeIntervalSince1970: time)) : ""

        let (icon, tint, bg) = notifIconInfo(for: vitalKey)
        alertIconView.image           = icon?.withRenderingMode(.alwaysTemplate)
        alertIconView.tintColor       = tint
        alertIconContainer.backgroundColor = bg
    }

    // MARK: - Helpers — Status Logic

    private func hrStatus(_ hr: Int) -> (String, UIColor) {
        let green  = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard hr > 0 else { return ("No data", UIColor.gray) }
        if hr >= 60 && hr <= 100 { return ("Optimal",  green) }
        if hr >= 50 && hr <= 110 { return ("Good",     orange) }
        return ("Alert", red)
    }

    private func hrvStatus(_ hrv: Int) -> (String, UIColor) {
        let green  = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard hrv > 0 else { return ("No data", UIColor.gray) }
        if hrv >= 50 { return ("Good", green) }
        if hrv >= 30 { return ("Fair", orange) }
        return ("Low", red)
    }

    private func bpStatus(sbp: Int, dbp: Int) -> (String, UIColor) {
        let green  = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard sbp > 0 else { return ("No data", UIColor.gray) }
        if sbp >= 90 && sbp <= 120 && dbp >= 60 && dbp <= 80 { return ("Normal",   green) }
        if (sbp >= 121 && sbp <= 139) || (dbp >= 81 && dbp <= 89) { return ("Elevated", orange) }
        return ("High", red)
    }

    private func spo2Status(_ spo2: Int) -> (String, UIColor) {
        let green  = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard spo2 > 0 else { return ("No data", UIColor.gray) }
        if spo2 >= 95 { return ("Excellent", green) }
        if spo2 >= 90 { return ("Good",      orange) }
        return ("Low", red)
    }

    private func ecgCardStatus(_ score: Int) -> (String, UIColor) {
        let indigo = UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard score > 0 else { return ("No data", UIColor.gray) }
        if score >= 15 { return ("Improving", indigo) }
        if score >= 10 { return ("Fair",      orange) }
        return ("Low", red)
    }

    private func ecgDetailsStatus(_ text: String) -> (String, UIColor) {
        let amber  = UIColor(red: 1, green: 0.70, blue: 0, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        switch text {
        case "Normal ECG", "Normal Sinus", "Normal": return ("Healthy", amber)
        case "Atrial Fibrillation", "--":             return (text == "--" ? "No data" : "Alert", red)
        default:                                       return ("Review",  orange)
        }
    }

    private func caloriesStatus(_ cal: Int) -> (String, UIColor) {
        let red    = UIColor(red: 0.94, green: 0.33, blue: 0.31, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let amber  = UIColor(red: 1, green: 0.70, blue: 0, alpha: 1)
        guard cal > 0 else { return ("No data", UIColor.gray) }
        if cal >= 2000 { return ("Active",   red) }
        if cal >= 1500 { return ("Moderate", orange) }
        return ("Light", amber)
    }

    private func stepsStatus(_ steps: Int) -> (String, UIColor) {
        let green  = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)
        let lgreen = UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let indigo = UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1)
        let grey   = UIColor(white: 0.6, alpha: 1)
        let target = 10_000
        guard steps > 0 else { return ("No data", grey) }
        if steps >= target           { return ("Target Met",  green) }
        if steps >= target * 3 / 4  { return ("Almost There", lgreen) }
        if steps >= target / 2      { return ("Halfway",      orange) }
        if steps >= target / 5      { return ("Keep Going",   indigo) }
        return ("Just Started", grey)
    }

    private func bmiStatus(_ bmi: Double) -> (String, UIColor) {
        let lgreen = UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let amber  = UIColor(red: 1, green: 0.70, blue: 0, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard bmi > 0 else { return ("No data", UIColor.gray) }
        if bmi >= 18.5 && bmi < 25 { return ("Healthy",    lgreen) }
        if bmi >= 25   && bmi < 30 { return ("Overweight", orange) }
        if bmi < 18.5              { return ("Underweight", amber) }
        return ("Obese", red)
    }

    private func glucoseStatus(_ mg: Int) -> (String, UIColor) {
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let amber  = UIColor(red: 1, green: 0.70, blue: 0, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard mg > 0 else { return ("No data", UIColor.gray) }
        if mg >= 70  && mg <= 99  { return ("Normal",   orange) }
        if mg >= 100 && mg <= 125 { return ("Elevated", amber) }
        return ("High", red)
    }

    private func tempStatus(_ temp: Double) -> (String, UIColor) {
        let orange = UIColor(red: 1, green: 0.60, blue: 0, alpha: 1)
        let amber  = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        let indigo = UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1)
        guard temp > 0 else { return ("No data", UIColor.gray) }
        if temp >= 36.1 && temp <= 37.2 { return ("Normal",   orange) }
        if temp >= 37.3 && temp <= 38.0 { return ("Elevated", amber) }
        if temp > 38.0                  { return ("Fever",    red) }
        return ("Low", indigo)
    }

    private func sleepDurationStatus(_ minutes: Int) -> (String, UIColor) {
        let indigo = UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1)
        let lgreen = UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let amber  = UIColor(red: 1, green: 0.70, blue: 0, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        let target = 480 // 8 h
        guard minutes > 0 else { return ("No data", UIColor.gray) }
        if minutes >= target               { return ("Target Met",  indigo) }
        if minutes >= target * 7 / 8      { return ("Almost There", lgreen) }
        if minutes >= target * 3 / 4      { return ("Good",         orange) }
        if minutes >= target / 2          { return ("Halfway",      amber) }
        return ("Low", red)
    }

    private func sleepQualityStatus(_ quality: Int) -> (String, UIColor) {
        let lgreen = UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        let green  = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)
        let orange = UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1)
        guard quality > 0 else { return ("No data", UIColor.gray) }
        if quality >= 90 { return ("Excellent", lgreen) }
        if quality >= 80 { return ("Good",      green) }
        if quality >= 70 { return ("Fair",      orange) }
        return ("Poor", red)
    }

    // MARK: - Helpers — Computation

    private func computeSleepQuality() -> Int {
        let sessions = sleepRepo.getAllSessions()
        guard !sessions.isEmpty else { return 0 }

        // Use sessions from the last 36h (covers previous night's sleep)
        let cutoff = Int64(Date().timeIntervalSince1970) - 36 * 3600
        let recent = sessions.filter { $0.endTime >= cutoff }
        guard !recent.isEmpty else {
            // fallback to most recent session
            if let last = sessions.first {
                let total = last.deepSleepTimes + last.lightSleepTimes + last.remSleepTimes
                let raw   = min(100, max(12, Int(Double(total) / 480.0 * 100)))
                return raw
            }
            return 0
        }

        let scores = recent.map { session -> Int in
            let total = session.deepSleepTimes + session.lightSleepTimes + session.remSleepTimes
            return min(100, max(12, Int(Double(total) / 480.0 * 100)))
        }
        return scores.reduce(0, +) / scores.count
    }

    private func computeBMI() -> Double {
        let heightCm = UserDefaults.standard.double(forKey: "user_height")
        let weightKg = UserDefaults.standard.double(forKey: "user_weight")
        guard heightCm > 0, weightKg > 0 else { return 0 }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    private func lastSyncDate() -> Date? {
        let ts = UserDefaults.standard.double(forKey: "last_sync_timestamp")
        guard ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    private func formattedNumber(_ n: Int) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func relativeTime(from date: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(date))
        if elapsed < 60       { return "Just now" }
        if elapsed < 3600     { return "\(elapsed / 60) min ago" }
        if elapsed < 86400    { return "\(elapsed / 3600) hr ago" }
        if elapsed < 172800   { return "Yesterday" }
        if elapsed < 604800   { return "\(elapsed / 86400) days ago" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM dd"
        return fmt.string(from: date)
    }

    private func notifIconInfo(for vitalKey: String) -> (UIImage?, UIColor, UIColor) {
        switch vitalKey {
        case "heart_rate":
            return (UIImage(systemName: "heart.fill"),
                    UIColor(red: 1, green: 0.32, blue: 0.32, alpha: 1),
                    UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1))
        case "hrv":
            return (UIImage(systemName: "waveform"),
                    UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1),
                    UIColor(red: 0.95, green: 0.88, blue: 1, alpha: 1))
        case "blood_pressure":
            return (UIImage(systemName: "drop.fill"),
                    UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),
                    UIColor(red: 0.88, green: 1, blue: 0.91, alpha: 1))
        case "blood_oxygen":
            return (UIImage(systemName: "lungs.fill"),
                    UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1),
                    UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1))
        case "blood_sugar":
            return (UIImage(systemName: "drop.fill"),
                    UIColor(red: 1, green: 0.65, blue: 0.15, alpha: 1),
                    UIColor(red: 1, green: 0.94, blue: 0.88, alpha: 1))
        case "temperature":
            return (UIImage(systemName: "thermometer"),
                    UIColor(red: 1, green: 0.60, blue: 0, alpha: 1),
                    UIColor(red: 1, green: 0.94, blue: 0.88, alpha: 1))
        case "sleep":
            return (UIImage(systemName: "moon.fill"),
                    UIColor(red: 0.33, green: 0.43, blue: 1, alpha: 1),
                    UIColor(red: 0.88, green: 0.89, blue: 1, alpha: 1))
        default:
            return (UIImage(systemName: "bell.fill"),
                    UIColor(white: 0.5, alpha: 1),
                    UIColor(white: 0.92, alpha: 1))
        }
    }

    // MARK: - Actions

    @objc private func alertCardTapped() {
        showPlaceholder(title: "Notifications")
    }

    private func populateCardioVC(_ vc: CardiovascularStatusViewController) {
        vc.heartRate          = cachedHR
        vc.heartRateStatus    = cachedHRStatus
        vc.previousHeartRate  = cachedPrevHR
        vc.hrv                = cachedHRV
        vc.hrvStatus          = cachedHRVStatus
        vc.previousHrv        = cachedPrevHRV
        vc.bloodPressureSystolic  = cachedSBP
        vc.bloodPressureDiastolic = cachedDBP
        vc.bloodPressureStatus    = cachedBPStatus
        vc.previousSystolic   = cachedPrevSBP
        vc.previousDiastolic  = cachedPrevDBP
        vc.spo2               = cachedSPO2
        vc.spo2Status         = cachedSPO2Status
        vc.previousSpo2       = cachedPrevSPO2
        vc.ecgValue           = cachedECGScore
        vc.ecgStatus          = cachedECGStatus
        vc.previousEcg        = cachedPrevECGScore
        vc.lastSyncMillis     = cachedLastSyncMillis
    }

    private func push(_ vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showPlaceholder(title: String) {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        vc.title = title
        push(vc)
    }

    // MARK: - Card Factory

    private func makeCard(icon: UIImage?, iconTint: UIColor, iconBg: UIColor,
                          title: String, value: String, unit: String) -> DashboardVitalCardV2 {
        let cfg = DashboardVitalCardV2.Config(
            iconImage:   icon,
            iconTint:    iconTint,
            iconBgColor: iconBg,
            title:       title,
            value:       value,
            unit:        unit,
            statusText:  "No data",
            statusColor: UIColor.gray)
        return DashboardVitalCardV2(config: cfg)
    }
}

// MARK: - DashboardSectionView Extension (alert card insertion)

private extension DashboardSectionView {
    /// Inserts an arbitrary arranged subview with inset padding inside the section's stack.
    func addArrangedSubview(_ view: UIView, padding: UIEdgeInsets) {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: padding.top),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: padding.left),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -padding.right),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -padding.bottom)
        ])
        addRow(cards: [wrapper])
    }
}

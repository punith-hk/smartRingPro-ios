import UIKit
import YCProductSDK

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

    // MARK: - Insight Card Live References (Card 1 = Notification, 2 = Sleep, 3 = Steps)
    private var insightCard1     = UIView()
    private var insightIcon1     = UIImageView()
    private var insightIconBg1   = UIView()
    private var insightTitle1    = UILabel()
    private var insightBody1     = UILabel()
    private var insightTime1     = UILabel()

    private var insightCard2     = UIView()
    private var insightIcon2     = UIImageView()
    private var insightIconBg2   = UIView()
    private var insightTitle2    = UILabel()
    private var insightBody2     = UILabel()
    private var insightTime2     = UILabel()

    private var insightCard3     = UIView()
    private var insightIcon3     = UIImageView()
    private var insightIconBg3   = UIView()
    private var insightTitle3    = UILabel()
    private var insightBody3     = UILabel()
    private var insightTime3     = UILabel()

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

        // Path B: BLE connects while dashboard is visible (or on another tab)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBLEStateChanged(_:)),
            name: YCProduct.deviceStateNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLocalData()
        if let date = SyncFreshnessChecker.lastPrimaryDataDate() {
            syncBanner.markSynced(date: date)
        }
        refreshNotificationBadge()
        attemptAutoSync()   // Path A: BLE already connected when dashboard appears
    }

    // MARK: - Notification Badge
    private func refreshNotificationBadge() {
        let uid = UserDefaultsManager.shared.userId
        guard uid > 0 else { return }
        // Use cache if valid, otherwise fetch
        if NotificationCache.shared.isValid {
            updateNotificationBadge(count: NotificationCache.shared.unreadCount)
            return
        }
        NotificationService.shared.getNotifications(userId: uid) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let resp) = result {
                    NotificationCache.shared.update(resp.data)
                    self?.updateNotificationBadge(count: NotificationCache.shared.unreadCount)
                    self?.updateInsightCards()
                }
            }
        }
    }

    // MARK: - Auto Sync

    /// Fires a full BLE sync exactly once per app session when:
    ///   1. It has not already triggered this session
    ///   2. A device is connected
    ///   3. At least one vital is outside its measurement interval (data is stale)
    ///
    /// Called both from viewWillAppear (Path A: BLE already connected) and from
    /// the BLE-connect notification handler (Path B: BLE connects after launch).
    private func attemptAutoSync() {
        guard !AutoSyncSession.hasTriggered else { return }
        guard BLEStateManager.shared.hasConnectedDevice() else { return }
        guard !SyncFreshnessChecker.allVitalsUpToDate() else { return }

        AutoSyncSession.hasTriggered = true
        print("🔄 AutoSync: triggering session sync (data stale, BLE connected)")

        syncBanner.setSyncing(true)
        Loader.shared.show(on: view, message: "Syncing data…")
        BackgroundSyncManager.shared.startFullSync { [weak self] (_: Bool) in
            DispatchQueue.main.async {
                Loader.shared.hide()
                guard let self = self else { return }
                self.syncBanner.setSyncing(false)
                let lastDataDate = SyncFreshnessChecker.lastPrimaryDataDate() ?? Date()
                self.syncBanner.markSynced(date: lastDataDate)
                UserDefaults.standard.set(lastDataDate.timeIntervalSince1970, forKey: "last_sync_timestamp")
                self.loadLocalData()
                print("✅ AutoSync: session sync complete")
            }
        }
    }

    /// Path B handler — BLE connects while the app is running.
    /// Attempts auto-sync only if the dashboard view is currently on screen,
    /// so the Loader attaches to the visible view.
    @objc private func onBLEStateChanged(_ notification: Notification) {
        guard
            let info  = notification.userInfo as? [String: Any],
            let state = info[YCProduct.connecteStateKey] as? YCProductState,
            state == .connected
        else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else { return }
            self.attemptAutoSync()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: YCProduct.deviceStateNotification, object: nil)
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
            guard let self = self else { return }
            guard BLEStateManager.shared.hasConnectedDevice() else {
                Toast.show(message: "No device connected. Please connect your ring first.", in: self.view)
                return
            }
            // Pre-flight: all vitals already within measurement interval?
            if SyncFreshnessChecker.allVitalsUpToDate() {
                let next = SyncFreshnessChecker.nextSyncMessage()
                let msg = next.isEmpty ? "All data is up to date" : "All data is up to date. \(next)"
                Toast.show(message: msg, in: self.view)
                return
            }
            self.syncBanner.setSyncing(true)
            Loader.shared.show(on: self.view, message: "Syncing data…")
            BackgroundSyncManager.shared.startFullSync { [weak self] (_: Bool) in
                Loader.shared.hide()   // always hide — Loader is a singleton
                guard let self = self else { return }
                self.syncBanner.setSyncing(false)
                // Banner uses oldest primary vital timestamp (min of HR/BP/combined)
                let lastDataDate = SyncFreshnessChecker.lastPrimaryDataDate() ?? Date()
                self.syncBanner.markSynced(date: lastDataDate)
                UserDefaults.standard.set(lastDataDate.timeIntervalSince1970, forKey: "last_sync_timestamp")
                self.loadLocalData()
            }
        }

        syncBanner.onDetailTapped = { [weak self] in
            self?.showLastSyncDetailPopup()
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
            self?.push(StepsViewController())
        }

        bmiCard = makeCard(
            icon: UIImage(systemName: "scalemass.fill"),
            iconTint: UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1),
            iconBg: UIColor(red: 0.88, green: 1, blue: 0.91, alpha: 1),
            title: "BMI", value: "--", unit: "kg/m²")
        bmiCard.onTap = { [weak self] in
            self?.push(BMIViewController())
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
            title: "Body Temp", value: "--", unit: AppSettingsManager.shared.getTemperatureUnit() == .fahrenheit ? "°F" : "°C")
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

        // Card 1 — Latest Notification
        insightCard1 = makeInsightCardShell(
            iconView: &insightIcon1, iconBg: &insightIconBg1,
            titleLabel: &insightTitle1, bodyLabel: &insightBody1, timeLabel: &insightTime1
        )
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(insightCard1Tapped))
        insightCard1.addGestureRecognizer(tap1)
        insightCard1.isUserInteractionEnabled = true
        insightCard1.isHidden = true   // shown only when notification data exists
        insightsSection.addContent(insightCard1)

        // Card 2 — Sleep Quality
        insightCard2 = makeInsightCardShell(
            iconView: &insightIcon2, iconBg: &insightIconBg2,
            titleLabel: &insightTitle2, bodyLabel: &insightBody2, timeLabel: &insightTime2
        )
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(insightCard2Tapped))
        insightCard2.addGestureRecognizer(tap2)
        insightCard2.isUserInteractionEnabled = true
        insightCard2.isHidden = true   // shown only when sleep data exists
        insightsSection.addContent(insightCard2)

        // Card 3 — Steps & Activity (always visible)
        insightCard3 = makeInsightCardShell(
            iconView: &insightIcon3, iconBg: &insightIconBg3,
            titleLabel: &insightTitle3, bodyLabel: &insightBody3, timeLabel: &insightTime3
        )
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(insightCard3Tapped))
        insightCard3.addGestureRecognizer(tap3)
        insightCard3.isUserInteractionEnabled = true
        insightsSection.addContent(insightCard3)
    }

    /// Creates a card shell and sets the caller's label/icon references via inout params.
    private func makeInsightCardShell(
        iconView: inout UIImageView,
        iconBg: inout UIView,
        titleLabel: inout UILabel,
        bodyLabel: inout UILabel,
        timeLabel: inout UILabel
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.masksToBounds = false
        card.translatesAutoresizingMaskIntoConstraints = false

        let localIconBg = UIView()
        localIconBg.layer.cornerRadius = 24
        localIconBg.translatesAutoresizingMaskIntoConstraints = false

        let localIconView = UIImageView()
        localIconView.contentMode = .scaleAspectFit
        localIconView.translatesAutoresizingMaskIntoConstraints = false
        localIconBg.addSubview(localIconView)

        let localTitle = UILabel()
        localTitle.font = .systemFont(ofSize: 14, weight: .bold)
        localTitle.textColor = .black
        localTitle.translatesAutoresizingMaskIntoConstraints = false

        let localBody = UILabel()
        localBody.font = .systemFont(ofSize: 12)
        localBody.textColor = UIColor(white: 0.45, alpha: 1)
        localBody.numberOfLines = 2
        localBody.translatesAutoresizingMaskIntoConstraints = false

        let localTime = UILabel()
        localTime.font = .systemFont(ofSize: 11)
        localTime.textColor = UIColor(white: 0.60, alpha: 1)
        localTime.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView()
        chevron.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        chevron.tintColor = UIColor(white: 0.65, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        [localIconBg, localTitle, localBody, localTime, chevron].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            localIconView.centerXAnchor.constraint(equalTo: localIconBg.centerXAnchor),
            localIconView.centerYAnchor.constraint(equalTo: localIconBg.centerYAnchor),
            localIconView.widthAnchor.constraint(equalToConstant: 22),
            localIconView.heightAnchor.constraint(equalToConstant: 22),

            localIconBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            localIconBg.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            localIconBg.widthAnchor.constraint(equalToConstant: 48),
            localIconBg.heightAnchor.constraint(equalToConstant: 48),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 9),
            chevron.heightAnchor.constraint(equalToConstant: 15),

            localTitle.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            localTitle.leadingAnchor.constraint(equalTo: localIconBg.trailingAnchor, constant: 12),
            localTitle.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            localBody.topAnchor.constraint(equalTo: localTitle.bottomAnchor, constant: 4),
            localBody.leadingAnchor.constraint(equalTo: localTitle.leadingAnchor),
            localBody.trailingAnchor.constraint(equalTo: localTitle.trailingAnchor),

            localTime.topAnchor.constraint(equalTo: localBody.bottomAnchor, constant: 4),
            localTime.leadingAnchor.constraint(equalTo: localTitle.leadingAnchor),
            localTime.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])

        // Write back to caller's inout references
        iconView   = localIconView
        iconBg     = localIconBg
        titleLabel = localTitle
        bodyLabel  = localBody
        timeLabel  = localTime

        return card
    }

    // MARK: - Insight Card Tap Actions

    @objc private func insightCard1Tapped() {
        push(NotificationsViewController())
    }

    @objc private func insightCard2Tapped() {
        push(SleepViewController())
    }

    @objc private func insightCard3Tapped() {
        push(StepsViewController())
    }

    // MARK: - Update Insight Cards

    func updateInsightCards() {
        updateNotificationInsightCard()
        updateSleepInsightCard()
        updateStepsInsightCard()
    }

    private func updateNotificationInsightCard() {
        // Prefer live cache; fall back to UserDefaults written by NotificationService
        let title: String
        let body: String
        let time: String
        let vitalKey: String

        if let notif = NotificationCache.shared.latest {
            title    = notif.resolvedTitle
            body     = notif.message
            time     = relativeTime(from: Date(timeIntervalSince1970: TimeInterval(notif.timestamp)))
            vitalKey = notif.parsedVitals.keys.first ?? notif.vitals ?? ""
            insightCard1.isHidden = false
        } else {
            let defaults = UserDefaults.standard
            let storedTitle = defaults.string(forKey: "notif_latest_title") ?? ""
            guard !storedTitle.isEmpty else {
                insightCard1.isHidden = true
                return
            }
            title    = storedTitle
            body     = defaults.string(forKey: "notif_latest_body") ?? ""
            let ts   = defaults.double(forKey: "notif_latest_time")
            time     = ts > 0 ? relativeTime(from: Date(timeIntervalSince1970: ts)) : ""
            vitalKey = defaults.string(forKey: "notif_latest_vital") ?? ""
            insightCard1.isHidden = false
        }

        insightTitle1.text = title
        insightBody1.text  = body
        insightTime1.text  = time
        let (icon, tint, bg) = notifIconInfo(for: vitalKey)
        insightIcon1.image           = icon?.withRenderingMode(.alwaysTemplate)
        insightIcon1.tintColor       = tint
        insightIconBg1.backgroundColor = bg
    }

    private func updateSleepInsightCard() {
        let sleepMin  = UserDefaults.standard.integer(forKey: "last_day_sleep_minutes")
        let quality   = UserDefaults.standard.integer(forKey: "last_day_sleep_quality")

        guard sleepMin > 0 else {
            insightCard2.isHidden = true
            return
        }
        insightCard2.isHidden = false

        let h = sleepMin / 60
        let m = sleepMin % 60
        let durStr = h > 0 ? "\(h)h \(m)m" : "\(m)m"

        let green  = UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        let orange = UIColor(red: 1.00, green: 0.65, blue: 0.15, alpha: 1)
        let red    = UIColor(red: 1.00, green: 0.32, blue: 0.32, alpha: 1)
        let greenBg  = UIColor(red: 0.88, green: 0.97, blue: 0.89, alpha: 1)
        let orangeBg = UIColor(red: 1.00, green: 0.95, blue: 0.88, alpha: 1)
        let redBg    = UIColor(red: 1.00, green: 0.88, blue: 0.88, alpha: 1)

        let title: String
        let body: String
        let iconName: String
        let tint: UIColor
        let bg: UIColor

        if quality >= 90 && sleepMin >= 420 {
            title    = "Excellent Sleep Quality"
            body     = "You had \(durStr) of quality sleep. Keep up the excellent work!"
            iconName = "checkmark.circle.fill"
            tint     = green;  bg = greenBg
        } else if quality >= 80 && sleepMin >= 360 {
            title    = "Great Sleep Quality"
            body     = "You had \(durStr) of quality sleep. Keep up the good work!"
            iconName = "checkmark.circle.fill"
            tint     = green;  bg = greenBg
        } else if quality >= 70 {
            title    = "Good Sleep"
            body     = "You slept for \(durStr). Try to maintain consistency!"
            iconName = "moon.fill"
            tint     = orange; bg = orangeBg
        } else {
            title    = "Sleep Needs Improvement"
            body     = "You had \(durStr) of sleep. Aim for better rest tonight!"
            iconName = "moon.fill"
            tint     = red;    bg = redBg
        }

        insightTitle2.text = title
        insightBody2.text  = body
        insightTime2.text  = "Last night"
        insightIcon2.image           = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
        insightIcon2.tintColor       = tint
        insightIconBg2.backgroundColor = bg
    }

    private func updateStepsInsightCard() {
        let todayTotals = stepsRepo.getTodayTotals()
        let steps       = todayTotals.steps
        let calories    = todayTotals.calories
        let target      = AppSettingsManager.shared.getStepsTarget()   // default 10 000

        let green   = UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        let orange  = UIColor(red: 1.00, green: 0.65, blue: 0.15, alpha: 1)
        let indigo  = UIColor(red: 0.33, green: 0.43, blue: 1.00, alpha: 1)
        let grey    = UIColor(white: 0.6, alpha: 1)
        let greenBg  = UIColor(red: 0.88, green: 0.97, blue: 0.89, alpha: 1)
        let orangeBg = UIColor(red: 1.00, green: 0.95, blue: 0.88, alpha: 1)
        let indigoBg = UIColor(red: 0.90, green: 0.92, blue: 1.00, alpha: 1)
        let amberBg  = UIColor(red: 1.00, green: 0.97, blue: 0.88, alpha: 1)

        let progress = target > 0 ? (steps * 100 / target) : 0
        let remaining = max(0, target - steps)

        let title: String
        let body: String
        let iconName: String
        let tint: UIColor
        let bg: UIColor

        if steps == 0 {
            title    = "Start Your Day Active!"
            body     = "No steps recorded yet. Get moving to reach your \(formattedNumber(target)) step goal!"
            iconName = "figure.run"
            tint     = grey;   bg = amberBg
        } else if steps >= target {
            title    = "Daily Step Goal Achieved!"
            body     = "Great job! You've walked \(formattedNumber(steps)) steps and burned \(calories) kcal today. Keep it up!"
            iconName = "checkmark.circle.fill"
            tint     = green;  bg = greenBg
        } else if progress >= 75 {
            title    = "Almost There!"
            body     = "You're \(progress)% to your goal! Just \(formattedNumber(remaining)) more steps to go. You've burned \(calories) kcal."
            iconName = "figure.walk"
            tint     = green;  bg = greenBg
        } else if progress >= 50 {
            title    = "Halfway to Your Goal!"
            body     = "You've completed \(formattedNumber(steps)) steps (\(progress)%). Burned \(calories) kcal so far. Keep moving!"
            iconName = "figure.walk"
            tint     = orange; bg = orangeBg
        } else {
            title    = "Keep Moving!"
            body     = "You've taken \(formattedNumber(steps)) steps and burned \(calories) kcal. You're \(progress)% to your goal!"
            iconName = "figure.run"
            tint     = indigo; bg = indigoBg
        }

        insightTitle3.text = title
        insightBody3.text  = body
        insightTime3.text  = "Today"
        insightIcon3.image           = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
        insightIcon3.tintColor       = tint
        insightIconBg3.backgroundColor = bg
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
        let todaySteps = stepsRepo.getTodayTotals()
        let steps     = todaySteps.steps
        let calories  = todaySteps.calories
        let glucose   = bloodGlucoseRepo.getLatestEntry()?.glucoseValue   ?? 0
        let temp      = temperatureRepo.getLatestEntry()?.temperatureValue ?? 0
        // Both keys written by SleepSyncHelper.updateDashboardSleepStats after every BLE sync
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
        updateInsightCards()

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
        let unitSetting = AppSettingsManager.shared.getTemperatureUnit()
        let displayTemp = (unitSetting == .fahrenheit && temp > 0) ? TemperatureConverter.celsiusToFahrenheit(temp) : temp
        let unitStr = unitSetting == .fahrenheit ? "°F" : "°C"
        let text = displayTemp > 0 ? String(format: "%.1f", displayTemp) : "--"
        bodyTempCard.updateValue(text, unit: unitStr)
        let (status, color) = tempStatus(temp)   // tempStatus thresholds are in Celsius
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
        let stored = UserDefaults.standard.integer(forKey: "last_day_sleep_quality")
        if stored > 0 { return stored }

        // Fallback: mirror SleepSyncHelper — today's sleep group, per-field minute truncation
        let sessions = sleepRepo.getByDateRange(startDate: Date(), endDate: Date())
        guard !sessions.isEmpty else { return 0 }
        let totalMin = sessions.reduce(0) {
            $0 + Int($1.deepSleepTimes) / 60 + Int($1.lightSleepTimes) / 60 + Int($1.remSleepTimes) / 60
        }
        return min(100, max(12, Int(Double(totalMin) / 480.0 * 100)))
    }

    private func computeBMI() -> Double {
        let heightCm = UserDefaults.standard.double(forKey: "user_height")
        let weightKg = UserDefaults.standard.double(forKey: "user_weight")
        guard heightCm > 0, weightKg > 0 else { return 0 }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    private func lastSyncDate() -> Date? {
        // Always derive from live UserDefaults keys so it's accurate even after app restart.
        return SyncFreshnessChecker.lastPrimaryDataDate()
    }

    // MARK: - Last Sync Detail Popup
    private func showLastSyncDetailPopup() {
        let mgr = BackgroundSyncManager.shared
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM yyyy, hh:mm a"

        // Query local DB for actual last data timestamps
        let hrTs    = HeartRateRepository().getLatestEntry()?.timestamp
        let bpTs    = BloodPressureRepository().getLatestEntry()?.timestamp
        let hrvTs   = HrvRepository().getLatestEntry()?.timestamp
        let o2Ts    = BloodOxygenRepository().getLatestEntry()?.timestamp
        let bgTs    = BloodGlucoseRepository().getLatestEntry()?.timestamp
        let tempTs  = TemperatureRepository().getLatestEntry()?.timestamp

        func format(_ ts: Int64?) -> String {
            guard let ts = ts, ts > 0 else { return "No data yet" }
            return fmt.string(from: Date(timeIntervalSince1970: TimeInterval(ts)))
        }

        // Status: -1 = never synced, 0 = synced but device had no new data, >0 = new data received
        func status(_ bleCount: Int, hasSyncRan: Bool) -> String {
            guard hasSyncRan else { return "" }
            return bleCount > 0 ? "  🔄 Updated" : "  ✅ Up to date"
        }

        func row(_ emoji: String, _ name: String, _ ts: Int64?, syncRan: Bool, bleCount: Int) -> String {
            "\(emoji) \(name)\n    \(format(ts))\(status(bleCount, hasSyncRan: syncRan))"
        }

        let body = [
            row("❤️", "Heart Rate",     hrTs,   syncRan: mgr.lastHeartRateSync != nil,     bleCount: mgr.lastHeartRateBleCount),
            row("🫀", "HRV",            hrvTs,  syncRan: mgr.lastHRVSync != nil,            bleCount: mgr.lastHRVBleCount),
            row("🩸", "Blood Oxygen",   o2Ts,   syncRan: mgr.lastBloodOxygenSync != nil,   bleCount: mgr.lastBloodOxygenBleCount),
            row("💉", "Blood Glucose",  bgTs,   syncRan: mgr.lastBloodGlucoseSync != nil,  bleCount: mgr.lastBloodGlucoseBleCount),
            row("🫁", "Blood Pressure", bpTs,   syncRan: mgr.lastBloodPressureSync != nil, bleCount: mgr.lastBloodPressureBleCount),
            row("🌡️", "Temperature",    tempTs, syncRan: mgr.lastTemperatureSync != nil,   bleCount: mgr.lastTemperatureBleCount),
        ].joined(separator: "\n\n")

        let alert = UIAlertController(title: "Last Data per Vital", message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

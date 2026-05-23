import UIKit

// MARK: - Entry Type
enum CardiovascularVitalType {
    case heartRate, hrv, ecg, bloodPressure, bloodOxygen, all

    var cardSubtitle: String {
        switch self {
        case .heartRate:     return "Heart Rate Details"
        case .hrv:           return "HRV Details"
        case .ecg:           return "ECG Details"
        case .bloodPressure: return "Blood Pressure Details"
        case .bloodOxygen:   return "Blood Oxygen (SpO2) Details"
        case .all:           return "HR, HRV, ECG, BP, SpO2"
        }
    }
}

// MARK: - Category
private enum VitalCategory {
    case optimal, caution, critical

    var color: UIColor {
        switch self {
        case .optimal:  return UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1) // #4CAF50
        case .caution:  return UIColor(red: 1.000, green: 0.702, blue: 0.000, alpha: 1) // #FFB300
        case .critical: return UIColor(red: 0.957, green: 0.263, blue: 0.212, alpha: 1) // #F44336
        }
    }

    var title: String {
        switch self {
        case .optimal:  return "OPTIMAL"
        case .caution:  return "CAUTION"
        case .critical: return "CRITICAL"
        }
    }

    var columnSubtitle: String {
        switch self {
        case .optimal:  return "Baseline: Excellent"
        case .caution:  return "Recent Deviation"
        case .critical: return "Immediate Attention"
        }
    }

    var emptyMessage: String {
        switch self {
        case .optimal:  return "⚠ No vitals in\noptimal range"
        case .caution:  return "✓ No caution\nalerts"
        case .critical: return "✓ No critical\nalerts"
        }
    }

    var emptyTextColor: UIColor {
        switch self {
        case .optimal:  return UIColor(white: 0.6, alpha: 1)
        default:        return UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1)
        }
    }
}

// MARK: - Vital Model
private struct VitalData {
    let label: String
    let value: String
    let unit: String
    let subLabel: String
    let category: VitalCategory
    // single‑arrow vitals
    let currentValueInt: Int
    let previousValue: Int
    // BP two‑arrow
    let hasTwoArrows: Bool
    let currentValueLeft: Int
    let currentValueRight: Int
    let previousValueLeft: Int
    let previousValueRight: Int
}

// MARK: - ViewController
final class CardiovascularStatusViewController: AppBaseViewController {

    // MARK: Input from dashboard
    var vitalType: CardiovascularVitalType = .all
    var heartRate: Int = 0
    var heartRateStatus: String = "--"
    var previousHeartRate: Int = 0
    var hrv: Int = 0
    var hrvStatus: String = "--"
    var previousHrv: Int = 0
    var bloodPressureSystolic: Int = 0
    var bloodPressureDiastolic: Int = 0
    var bloodPressureStatus: String = "--"
    var previousSystolic: Int = 0
    var previousDiastolic: Int = 0
    var spo2: Int = 0
    var spo2Status: String = "--"
    var previousSpo2: Int = 0
    var ecgValue: Int = 0
    var ecgStatus: String = "--"
    var previousEcg: Int = 0
    var lastSyncMillis: Int64 = 0

    // MARK: Private UI
    private let outerScroll = UIScrollView()
    private let contentView  = UIView()

    // Per-column inner scroll views & hint containers (store to wire scroll events)
    private var innerScrollViews: [UIScrollView] = []
    private var scrollHintContainers: [UIView] = []
    private var scrollHints: [UILabel] = []

    // Fixed height for the scrollable vitals area in each column
    private let columnScrollHeight: CGFloat = 175

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("")   // back button only; logo shown by LogoNavigationController
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        setupOuterScroll()
        setupSyncBanner()
        setupPageTitle()
        setupTopCard()
        setupSectionTitle()
        setupThreeColumns()
        setupLegendCard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Defer so inner scroll view contentSizes are fully resolved
        DispatchQueue.main.async { self.updateScrollHints() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateScrollHints()
    }

    // MARK: - Outer scroll
    private func setupOuterScroll() {
        outerScroll.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outerScroll)
        outerScroll.addSubview(contentView)
        NSLayoutConstraint.activate([
            outerScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            outerScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outerScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            outerScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: outerScroll.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: outerScroll.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: outerScroll.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: outerScroll.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: outerScroll.widthAnchor),
        ])
    }

    // MARK: - Sync banner (absolute top‑right)
    private var syncBannerView: UIView!

    private func setupSyncBanner() {
        syncBannerView = UIView()
        syncBannerView.translatesAutoresizingMaskIntoConstraints = false

        let refreshIcon = UIImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath"))
        refreshIcon.tintColor = UIColor(red: 0.051, green: 0.6, blue: 1.0, alpha: 1)
        refreshIcon.contentMode = .scaleAspectFit
        refreshIcon.translatesAutoresizingMaskIntoConstraints = false
        refreshIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        refreshIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let textLabel = UILabel()
        textLabel.text = syncText()
        textLabel.font = UIFont.systemFont(ofSize: 11)
        textLabel.textColor = UIColor(red: 0.051, green: 0.6, blue: 1.0, alpha: 1)
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        let dot = UIView()
        dot.backgroundColor = syncDotColor()
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let row = UIStackView(arrangedSubviews: [refreshIcon, textLabel, dot])
        row.axis = .horizontal
        row.spacing = 4
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        syncBannerView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: syncBannerView.topAnchor),
            row.bottomAnchor.constraint(equalTo: syncBannerView.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: syncBannerView.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: syncBannerView.trailingAnchor),
        ])

        contentView.addSubview(syncBannerView)
        NSLayoutConstraint.activate([
            syncBannerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            syncBannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Page title
    private var pageTitleLabel: UILabel!

    private func setupPageTitle() {
        pageTitleLabel = UILabel()
        pageTitleLabel.text = "CARDIOVASCULAR STATUS SUMMARY"
        pageTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        pageTitleLabel.textColor = UIColor(white: 0.08, alpha: 1)
        pageTitleLabel.numberOfLines = 2
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageTitleLabel)
        NSLayoutConstraint.activate([
            pageTitleLabel.topAnchor.constraint(equalTo: syncBannerView.bottomAnchor, constant: 8),
            pageTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pageTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Top card (icon + title + subtitle + chevron)
    private var topCard: UIView!

    private func setupTopCard() {
        topCard = UIView()
        topCard.backgroundColor = .white
        topCard.layer.cornerRadius = 14
        topCard.layer.shadowColor = UIColor.black.cgColor
        topCard.layer.shadowOpacity = 0.10
        topCard.layer.shadowRadius = 8
        topCard.layer.shadowOffset = CGSize(width: 0, height: 3)
        topCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topCard)

        // Pink circle icon background
        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1) // light pink
        iconBg.layer.cornerRadius = 26
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 52).isActive = true
        iconBg.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let heartIcon = UIImageView(image: UIImage(systemName: "heart.fill"))
        heartIcon.tintColor = UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1)
        heartIcon.contentMode = .scaleAspectFit
        heartIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(heartIcon)
        NSLayoutConstraint.activate([
            heartIcon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            heartIcon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            heartIcon.widthAnchor.constraint(equalToConstant: 26),
            heartIcon.heightAnchor.constraint(equalToConstant: 26),
        ])

        let cardTitleLabel = UILabel()
        cardTitleLabel.text = "Cardiovascular"
        cardTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        cardTitleLabel.textColor = UIColor(white: 0.08, alpha: 1)
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let cardSubtitleLabel = UILabel()
        cardSubtitleLabel.text = vitalType.cardSubtitle
        cardSubtitleLabel.font = UIFont.systemFont(ofSize: 13)
        cardSubtitleLabel.textColor = UIColor(white: 0.50, alpha: 1)
        cardSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [cardTitleLabel, cardSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UILabel()
        chevron.text = "›"
        chevron.font = UIFont.systemFont(ofSize: 26, weight: .light)
        chevron.textColor = UIColor(white: 0.6, alpha: 1)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView(arrangedSubviews: [iconBg, textStack, chevron])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        topCard.addSubview(hStack)

        NSLayoutConstraint.activate([
            topCard.topAnchor.constraint(equalTo: pageTitleLabel.bottomAnchor, constant: 10),
            topCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            topCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),

            hStack.topAnchor.constraint(equalTo: topCard.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: topCard.bottomAnchor, constant: -14),
            hStack.leadingAnchor.constraint(equalTo: topCard.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: topCard.trailingAnchor, constant: -14),
        ])

        topCard.isUserInteractionEnabled = true
        topCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(topCardTapped)))
    }

    @objc private func topCardTapped() {
        let vc: UIViewController
        switch vitalType {
        case .heartRate:
            vc = HeartRateViewController()
        case .hrv:
            vc = HealthVitalsViewController(vitalType: .hrv)
        case .ecg:
            vc = ECGViewController()
        case .bloodPressure:
            vc = HealthVitalsViewController(vitalType: .bloodPressure)
        case .bloodOxygen:
            vc = HealthVitalsViewController(vitalType: .bloodOxygen)
        case .all:
            Toast.show(message: "Please select a specific vital from dashboard", in: view)
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Section title
    private var sectionTitleLabel: UILabel!

    private func setupSectionTitle() {
        sectionTitleLabel = UILabel()
        sectionTitleLabel.text = "CARDIOVASCULAR HEALTH"
        sectionTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        sectionTitleLabel.textColor = UIColor(red: 0.133, green: 0.122, blue: 0.122, alpha: 1) // #221F1F
        sectionTitleLabel.textAlignment = .center
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sectionTitleLabel)
        NSLayoutConstraint.activate([
            sectionTitleLabel.topAnchor.constraint(equalTo: topCard.bottomAnchor, constant: 18),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Three columns
    private var columnsStack: UIStackView!
    private var columnsStackBottomAnchor: NSLayoutConstraint!

    private func setupThreeColumns() {
        let vitals = buildVitals()
        let optimal  = vitals.filter { $0.category == .optimal }
        let caution  = vitals.filter { $0.category == .caution }
        let critical = vitals.filter { $0.category == .critical }

        columnsStack = UIStackView()
        columnsStack.axis = .horizontal
        columnsStack.distribution = .fillEqually
        columnsStack.spacing = 10
        columnsStack.alignment = .fill
        columnsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(columnsStack)

        let optimalCol  = makeColumnCard(category: .optimal,  vitals: optimal)
        let cautionCol  = makeColumnCard(category: .caution,  vitals: caution)
        let criticalCol = makeColumnCard(category: .critical, vitals: critical)
        columnsStack.addArrangedSubview(optimalCol)
        columnsStack.addArrangedSubview(cautionCol)
        columnsStack.addArrangedSubview(criticalCol)

        NSLayoutConstraint.activate([
            columnsStack.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 14),
            columnsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            columnsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])
    }

    /// Builds one column card: header (non-scrollable) + vitals scroll area + scroll hint
    private func makeColumnCard(category: VitalCategory, vitals: [VitalData]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = false
        card.layer.shadowColor  = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.10
        card.layer.shadowRadius  = 6
        card.layer.shadowOffset  = CGSize(width: 0, height: 3)
        card.translatesAutoresizingMaskIntoConstraints = false

        // --- Glowing circle ---
        let circleSize: CGFloat = 62
        let circleView = UIView()
        circleView.backgroundColor = category.color
        circleView.layer.cornerRadius = circleSize / 2
        circleView.layer.shadowColor  = category.color.cgColor
        circleView.layer.shadowOpacity = 0.55
        circleView.layer.shadowRadius  = 12
        circleView.layer.shadowOffset  = CGSize(width: 0, height: 4)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: circleSize).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: circleSize).isActive = true

        // Inner highlight (lighter top half to simulate radial gradient)
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.white.withAlphaComponent(0.20)
        highlightView.layer.cornerRadius = circleSize / 2
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        circleView.addSubview(highlightView)
        NSLayoutConstraint.activate([
            highlightView.topAnchor.constraint(equalTo: circleView.topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: circleView.leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: circleView.trailingAnchor),
            highlightView.heightAnchor.constraint(equalToConstant: circleSize * 0.55),
        ])

        // --- Category label (● OPTIMAL) ---
        let categoryLabel = UILabel()
        categoryLabel.text = "● \(category.title)"
        categoryLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        categoryLabel.textColor = category.color
        categoryLabel.textAlignment = .center
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false

        // --- Subtitle ---
        let subLabel = UILabel()
        subLabel.text = category.columnSubtitle
        subLabel.font = UIFont.systemFont(ofSize: 10)
        subLabel.textColor = UIColor(white: 0.50, alpha: 1)
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 1
        subLabel.adjustsFontSizeToFitWidth = true
        subLabel.minimumScaleFactor = 0.65
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        // --- Colored divider ---
        let divider = UIView()
        divider.backgroundColor = category.color
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1.5).isActive = true

        // --- Inner scroll view (fixed height, independent scroll) ---
        let innerScroll = UIScrollView()
        innerScroll.showsVerticalScrollIndicator = false
        innerScroll.alwaysBounceVertical = false
        innerScroll.translatesAutoresizingMaskIntoConstraints = false
        innerScroll.heightAnchor.constraint(equalToConstant: columnScrollHeight).isActive = true

        let vitalsContainer = UIView()
        vitalsContainer.backgroundColor = .white
        vitalsContainer.translatesAutoresizingMaskIntoConstraints = false
        innerScroll.addSubview(vitalsContainer)
        NSLayoutConstraint.activate([
            vitalsContainer.topAnchor.constraint(equalTo: innerScroll.topAnchor),
            vitalsContainer.leadingAnchor.constraint(equalTo: innerScroll.leadingAnchor),
            vitalsContainer.trailingAnchor.constraint(equalTo: innerScroll.trailingAnchor),
            vitalsContainer.bottomAnchor.constraint(equalTo: innerScroll.bottomAnchor),
            vitalsContainer.widthAnchor.constraint(equalTo: innerScroll.widthAnchor),
        ])

        // Populate vitals
        if vitals.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = category.emptyMessage
            emptyLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            emptyLabel.textColor = category.emptyTextColor
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 2
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            vitalsContainer.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.topAnchor.constraint(equalTo: vitalsContainer.topAnchor, constant: 14),
                emptyLabel.centerXAnchor.constraint(equalTo: vitalsContainer.centerXAnchor),
                emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: vitalsContainer.leadingAnchor, constant: 4),
                emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: vitalsContainer.trailingAnchor, constant: -4),
                emptyLabel.bottomAnchor.constraint(equalTo: vitalsContainer.bottomAnchor, constant: -14),
            ])
        } else {
            var prevAnchor = vitalsContainer.topAnchor
            for (i, vital) in vitals.enumerated() {
                let row = makeVitalRow(vital)
                vitalsContainer.addSubview(row)
                NSLayoutConstraint.activate([
                    row.topAnchor.constraint(equalTo: prevAnchor),
                    row.leadingAnchor.constraint(equalTo: vitalsContainer.leadingAnchor),
                    row.trailingAnchor.constraint(equalTo: vitalsContainer.trailingAnchor),
                ])
                prevAnchor = row.bottomAnchor
                if i < vitals.count - 1 {
                    let sep = UIView()
                    sep.backgroundColor = UIColor(white: 0.88, alpha: 1)
                    sep.translatesAutoresizingMaskIntoConstraints = false
                    sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    vitalsContainer.addSubview(sep)
                    NSLayoutConstraint.activate([
                        sep.topAnchor.constraint(equalTo: prevAnchor),
                        sep.leadingAnchor.constraint(equalTo: vitalsContainer.leadingAnchor, constant: 8),
                        sep.trailingAnchor.constraint(equalTo: vitalsContainer.trailingAnchor, constant: -8),
                    ])
                    prevAnchor = sep.bottomAnchor
                }
            }
            // Bind last element to container bottom
            let lastConstraint = vitalsContainer.bottomAnchor.constraint(equalTo: prevAnchor)
            lastConstraint.isActive = true
        }

        // --- Scroll hint (full-width gray strip) ---
        let scrollHintContainer = UIView()
        scrollHintContainer.backgroundColor = UIColor(white: 0.88, alpha: 1)
        scrollHintContainer.layer.cornerRadius = 16
        scrollHintContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        scrollHintContainer.layer.masksToBounds = true
        scrollHintContainer.isHidden = true
        scrollHintContainer.translatesAutoresizingMaskIntoConstraints = false

        let scrollHint = UILabel()
        scrollHint.text = "scroll ↓"
        scrollHint.font = UIFont.systemFont(ofSize: 10)
        scrollHint.textColor = UIColor(white: 0.40, alpha: 1)
        scrollHint.textAlignment = .center
        scrollHint.translatesAutoresizingMaskIntoConstraints = false
        scrollHintContainer.addSubview(scrollHint)
        NSLayoutConstraint.activate([
            scrollHint.topAnchor.constraint(equalTo: scrollHintContainer.topAnchor, constant: 6),
            scrollHint.bottomAnchor.constraint(equalTo: scrollHintContainer.bottomAnchor, constant: -6),
            scrollHint.centerXAnchor.constraint(equalTo: scrollHintContainer.centerXAnchor),
        ])

        // Assemble header stack
        let headerStack = UIStackView(arrangedSubviews: [circleView, categoryLabel, subLabel, divider])
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 6
        headerStack.setCustomSpacing(10, after: subLabel)
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(headerStack)
        card.addSubview(innerScroll)
        card.addSubview(scrollHintContainer)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            headerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),

            divider.widthAnchor.constraint(equalTo: headerStack.widthAnchor),

            innerScroll.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            innerScroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            innerScroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            scrollHintContainer.topAnchor.constraint(equalTo: innerScroll.bottomAnchor),
            scrollHintContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            scrollHintContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            scrollHintContainer.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        // Store for scroll hint updates
        innerScrollViews.append(innerScroll)
        scrollHintContainers.append(scrollHintContainer)
        scrollHints.append(scrollHint)

        // Wire scroll callback
        innerScroll.delegate = self

        return card
    }

    // MARK: - Update scroll hints
    private func updateScrollHints() {
        for (i, sv) in innerScrollViews.enumerated() {
            guard i < scrollHintContainers.count else { continue }
            let child = sv.contentSize.height
            let visible = sv.bounds.height
            scrollHintContainers[i].isHidden = child <= visible
        }
    }

    // MARK: - Vital row view
    private func makeVitalRow(_ vital: VitalData) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let labelLbl = UILabel()
        labelLbl.text = vital.label
        labelLbl.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        labelLbl.textColor = .black
        labelLbl.textAlignment = .center
        labelLbl.translatesAutoresizingMaskIntoConstraints = false

        // Value row (left arrow placeholder | value | right arrow)
        let valueRow = UIStackView()
        valueRow.axis = .horizontal
        valueRow.spacing = 4
        valueRow.alignment = .center
        valueRow.translatesAutoresizingMaskIntoConstraints = false

        let valueLbl = UILabel()
        let valueFontSize: CGFloat = vital.hasTwoArrows ? 17 : 20
        valueLbl.text = vital.value
        valueLbl.font = UIFont.systemFont(ofSize: valueFontSize, weight: .bold)
        valueLbl.textColor = .black
        valueLbl.translatesAutoresizingMaskIntoConstraints = false

        if vital.hasTwoArrows {
            // BP: left arrow (systolic) | value | right arrow (diastolic)
            valueRow.addArrangedSubview(makeArrowLabel(current: vital.currentValueLeft,  previous: vital.previousValueLeft))
            valueRow.addArrangedSubview(valueLbl)
            valueRow.addArrangedSubview(makeArrowLabel(current: vital.currentValueRight, previous: vital.previousValueRight))
        } else {
            // Invisible placeholder on left, value in center, arrow on right
            let placeholder = UIView()
            placeholder.widthAnchor.constraint(equalToConstant: 14).isActive = true
            placeholder.heightAnchor.constraint(equalToConstant: 14).isActive = true
            valueRow.addArrangedSubview(placeholder)
            valueRow.addArrangedSubview(valueLbl)
            valueRow.addArrangedSubview(makeArrowLabel(current: vital.currentValueInt, previous: vital.previousValue))
        }

        let unitLbl = UILabel()
        unitLbl.text = vital.unit
        unitLbl.font = UIFont.systemFont(ofSize: 10)
        unitLbl.textColor = UIColor(white: 0.60, alpha: 1)
        unitLbl.textAlignment = .center
        unitLbl.translatesAutoresizingMaskIntoConstraints = false

        let vStack = UIStackView(arrangedSubviews: [labelLbl, valueRow, unitLbl])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 2
        vStack.translatesAutoresizingMaskIntoConstraints = false

        // Sub-label for ECG
        if !vital.subLabel.isEmpty && vital.subLabel != "--" {
            let subLbl = UILabel()
            subLbl.text = vital.subLabel
            subLbl.font = UIFont.systemFont(ofSize: 9)
            subLbl.textColor = UIColor(white: 0.40, alpha: 1)
            subLbl.textAlignment = .center
            subLbl.translatesAutoresizingMaskIntoConstraints = false
            vStack.addArrangedSubview(subLbl)
        }

        container.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            vStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            vStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            vStack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 2),
            vStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -2),
        ])

        return container
    }

    // Arrow label: ↑ green if current ≥ previous or previous == 0, else ↓ red
    private func makeArrowLabel(current: Int, previous: Int) -> UILabel {
        let isUp = previous == 0 || current >= previous
        let lbl = UILabel()
        lbl.text = isUp ? "↑" : "↓"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        lbl.textColor = isUp
            ? UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1) // #4CAF50
            : UIColor(red: 0.957, green: 0.263, blue: 0.212, alpha: 1) // #F44336
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    // MARK: - Legend card
    private func setupLegendCard() {
        let legendCard = UIView()
        legendCard.backgroundColor = .white
        legendCard.layer.cornerRadius = 14
        legendCard.layer.shadowColor = UIColor.black.cgColor
        legendCard.layer.shadowOpacity = 0.10
        legendCard.layer.shadowRadius = 6
        legendCard.layer.shadowOffset = CGSize(width: 0, height: 3)
        legendCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(legendCard)

        let header = UILabel()
        header.text = "Health Status:"
        header.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        header.textColor = UIColor(white: 0.10, alpha: 1)
        header.translatesAutoresizingMaskIntoConstraints = false

        let items: [(String, UIColor)] = [
            ("● Optimal - Within Normal Range",       UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1)),
            ("● Caution - Requires Attention",        UIColor(red: 1.000, green: 0.702, blue: 0.000, alpha: 1)),
            ("● Critical - Immediate Action Required",UIColor(red: 0.957, green: 0.263, blue: 0.212, alpha: 1)),
        ]

        var views: [UIView] = [header]
        for (text, color) in items {
            let lbl = UILabel()
            lbl.text = text
            lbl.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            lbl.textColor = color
            lbl.translatesAutoresizingMaskIntoConstraints = false
            views.append(lbl)
        }

        let vStack = UIStackView(arrangedSubviews: views)
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        legendCard.addSubview(vStack)

        NSLayoutConstraint.activate([
            legendCard.topAnchor.constraint(equalTo: columnsStack.bottomAnchor, constant: 18),
            legendCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            legendCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            legendCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28),

            vStack.topAnchor.constraint(equalTo: legendCard.topAnchor, constant: 14),
            vStack.bottomAnchor.constraint(equalTo: legendCard.bottomAnchor, constant: -14),
            vStack.leadingAnchor.constraint(equalTo: legendCard.leadingAnchor, constant: 14),
            vStack.trailingAnchor.constraint(equalTo: legendCard.trailingAnchor, constant: -14),
        ])
    }

    // MARK: - Data helpers
    private func syncText() -> String {
        guard lastSyncMillis > 0 else { return "Last recorded: No data yet" }
        let recordedDate = Date(timeIntervalSince1970: TimeInterval(lastSyncMillis) / 1000)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: recordedDate)

        let diff  = Int64(Date().timeIntervalSince1970 * 1000) - lastSyncMillis
        let mins  = diff / 60_000
        let hours = diff / 3_600_000
        let days  = diff / 86_400_000
        if diff  < 60_000  { return "Last recorded: \(timeStr)" }
        if mins  < 60      { return "Last recorded: \(timeStr) (\(mins)m ago)" }
        if hours < 24      { return "Last recorded: \(timeStr) (\(hours)h ago)" }
        return "Last recorded: \(days)d ago (\(timeStr))"
    }

    private func syncDotColor() -> UIColor {
        guard lastSyncMillis > 0 else { return UIColor(red: 0.957, green: 0.263, blue: 0.212, alpha: 1) }
        let hours = (Int64(Date().timeIntervalSince1970 * 1000) - lastSyncMillis) / 3_600_000
        if hours < 2  { return UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1) } // green
        if hours < 12 { return UIColor(red: 1.000, green: 0.655, blue: 0.149, alpha: 1) } // orange #FFA726
        return UIColor(red: 0.957, green: 0.263, blue: 0.212, alpha: 1)                    // red
    }

    /// Classify status string → column
    private func classify(_ status: String) -> VitalCategory {
        let s = status.lowercased()
        let optimalKW = ["optimal","normal","good","excellent","healthy","target met"]
        let cautionKW = ["elevated","fair","moderate","almost","halfway","light","keep going","just started","active"]
        if optimalKW.contains(where: { s.contains($0) }) { return .optimal }
        if cautionKW.contains(where: { s.contains($0) }) { return .caution }
        return .critical
    }

    private func buildVitals() -> [VitalData] {
        return [
            // HR
            VitalData(
                label: "HR",
                value: heartRate > 0 ? "\(heartRate)" : "--",
                unit: "BPM", subLabel: "",
                category: classify(heartRateStatus),
                currentValueInt: heartRate, previousValue: previousHeartRate,
                hasTwoArrows: false,
                currentValueLeft: 0, currentValueRight: 0,
                previousValueLeft: 0, previousValueRight: 0
            ),
            // BP
            VitalData(
                label: "BP",
                value: bloodPressureSystolic > 0 ? "\(bloodPressureSystolic)/\(bloodPressureDiastolic)" : "--/--",
                unit: "mmHg", subLabel: "",
                category: classify(bloodPressureStatus),
                currentValueInt: 0, previousValue: 0,
                hasTwoArrows: true,
                currentValueLeft: bloodPressureSystolic,  currentValueRight: bloodPressureDiastolic,
                previousValueLeft: previousSystolic,      previousValueRight: previousDiastolic
            ),
            // HRV
            VitalData(
                label: "HRV",
                value: hrv > 0 ? "\(hrv)" : "--",
                unit: "ms", subLabel: "",
                category: classify(hrvStatus),
                currentValueInt: hrv, previousValue: previousHrv,
                hasTwoArrows: false,
                currentValueLeft: 0, currentValueRight: 0,
                previousValueLeft: 0, previousValueRight: 0
            ),
            // ECG
            VitalData(
                label: "ECG",
                value: ecgValue > 0 ? "\(ecgValue)" : "--",
                unit: "tores", subLabel: ecgStatus,
                category: classify(ecgStatus),
                currentValueInt: ecgValue, previousValue: previousEcg,
                hasTwoArrows: false,
                currentValueLeft: 0, currentValueRight: 0,
                previousValueLeft: 0, previousValueRight: 0
            ),
            // SpO2
            VitalData(
                label: "SpO₂",
                value: spo2 > 0 ? "\(spo2)" : "--",
                unit: "%", subLabel: "",
                category: classify(spo2Status),
                currentValueInt: spo2, previousValue: previousSpo2,
                hasTwoArrows: false,
                currentValueLeft: 0, currentValueRight: 0,
                previousValueLeft: 0, previousValueRight: 0
            ),
        ]
    }
}

// MARK: - UIScrollViewDelegate (scroll hints)
extension CardiovascularStatusViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let idx = innerScrollViews.firstIndex(of: scrollView),
              idx < scrollHintContainers.count else { return }
        let maxOffset = scrollView.contentSize.height - scrollView.bounds.height
        scrollHintContainers[idx].isHidden = scrollView.contentOffset.y >= maxOffset - 4
    }
}

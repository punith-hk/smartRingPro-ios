import UIKit

class HealthDashboardViewController: AppBaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let gridStack = UIStackView()

    private let topCard = UIView()
    private let stepProgress = StepProgressView()
    private let bottomStatsStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Health")
        showHamburger()

        setupUI()
        setupTopCard()
        setupBottomStats()
        setupVitals()

        stepProgress.setProgress(current: 0, total: 10000)
    }

    // MARK: - Base UI
    private func setupUI() {

        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        gridStack.axis = .vertical
        gridStack.spacing = 16
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            gridStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gridStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            gridStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Top Card
    private func setupTopCard() {

        topCard.backgroundColor = UIColor(red: 0.40, green: 0.80, blue: 0.85, alpha: 1)
        topCard.layer.cornerRadius = 20
        topCard.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topCard)

        NSLayoutConstraint.activate([
            topCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            topCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            topCard.heightAnchor.constraint(equalToConstant: 160)
        ])

        stepProgress.translatesAutoresizingMaskIntoConstraints = false
        topCard.addSubview(stepProgress)

        NSLayoutConstraint.activate([
            stepProgress.centerXAnchor.constraint(equalTo: topCard.centerXAnchor),
            stepProgress.topAnchor.constraint(equalTo: topCard.topAnchor, constant: 18),
            stepProgress.widthAnchor.constraint(equalToConstant: 140),
            stepProgress.heightAnchor.constraint(equalToConstant: 140)
        ])

        gridStack.topAnchor.constraint(equalTo: topCard.bottomAnchor, constant: 24).isActive = true
    }

    // MARK: - Bottom Stats (FIXED SPACING)
    private func setupBottomStats() {

        bottomStatsStack.axis = .horizontal
        bottomStatsStack.distribution = .fillEqually
        bottomStatsStack.alignment = .center
        bottomStatsStack.translatesAutoresizingMaskIntoConstraints = false

        bottomStatsStack.addArrangedSubview(statView(
            icon: "flame.fill",
            text: "0 Kcal",
            align: .left
        ))

        bottomStatsStack.addArrangedSubview(statView(
            icon: "flag.checkered",
            text: "10000",
            align: .center
        ))

        bottomStatsStack.addArrangedSubview(statView(
            icon: "figure.walk",
            text: "0.00 km",
            align: .right
        ))

        topCard.addSubview(bottomStatsStack)

        NSLayoutConstraint.activate([
            bottomStatsStack.leadingAnchor.constraint(equalTo: topCard.leadingAnchor, constant: 24),
            bottomStatsStack.trailingAnchor.constraint(equalTo: topCard.trailingAnchor, constant: -24),
            bottomStatsStack.bottomAnchor.constraint(equalTo: topCard.bottomAnchor, constant: -12),
            bottomStatsStack.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func statView(
        icon: String,
        text: String,
        align: StatAlignment
    ) -> UIView {

        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = .white

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [image, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        switch align {
        case .left:
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            ])

        case .center:
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: container.centerXAnchor)
            ])

        case .right:
            NSLayoutConstraint.activate([
                stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
        }

        return container
    }


    // MARK: - Vitals Grid (UNCHANGED)
    private func setupVitals() {

        let rows = [

            createRow(
                left: VitalCardView(icon: UIImage(systemName: "drop"), title: "Blood Glucose", value: "0 mg/dL"),
                right: VitalCardView(icon: UIImage(systemName: "waveform.path.ecg"), title: "Blood Pressure", value: "--/-- mmHg")
            ),

            createRow(
                left: VitalCardView(icon: UIImage(systemName: "heart.text.square"), title: "ECG", value: ""),
                right: VitalCardView(icon: UIImage(systemName: "bed.double"), title: "Sleep", value: "0h 0m")
            ),

            createRow(
                left: VitalCardView(icon: UIImage(systemName: "heart"), title: "Heart Rate", value: "0 bpm"),
                right: VitalCardView(icon: UIImage(systemName: "waveform"), title: "Heart Rate Variability", value: "0 ms")
            ),

            createRow(
                left: VitalCardView(icon: UIImage(systemName: "thermometer"), title: "Temperature", value: "0°C"),
                right: VitalCardView(icon: UIImage(systemName: "drop.fill"), title: "Blood Oxygen", value: "0%")
            )
        ]

        rows.forEach { gridStack.addArrangedSubview($0) }
    }

    private func createRow(left: UIView, right: UIView) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.spacing = 16
        row.distribution = .fillEqually
        return row
    }
    
//    private func fetchLatestHealthData() {
//
//        guard let userId = UserDefaultsManager.shared.userId else {
//            print("❌ User ID not found")
//            return
//        }
//
//        HealthService.shared.getLastHealthData(userId: userId) { [weak self] result in
//            DispatchQueue.main.async {
//
//                switch result {
//
//                case .success(let response):
//                    if response.data.isEmpty {
//                        print("⚠️ No health data found")
//                    } else {
//                        self?.setData(response)
//                    }
//
//                case .failure(let error):
//                    print("❌ API failed:", error)
//                }
//            }
//        }
//    }
//    
//    private func setData(_ response: GetLastUserHealthDataResponse) {
//
//        let dataMap = Dictionary(uniqueKeysWithValues:
//            response.data.map { ($0.type, $0) }
//        )
//
//        // Temperature
//        if let temp = dataMap["temperature"]?.value {
//            // temperatureLabel.text = "\(temp) °C"
//        }
//
//        // Heart Rate
//        if let hr = dataMap["heart_rate"]?.value {
//            // heartRateLabel.text = "\(hr) times/min"
//        }
//
//        // Blood Oxygen
//        if let spo2 = dataMap["blood_oxygen"]?.value {
//            // bloodOxygenLabel.text = "\(spo2) %"
//        }
//
//        // Blood Pressure
//        let bp = dataMap["blood_pressure"]?.value ?? "--/--"
//        let parts = bp.split(separator: "/")
//        let sys = parts.first ?? "--"
//        let dia = parts.count > 1 ? parts[1] : "--"
//        // bloodPressureLabel.text = "\(sys)/\(dia) mmHg"
//
//        // Blood Sugar
//        if let sugar = dataMap["blood_sugar"]?.value {
//            // bloodSugarLabel.text = "\(sugar) mg/dL"
//        }
//
//        // HRV
//        if let hrv = dataMap["hrv"]?.value {
//            // hrvLabel.text = "\(hrv) times"
//        }
//
//        print("✅ UI updated with latest health data")
//    }

}

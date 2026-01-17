import UIKit

class HealthDashboardViewController: AppBaseViewController {

    // MARK: - Scroll & Layout
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let gridStack = UIStackView()

    // MARK: - Top Card
    private let topCard = UIView()
    private let stepProgress = StepProgressView()
    private let bottomStatsStack = UIStackView()

    // MARK: - Vital Cards (REFERENCES)
    private lazy var bloodGlucoseCard = VitalCardView(
        icon: UIImage(systemName: "drop"),
        title: "Blood Glucose",
        value: "0 mg/dL"
    )

    private lazy var bloodPressureCard = VitalCardView(
        icon: UIImage(systemName: "waveform.path.ecg"),
        title: "Blood Pressure",
        value: "--/-- mmHg"
    )

    private lazy var ecgCard = VitalCardView(
        icon: UIImage(systemName: "heart.text.square"),
        title: "ECG",
        value: ""
    )

    private lazy var sleepCard = VitalCardView(
        icon: UIImage(systemName: "bed.double"),
        title: "Sleep",
        value: "--:--"
    )

    private lazy var heartRateCard = VitalCardView(
        icon: UIImage(systemName: "heart"),
        title: "Heart Rate",
        value: "0 times/min"
    )

    private lazy var hrvCard = VitalCardView(
        icon: UIImage(systemName: "waveform"),
        title: "Heart Rate Variability",
        value: "0 times/min"
    )

    private lazy var temperatureCard = VitalCardView(
        icon: UIImage(systemName: "thermometer"),
        title: "Temperature",
        value: AppSettingsManager.shared.getTemperatureUnit() == .fahrenheit ? "--°F" : "--°C"
    )

    private lazy var bloodOxygenCard = VitalCardView(
        icon: UIImage(systemName: "drop.fill"),
        title: "Blood Oxygen",
        value: "0%"
    )
    
    private var lastHealthResponse: GetLastUserHealthDataResponse?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("Health")
        showHamburger()

        setupUI()
        setupTopCard()
        setupBottomStats()
        setupVitals()
        setupCardActions()

        stepProgress.setProgress(current: 0, total: 10000)

        observeSettings()
        fetchProfileIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data from local DB every time view appears
        fetchLatestHealthData()
    }
    
    private func observeSettings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onTemperatureUnitChanged),
            name: .temperatureUnitChanged,
            object: nil
        )
    }
    
    @objc private func onTemperatureUnitChanged() {
        // Re-fetch and update temperature from local DB with new unit
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let tempRepo = TemperatureRepository()
            let latestTemp = tempRepo.getLatestEntry()
            
            DispatchQueue.main.async {
                if let temp = latestTemp {
                    let tempValue = temp.temperatureValue
                    self.temperatureCard.updateValue(self.formatBodyTemperature(tempValue))
                } else {
                    self.temperatureCard.updateValue(self.formatBodyTemperature(nil))
                }
            }
        }
    }


    // MARK: - Base UI
    private func setupUI() {

        view.backgroundColor = UIColor(
            red: 0.27,
            green: 0.60,
            blue: 0.96,
            alpha: 1
        )

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor
            ),
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor
            ),
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor
            ),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        gridStack.axis = .vertical
        gridStack.spacing = 16
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            gridStack.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            gridStack.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            gridStack.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -24
            ),
        ])
    }

    // MARK: - Top Card
    private func setupTopCard() {

        topCard.backgroundColor = UIColor(
            red: 0.40,
            green: 0.80,
            blue: 0.85,
            alpha: 1
        )
        topCard.layer.cornerRadius = 20
        topCard.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topCard)

        NSLayoutConstraint.activate([
            topCard.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 16
            ),
            topCard.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            topCard.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            topCard.heightAnchor.constraint(equalToConstant: 160),
        ])

        stepProgress.translatesAutoresizingMaskIntoConstraints = false
        topCard.addSubview(stepProgress)
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(openCalories)
        )
        topCard.isUserInteractionEnabled = true
        topCard.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            stepProgress.centerXAnchor.constraint(
                equalTo: topCard.centerXAnchor
            ),
            stepProgress.topAnchor.constraint(
                equalTo: topCard.topAnchor,
                constant: 18
            ),
            stepProgress.widthAnchor.constraint(equalToConstant: 140),
            stepProgress.heightAnchor.constraint(equalToConstant: 140),
        ])

        gridStack.topAnchor.constraint(
            equalTo: topCard.bottomAnchor,
            constant: 24
        ).isActive = true
    }

    // MARK: - Bottom Stats (FIXED SPACING)
    private func setupBottomStats() {

        bottomStatsStack.axis = .horizontal
        bottomStatsStack.distribution = .fillEqually
        bottomStatsStack.alignment = .center
        bottomStatsStack.translatesAutoresizingMaskIntoConstraints = false

        bottomStatsStack.addArrangedSubview(
            statView(
                icon: "flame.fill",
                text: "0 Kcal",
                align: .left
            )
        )

        bottomStatsStack.addArrangedSubview(
            statView(
                icon: "flag.checkered",
                text: "10000",
                align: .center
            )
        )

        bottomStatsStack.addArrangedSubview(
            statView(
                icon: "figure.walk",
                text: "0.00 km",
                align: .right
            )
        )

        topCard.addSubview(bottomStatsStack)

        NSLayoutConstraint.activate([
            bottomStatsStack.leadingAnchor.constraint(
                equalTo: topCard.leadingAnchor,
                constant: 24
            ),
            bottomStatsStack.trailingAnchor.constraint(
                equalTo: topCard.trailingAnchor,
                constant: -24
            ),
            bottomStatsStack.bottomAnchor.constraint(
                equalTo: topCard.bottomAnchor,
                constant: -4
            ),
            bottomStatsStack.heightAnchor.constraint(equalToConstant: 24),
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
        label.font = .systemFont(ofSize: 14, weight: .medium)
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
                stack.trailingAnchor.constraint(
                    equalTo: container.trailingAnchor
                )
            ])
        }

        return container
    }

    private func setupVitals() {

        [
            createRow(left: bloodGlucoseCard, right: bloodPressureCard),
            createRow(left: ecgCard, right: sleepCard),
            createRow(left: heartRateCard, right: hrvCard),
            createRow(left: temperatureCard, right: bloodOxygenCard),
        ].forEach { gridStack.addArrangedSubview($0) }
    }

    private func createRow(left: UIView, right: UIView) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.spacing = 16
        row.distribution = .fillEqually
        return row
    }
    
    @objc private func openCalories() {
        let vc = CaloriesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupCardActions() {

        bloodGlucoseCard.onTap = { [weak self] in
            let vc = HealthVitalsViewController(vitalType: .bloodGlucose)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        bloodPressureCard.onTap = { [weak self] in
            let vc = HealthVitalsViewController(vitalType: .bloodPressure)
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        sleepCard.onTap = { [weak self] in
            let vc = SleepViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        heartRateCard.onTap = { [weak self] in
            // Using new generic HealthVitalsViewController for testing
            let vc = HealthVitalsViewController(vitalType: .heartRate)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        hrvCard.onTap = { [weak self] in
            let vc = HealthVitalsViewController(vitalType: .hrv)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        temperatureCard.onTap = { [weak self] in
            let vc = HealthVitalsViewController(vitalType: .temperature)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        bloodOxygenCard.onTap = { [weak self] in
            let vc = HealthVitalsViewController(vitalType: .bloodOxygen)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        
    }

    // MARK: - API
    private func fetchLatestHealthData() {

        let userId = UserDefaults.standard.integer(forKey: "id")
        guard userId > 0 else { return }

        // ✅ Fetch latest values from local database instead of API
        fetchLatestFromLocalDB()
        
        // 🔴 COMMENTED: Old API call for latest data
        /*
        HealthService.shared.getLastHealthData(userId: userId) {
            [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if case .success(let response) = result {
                    self.lastHealthResponse = response
                    self.applyHealthData(response)
                }
            }
        }
        */
    }
    
    // MARK: - Local Database Fetch
    private func fetchLatestFromLocalDB() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Fetch latest values from each repository
            let heartRateRepo = HeartRateRepository()
            let bpRepo = BloodPressureRepository()
            let hrvRepo = HrvRepository()
            let bloodOxygenRepo = BloodOxygenRepository()
            let bloodGlucoseRepo = BloodGlucoseRepository()
            let tempRepo = TemperatureRepository()
            let stepsRepo = StepsRepository()
            
            let latestHR = heartRateRepo.getLatestEntry()
            let latestBP = bpRepo.getLatestEntry()
            let latestHRV = hrvRepo.getLatestEntry()
            let latestO2 = bloodOxygenRepo.getLatestEntry()
            let latestGlucose = bloodGlucoseRepo.getLatestEntry()
            let latestTemp = tempRepo.getLatestEntry()
            
            // Fetch today's steps data
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let todaySteps = stepsRepo.getByDateRange(start: today, end: tomorrow)
            
            // Calculate today's totals
            let totalSteps = todaySteps.reduce(0) { $0 + Int($1.steps) }
            let totalCalories = todaySteps.reduce(0) { $0 + Int($1.calories) }
            let totalDistance = todaySteps.reduce(0) { $0 + Int($1.distance) }
            let distanceKm = Double(totalDistance) / 1000.0
            
            DispatchQueue.main.async {
                // Heart Rate
                if let hr = latestHR {
                    self.heartRateCard.updateValue("\(hr.bpm) times/min")
                } else {
                    self.heartRateCard.updateValue("-- times/min")
                }
                
                // Blood Pressure
                if let bp = latestBP {
                    self.bloodPressureCard.updateValue("\(bp.systolicValue)/\(bp.diastolicValue) mmHg")
                } else {
                    self.bloodPressureCard.updateValue("--/-- mmHg")
                }
                
                // HRV
                if let hrv = latestHRV {
                    self.hrvCard.updateValue("\(hrv.hrvValue) ms")
                } else {
                    self.hrvCard.updateValue("-- ms")
                }
                
                // Blood Oxygen
                if let o2 = latestO2 {
                    self.bloodOxygenCard.updateValue("\(o2.oxygenValue) %")
                } else {
                    self.bloodOxygenCard.updateValue("-- %")
                }
                
                // Blood Glucose
                if let glucose = latestGlucose {
                    self.bloodGlucoseCard.updateValue("\(glucose.glucoseValue) mg/dL")
                } else {
                    self.bloodGlucoseCard.updateValue("-- mg/dL")
                }
                
                // Temperature
                if let temp = latestTemp {
                    let tempValue = temp.temperatureValue
                    self.temperatureCard.updateValue(self.formatBodyTemperature(tempValue))
                } else {
                    self.temperatureCard.updateValue(self.formatBodyTemperature(nil))
                }
                
                // Update Steps, Calories, Distance
                self.updateStepStats(
                    steps: totalSteps,
                    calories: totalCalories,
                    distanceKm: distanceKm
                )
            }
        }
    }

    private func applyHealthData(_ response: GetLastUserHealthDataResponse) {

        let map = Dictionary(
            uniqueKeysWithValues: response.data.map { ($0.type, $0.value) }
        )

        bloodGlucoseCard.updateValue("\(map["blood_sugar"] ?? "--") mg/dL")
        bloodPressureCard.updateValue(map["blood_pressure"] ?? "--/-- mmHg")
        heartRateCard.updateValue("\(map["heart_rate"] ?? "--") times/min")
        bloodOxygenCard.updateValue("\(map["blood_oxygen"] ?? "--") %")
        hrvCard.updateValue("\(map["hrv"] ?? "--") times/min")
        
        let tempValue = Double(map["temperature"] ?? "")
        temperatureCard.updateValue(formatBodyTemperature(tempValue))
        
        // ---- STEPS / CALORIES / DISTANCE ----
            let steps = Int(map["steps"] ?? "0") ?? 0
            let calories = Int(map["calories"] ?? "0") ?? 0

            // simple distance formula (adjust later if needed)
            let distanceKm = Double(steps) * 0.0008

            updateStepStats(
                steps: steps,
                calories: calories,
                distanceKm: distanceKm
            )

        applySleepData()
    }
    
    private func formatBodyTemperature(_ value: Double?) -> String {

        let unit = AppSettingsManager.shared.getTemperatureUnit()

        guard let value = value, value > 0 else {
            return unit == .fahrenheit ? "--°F" : "--°C"
        }

        switch unit {
        case .celsius:
            return String(format: "%.1f°C", value)

        case .fahrenheit:
            let f = TemperatureConverter.celsiusToFahrenheit(value)
            return String(format: "%.1f°F", f)
        }
    }


    private func applySleepData() {

        let minutes = UserDefaults.standard.integer(
            forKey: "last_day_sleep_minutes"
        )
        guard minutes > 0 else {
            sleepCard.updateValue("--:--")
            return
        }

        sleepCard.updateValue("\(minutes / 60)h \(minutes % 60)m")
    }
    
    private func updateStepStats(
        steps: Int,
        calories: Int,
        distanceKm: Double
    ) {
        // Update circular progress
        stepProgress.setProgress(current: steps, total: 10000)

        // Update bottom stats labels
        updateBottomStat(index: 0, text: "\(calories) Kcal")
        updateBottomStat(index: 2, text: String(format: "%.2f km", distanceKm))
    }
    
    private func updateBottomStat(index: Int, text: String) {

        guard
            bottomStatsStack.arrangedSubviews.indices.contains(index),
            let container = bottomStatsStack.arrangedSubviews[index] as? UIView,
            let stack = container.subviews.first as? UIStackView,
            let label = stack.arrangedSubviews.last as? UILabel
        else { return }

        label.text = text
    }
    
    // MARK: - Profile Data Fetch
    private func fetchProfileIfNeeded() {
        // Check if profile data is already saved
        guard UserDefaultsManager.shared.profileName == nil || 
              UserDefaultsManager.shared.profileName?.isEmpty == true else {
            return
        }
        
        // Fetch profile data if not saved
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else { return }
        
        ProfileService.shared.getUserProfile(userId: userId) { result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    let data = response.data
                    let fullName = "\(data.first_name ?? "") \(data.last_name ?? "")".trimmingCharacters(in: .whitespaces)
                    
                    // Save to UserDefaults
                    UserDefaultsManager.shared.saveProfileData(name: fullName, photoUrl: data.patient_image_url ?? "")
                    
                    // Post notification to update side menu
                    NotificationCenter.default.post(
                        name: .profileDataLoaded,
                        object: nil,
                        userInfo: ["name": fullName, "imageUrl": data.patient_image_url ?? ""]
                    )
                }
            }
        }
    }
}

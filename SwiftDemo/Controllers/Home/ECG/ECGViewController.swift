import UIKit
import YCProductSDK

final class ECGViewController: AppBaseViewController {

    private let userId = UserDefaultsManager.shared.userId

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - ECG Measurement Card
    private let ecgMeasurementCard = UIView()
    private let cardTitleLabel = UILabel()
    private let cardDateLabel = UILabel()
    private let ecgGraphPlaceholder = UIView()
    private let graphInfoLabel = UILabel()
    
    // MARK: - Metrics Stack
    private let metricsStack = UIStackView()
    private let hrMetricView = UIView()
    private let bpMetricView = UIView()
    private let hrvMetricView = UIView()
    
    private let hrTitleLabel = UILabel()
    private let hrValueLabel = UILabel()
    private let bpTitleLabel = UILabel()
    private let bpValueLabel = UILabel()
    private let hrvTitleLabel = UILabel()
    private let hrvValueLabel = UILabel()
    
    // MARK: - Start Measurement Button
    private let startMeasurementButton = UIButton(type: .system)
    
    // MARK: - Trend & History Cards
    private let trendTrackingCard = UIView()
    private let trendIconView = UIView()
    private let trendTitleLabel = UILabel()
    private let trendArrowImageView = UIImageView()
    
    private let historyCard = UIView()
    private let historyIconView = UIView()
    private let historyTitleLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setScreenTitle("ECG")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)

        setupUI()
        loadLatestECGData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLatestECGData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Scroll
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

        setupECGMeasurementCard()
        setupStartMeasurementButton()
        setupTrendTrackingCard()
        setupHistoryCard()
    }

    private func setupECGMeasurementCard() {
        ecgMeasurementCard.backgroundColor = .white
        ecgMeasurementCard.layer.cornerRadius = 12
        ecgMeasurementCard.layer.shadowColor = UIColor.black.cgColor
        ecgMeasurementCard.layer.shadowOpacity = 0.1
        ecgMeasurementCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        ecgMeasurementCard.layer.shadowRadius = 4
        ecgMeasurementCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ecgMeasurementCard)

        // Card Title
        cardTitleLabel.text = "ECG Measurement"
        cardTitleLabel.font = .boldSystemFont(ofSize: 16)
        cardTitleLabel.textColor = .black
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        ecgMeasurementCard.addSubview(cardTitleLabel)

        // Card Date
        cardDateLabel.text = ""
        cardDateLabel.font = .systemFont(ofSize: 12)
        cardDateLabel.textColor = .lightGray
        cardDateLabel.translatesAutoresizingMaskIntoConstraints = false
        ecgMeasurementCard.addSubview(cardDateLabel)

        // ECG Graph Placeholder
        ecgGraphPlaceholder.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        ecgGraphPlaceholder.layer.cornerRadius = 8
        ecgGraphPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        ecgMeasurementCard.addSubview(ecgGraphPlaceholder)

        // Graph Info Label
        graphInfoLabel.text = "Gain: 10mm/mv Speed: 25mm/s Lead I"
        graphInfoLabel.font = .systemFont(ofSize: 10)
        graphInfoLabel.textColor = .darkGray
        graphInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        ecgMeasurementCard.addSubview(graphInfoLabel)

        // Metrics Stack
        metricsStack.axis = .horizontal
        metricsStack.spacing = 16
        metricsStack.distribution = .fillEqually
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        ecgMeasurementCard.addSubview(metricsStack)

        // HR Metric
        setupMetricView(
            containerView: hrMetricView,
            titleLabel: hrTitleLabel,
            valueLabel: hrValueLabel,
            title: "HR (bpm)",
            value: "77"
        )

        // BP Metric
        setupMetricView(
            containerView: bpMetricView,
            titleLabel: bpTitleLabel,
            valueLabel: bpValueLabel,
            title: "BP (mmHg)",
            value: "105/69"
        )

        // HRV Metric
        setupMetricView(
            containerView: hrvMetricView,
            titleLabel: hrvTitleLabel,
            valueLabel: hrvValueLabel,
            title: "HRV (ms)",
            value: "0"
        )

        metricsStack.addArrangedSubview(hrMetricView)
        metricsStack.addArrangedSubview(bpMetricView)
        metricsStack.addArrangedSubview(hrvMetricView)

        NSLayoutConstraint.activate([
            ecgMeasurementCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            ecgMeasurementCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ecgMeasurementCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            cardTitleLabel.topAnchor.constraint(equalTo: ecgMeasurementCard.topAnchor, constant: 16),
            cardTitleLabel.leadingAnchor.constraint(equalTo: ecgMeasurementCard.leadingAnchor, constant: 16),

            cardDateLabel.centerYAnchor.constraint(equalTo: cardTitleLabel.centerYAnchor),
            cardDateLabel.trailingAnchor.constraint(equalTo: ecgMeasurementCard.trailingAnchor, constant: -16),

            ecgGraphPlaceholder.topAnchor.constraint(equalTo: cardTitleLabel.bottomAnchor, constant: 12),
            ecgGraphPlaceholder.leadingAnchor.constraint(equalTo: ecgMeasurementCard.leadingAnchor, constant: 16),
            ecgGraphPlaceholder.trailingAnchor.constraint(equalTo: ecgMeasurementCard.trailingAnchor, constant: -16),
            ecgGraphPlaceholder.heightAnchor.constraint(equalToConstant: 120),

            graphInfoLabel.topAnchor.constraint(equalTo: ecgGraphPlaceholder.bottomAnchor, constant: 8),
            graphInfoLabel.leadingAnchor.constraint(equalTo: ecgGraphPlaceholder.leadingAnchor),

            metricsStack.topAnchor.constraint(equalTo: graphInfoLabel.bottomAnchor, constant: 16),
            metricsStack.leadingAnchor.constraint(equalTo: ecgMeasurementCard.leadingAnchor, constant: 16),
            metricsStack.trailingAnchor.constraint(equalTo: ecgMeasurementCard.trailingAnchor, constant: -16),
            metricsStack.heightAnchor.constraint(equalToConstant: 50),
            metricsStack.bottomAnchor.constraint(equalTo: ecgMeasurementCard.bottomAnchor, constant: -16)
        ])
    }

    private func setupMetricView(containerView: UIView, titleLabel: UILabel, valueLabel: UILabel, title: String, value: String) {
        containerView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .gray
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textColor = .black
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func setupStartMeasurementButton() {
        startMeasurementButton.setTitle("Start ECG Measurement", for: .normal)
        startMeasurementButton.setTitleColor(.white, for: .normal)
        startMeasurementButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        startMeasurementButton.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        startMeasurementButton.layer.cornerRadius = 25
        startMeasurementButton.translatesAutoresizingMaskIntoConstraints = false
        startMeasurementButton.addTarget(self, action: #selector(startMeasurementTapped), for: .touchUpInside)
        contentView.addSubview(startMeasurementButton)

        NSLayoutConstraint.activate([
            startMeasurementButton.topAnchor.constraint(equalTo: ecgMeasurementCard.bottomAnchor, constant: 24),
            startMeasurementButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            startMeasurementButton.widthAnchor.constraint(equalToConstant: 280),
            startMeasurementButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupTrendTrackingCard() {
        trendTrackingCard.backgroundColor = .white
        trendTrackingCard.layer.cornerRadius = 12
        trendTrackingCard.layer.shadowColor = UIColor.black.cgColor
        trendTrackingCard.layer.shadowOpacity = 0.1
        trendTrackingCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        trendTrackingCard.layer.shadowRadius = 4
        trendTrackingCard.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trendTrackingTapped))
        trendTrackingCard.addGestureRecognizer(tapGesture)
        
        contentView.addSubview(trendTrackingCard)

        // Icon View
        trendIconView.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 0.2)
        trendIconView.layer.cornerRadius = 20
        trendIconView.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.addSubview(trendIconView)
        
        // Add chart icon
        let iconImageView = UIImageView(image: UIImage(systemName: "chart.line.uptrend.xyaxis"))
        iconImageView.tintColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        trendIconView.addSubview(iconImageView)

        // Title
        trendTitleLabel.text = "ECG Trend Tracking"
        trendTitleLabel.font = .systemFont(ofSize: 15)
        trendTitleLabel.textColor = .black
        trendTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.addSubview(trendTitleLabel)

        // Arrow
        trendArrowImageView.image = UIImage(systemName: "chevron.right")
        trendArrowImageView.tintColor = .lightGray
        trendArrowImageView.contentMode = .scaleAspectFit
        trendArrowImageView.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.addSubview(trendArrowImageView)

        NSLayoutConstraint.activate([
            trendTrackingCard.topAnchor.constraint(equalTo: startMeasurementButton.bottomAnchor, constant: 24),
            trendTrackingCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            trendTrackingCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            trendTrackingCard.heightAnchor.constraint(equalToConstant: 70),

            trendIconView.centerYAnchor.constraint(equalTo: trendTrackingCard.centerYAnchor),
            trendIconView.leadingAnchor.constraint(equalTo: trendTrackingCard.leadingAnchor, constant: 16),
            trendIconView.widthAnchor.constraint(equalToConstant: 40),
            trendIconView.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: trendIconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: trendIconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            trendTitleLabel.centerYAnchor.constraint(equalTo: trendTrackingCard.centerYAnchor),
            trendTitleLabel.leadingAnchor.constraint(equalTo: trendIconView.trailingAnchor, constant: 12),

            trendArrowImageView.centerYAnchor.constraint(equalTo: trendTrackingCard.centerYAnchor),
            trendArrowImageView.trailingAnchor.constraint(equalTo: trendTrackingCard.trailingAnchor, constant: -16),
            trendArrowImageView.widthAnchor.constraint(equalToConstant: 16),
            trendArrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func setupHistoryCard() {
        historyCard.backgroundColor = .white
        historyCard.layer.cornerRadius = 12
        historyCard.layer.shadowColor = UIColor.black.cgColor
        historyCard.layer.shadowOpacity = 0.1
        historyCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        historyCard.layer.shadowRadius = 4
        historyCard.translatesAutoresizingMaskIntoConstraints = false
        historyCard.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(historyTapped))
        historyCard.addGestureRecognizer(tapGesture)
        
        contentView.addSubview(historyCard)

        // Icon View
        historyIconView.backgroundColor = UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 0.2)
        historyIconView.layer.cornerRadius = 20
        historyIconView.translatesAutoresizingMaskIntoConstraints = false
        historyCard.addSubview(historyIconView)
        
        // Add clock icon
        let iconImageView = UIImageView(image: UIImage(systemName: "clock"))
        iconImageView.tintColor = UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        historyIconView.addSubview(iconImageView)

        // Title
        historyTitleLabel.text = "ECG History"
        historyTitleLabel.font = .systemFont(ofSize: 15)
        historyTitleLabel.textColor = .black
        historyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        historyCard.addSubview(historyTitleLabel)

        NSLayoutConstraint.activate([
            historyCard.topAnchor.constraint(equalTo: trendTrackingCard.bottomAnchor, constant: 16),
            historyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            historyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            historyCard.heightAnchor.constraint(equalToConstant: 70),
            historyCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            historyIconView.centerYAnchor.constraint(equalTo: historyCard.centerYAnchor),
            historyIconView.leadingAnchor.constraint(equalTo: historyCard.leadingAnchor, constant: 16),
            historyIconView.widthAnchor.constraint(equalToConstant: 40),
            historyIconView.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: historyIconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: historyIconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            historyTitleLabel.centerYAnchor.constraint(equalTo: historyCard.centerYAnchor),
            historyTitleLabel.leadingAnchor.constraint(equalTo: historyIconView.trailingAnchor, constant: 12)
        ])
    }

    // MARK: - Data Loading
    private func loadLatestECGData() {
        // TODO: Load latest ECG data from local DB
        // For now, display placeholder values matching screenshot
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        cardDateLabel.text = dateFormatter.string(from: Date())
        
        // Default values from screenshot
        hrValueLabel.text = "77"
        bpValueLabel.text = "105/69"
        hrvValueLabel.text = "0"
    }

    // MARK: - Actions
    @objc private func startMeasurementTapped() {
        // Navigate to ECG measurement screen
        print("🟢 Start ECG Measurement tapped")
        let vc = ECGMeasureViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func trendTrackingTapped() {
        // TODO: Navigate to ECG trend tracking screen
        print("📊 ECG Trend Tracking tapped")
        Toast.show(message: "ECG Trend Tracking coming soon", in: self.view)
    }

    @objc private func historyTapped() {
        // TODO: Navigate to ECG history screen
        print("🕐 ECG History tapped")
        Toast.show(message: "ECG History coming soon", in: self.view)
    }
}

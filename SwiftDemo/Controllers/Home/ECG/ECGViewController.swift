import UIKit
import YCProductSDK

final class ECGViewController: AppBaseViewController {

    private let userId = UserDefaultsManager.shared.userId
    private let ecgRepository = ECGRecordRepository()
    private let CELL_SIZE: CGFloat = 6.25

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - ECG Card (waveform + summary as one card)
    private let ecgCard = UIView()

    // Waveform area (white)
    private let ecgScrollView = UIScrollView()
    private let ecgLineView = YCECGDrawLineView()
    private let graphInfoLabel = UILabel()

    // Summary area (light green)
    private let summaryArea = UIView()
    private let reportTitleLabel = UILabel()   // "ECG AI Report"
    private let cardDateLabel = UILabel()       // "2026.04.26 09:44"
    private let statusLabel = UILabel()         // "Normal ECG"
    private let toresValueLabel = UILabel()     // "14"
    private let toresUnitLabel = UILabel()      // "tores"

    // Metric cards
    private let metricsStack = UIStackView()
    private let hrCard = UIView()
    private let bpCard = UIView()
    private let hrvCard = UIView()
    private let hrValueLabel = UILabel()
    private let bpValueLabel = UILabel()
    private let hrvValueLabel = UILabel()

    // MARK: - Start Measurement Button
    private let startMeasurementButton = UIButton(type: .system)

    // MARK: - Page Title
    private let pageTitleLabel = UILabel()

    // MARK: - Trend & History Cards
    private let trendTrackingCard = UIView()
    private let historyCard = UIView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

        setupUI()
        loadLatestECGData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkDeviceConnection()
        loadLatestECGData()
    }

    // MARK: - UI Setup
    private func setupUI() {
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

        setupPageTitle()
        setupECGCard()
        setupStartMeasurementButton()
        setupTrendTrackingCard()
        setupHistoryCard()
    }

    // MARK: - Page Title
    private func setupPageTitle() {
        pageTitleLabel.text = "ECG Details"
        pageTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        pageTitleLabel.textColor = UIColor(white: 0.08, alpha: 1)
        pageTitleLabel.textAlignment = .center
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageTitleLabel)

        NSLayoutConstraint.activate([
            pageTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            pageTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pageTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - ECG Card (waveform + summary)
    private func setupECGCard() {
        ecgCard.backgroundColor = .white
        ecgCard.layer.cornerRadius = 16
        ecgCard.clipsToBounds = true
        ecgCard.layer.shadowColor = UIColor.black.cgColor
        ecgCard.layer.shadowOpacity = 0.08
        ecgCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        ecgCard.layer.shadowRadius = 6
        ecgCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ecgCard)

        // ── Waveform area ──────────────────────────────
        ecgScrollView.translatesAutoresizingMaskIntoConstraints = false
        ecgScrollView.showsHorizontalScrollIndicator = false
        ecgScrollView.backgroundColor = .white
        ecgCard.addSubview(ecgScrollView)

        ecgLineView.backgroundColor = .white
        ecgLineView.drawReferenceWaveformStype = .top
        ecgScrollView.addSubview(ecgLineView)

        graphInfoLabel.text = "Gain: 10mm/mv Speed: 25mm/s Lead I"
        graphInfoLabel.font = .systemFont(ofSize: 10)
        graphInfoLabel.textColor = UIColor(white: 0.4, alpha: 1)
        graphInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        ecgCard.addSubview(graphInfoLabel)

        // ── Summary area (light green) ─────────────────
        summaryArea.backgroundColor = UIColor(red: 203/255, green: 245/255, blue: 221/255, alpha: 1)
        summaryArea.translatesAutoresizingMaskIntoConstraints = false
        ecgCard.addSubview(summaryArea)

        // Row 1: "ECG AI Report" + date
        reportTitleLabel.text = "ECG AI Report"
        reportTitleLabel.font = .boldSystemFont(ofSize: 14)
        reportTitleLabel.textColor = .black
        reportTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryArea.addSubview(reportTitleLabel)

        cardDateLabel.text = ""
        cardDateLabel.font = .systemFont(ofSize: 12)
        cardDateLabel.textColor = UIColor(white: 0.4, alpha: 1)
        cardDateLabel.textAlignment = .right
        cardDateLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryArea.addSubview(cardDateLabel)

        // Row 2: status + tores
        statusLabel.text = "--"
        statusLabel.font = .boldSystemFont(ofSize: 16)
        statusLabel.textColor = .black
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryArea.addSubview(statusLabel)

        toresValueLabel.text = "--"
        toresValueLabel.font = .boldSystemFont(ofSize: 26)
        toresValueLabel.textColor = .black
        toresValueLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryArea.addSubview(toresValueLabel)

        toresUnitLabel.text = "tores"
        toresUnitLabel.font = .systemFont(ofSize: 13)
        toresUnitLabel.textColor = UIColor(white: 0.35, alpha: 1)
        toresUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryArea.addSubview(toresUnitLabel)

        // Row 3: metric cards
        metricsStack.axis = .horizontal
        metricsStack.spacing = 8
        metricsStack.distribution = .fillEqually
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        summaryArea.addSubview(metricsStack)

        metricsStack.addArrangedSubview(buildMetricCard(
            icon: "❤️", label: "HR", valueLabel: hrValueLabel, unit: "bpm"))
        metricsStack.addArrangedSubview(buildMetricCard(
            icon: "🩺", label: "BP", valueLabel: bpValueLabel, unit: "mmHg"))
        metricsStack.addArrangedSubview(buildMetricCard(
            icon: "~", label: "HRV", valueLabel: hrvValueLabel, unit: "ms"))

        // ── Constraints ────────────────────────────────
        NSLayoutConstraint.activate([
            // Card
            ecgCard.topAnchor.constraint(equalTo: pageTitleLabel.bottomAnchor, constant: 12),
            ecgCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            ecgCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            // Waveform scroll
            ecgScrollView.topAnchor.constraint(equalTo: ecgCard.topAnchor),
            ecgScrollView.leadingAnchor.constraint(equalTo: ecgCard.leadingAnchor),
            ecgScrollView.trailingAnchor.constraint(equalTo: ecgCard.trailingAnchor),
            ecgScrollView.heightAnchor.constraint(equalToConstant: 180),

            // Graph info label (bottom-left inside waveform area)
            graphInfoLabel.bottomAnchor.constraint(equalTo: ecgScrollView.bottomAnchor, constant: -6),
            graphInfoLabel.leadingAnchor.constraint(equalTo: ecgCard.leadingAnchor, constant: 8),

            // Summary area
            summaryArea.topAnchor.constraint(equalTo: ecgScrollView.bottomAnchor),
            summaryArea.leadingAnchor.constraint(equalTo: ecgCard.leadingAnchor),
            summaryArea.trailingAnchor.constraint(equalTo: ecgCard.trailingAnchor),
            summaryArea.bottomAnchor.constraint(equalTo: ecgCard.bottomAnchor),

            // Row 1
            reportTitleLabel.topAnchor.constraint(equalTo: summaryArea.topAnchor, constant: 12),
            reportTitleLabel.leadingAnchor.constraint(equalTo: summaryArea.leadingAnchor, constant: 14),
            cardDateLabel.centerYAnchor.constraint(equalTo: reportTitleLabel.centerYAnchor),
            cardDateLabel.trailingAnchor.constraint(equalTo: summaryArea.trailingAnchor, constant: -14),
            cardDateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: reportTitleLabel.trailingAnchor, constant: 8),

            // Row 2
            statusLabel.topAnchor.constraint(equalTo: reportTitleLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: summaryArea.leadingAnchor, constant: 14),

            toresValueLabel.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            toresValueLabel.trailingAnchor.constraint(equalTo: toresUnitLabel.leadingAnchor, constant: -4),
            toresUnitLabel.centerYAnchor.constraint(equalTo: toresValueLabel.centerYAnchor, constant: 4),
            toresUnitLabel.trailingAnchor.constraint(equalTo: summaryArea.trailingAnchor, constant: -14),

            // Row 3 - metrics
            metricsStack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            metricsStack.leadingAnchor.constraint(equalTo: summaryArea.leadingAnchor, constant: 14),
            metricsStack.trailingAnchor.constraint(equalTo: summaryArea.trailingAnchor, constant: -14),
            metricsStack.heightAnchor.constraint(equalToConstant: 72),
            metricsStack.bottomAnchor.constraint(equalTo: summaryArea.bottomAnchor, constant: -14),
        ])
    }

    private func buildMetricCard(icon: String, label: String, valueLabel: UILabel, unit: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor(white: 0.82, alpha: 1).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = UILabel()
        headerLabel.text = "\(icon) \(label)"
        headerLabel.font = .systemFont(ofSize: 11)
        headerLabel.textColor = UIColor(white: 0.35, alpha: 1)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(headerLabel)

        valueLabel.text = "--"
        valueLabel.font = .boldSystemFont(ofSize: 20)
        valueLabel.textColor = .black
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(valueLabel)

        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = .systemFont(ofSize: 10)
        unitLabel.textColor = UIColor(white: 0.5, alpha: 1)
        unitLabel.textAlignment = .center
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(unitLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            headerLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            valueLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            unitLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            unitLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            unitLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            unitLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -6),
        ])
        return card
    }

    private func setupStartMeasurementButton() {
        startMeasurementButton.setTitle("Start ECG Measurement", for: .normal)
        startMeasurementButton.setTitleColor(.white, for: .normal)
        startMeasurementButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        startMeasurementButton.backgroundColor = UIColor(red: 62/255, green: 207/255, blue: 160/255, alpha: 1)
        startMeasurementButton.layer.cornerRadius = 25
        startMeasurementButton.translatesAutoresizingMaskIntoConstraints = false
        startMeasurementButton.addTarget(self, action: #selector(startMeasurementTapped), for: .touchUpInside)
        contentView.addSubview(startMeasurementButton)

        NSLayoutConstraint.activate([
            startMeasurementButton.topAnchor.constraint(equalTo: ecgCard.bottomAnchor, constant: 20),
            startMeasurementButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            startMeasurementButton.widthAnchor.constraint(equalToConstant: 280),
            startMeasurementButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupTrendTrackingCard() {
        trendTrackingCard.backgroundColor = .white
        trendTrackingCard.layer.cornerRadius = 16
        trendTrackingCard.layer.shadowColor = UIColor.black.cgColor
        trendTrackingCard.layer.shadowOpacity = 0.06
        trendTrackingCard.layer.shadowOffset = CGSize(width: 0, height: 1)
        trendTrackingCard.layer.shadowRadius = 4
        trendTrackingCard.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.isUserInteractionEnabled = true
        trendTrackingCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(trendTrackingTapped)))
        contentView.addSubview(trendTrackingCard)

        let iconView = UIImageView(image: UIImage(systemName: "chart.pie.fill"))
        iconView.tintColor = UIColor(red: 62/255, green: 120/255, blue: 200/255, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = "ECG Trend Tracking"
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.addSubview(titleLabel)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(white: 0.7, alpha: 1)
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        trendTrackingCard.addSubview(arrow)

        NSLayoutConstraint.activate([
            trendTrackingCard.topAnchor.constraint(equalTo: startMeasurementButton.bottomAnchor, constant: 20),
            trendTrackingCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            trendTrackingCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            trendTrackingCard.heightAnchor.constraint(equalToConstant: 64),
            iconView.centerYAnchor.constraint(equalTo: trendTrackingCard.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: trendTrackingCard.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: trendTrackingCard.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            arrow.centerYAnchor.constraint(equalTo: trendTrackingCard.centerYAnchor),
            arrow.trailingAnchor.constraint(equalTo: trendTrackingCard.trailingAnchor, constant: -16),
            arrow.widthAnchor.constraint(equalToConstant: 14),
            arrow.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    private func setupHistoryCard() {
        historyCard.backgroundColor = .white
        historyCard.layer.cornerRadius = 16
        historyCard.layer.shadowColor = UIColor.black.cgColor
        historyCard.layer.shadowOpacity = 0.06
        historyCard.layer.shadowOffset = CGSize(width: 0, height: 1)
        historyCard.layer.shadowRadius = 4
        historyCard.translatesAutoresizingMaskIntoConstraints = false
        historyCard.isUserInteractionEnabled = true
        historyCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(historyTapped)))
        contentView.addSubview(historyCard)

        let iconView = UIImageView(image: UIImage(systemName: "clock"))
        iconView.tintColor = UIColor(white: 0.45, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        historyCard.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = "ECG History"
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        historyCard.addSubview(titleLabel)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(white: 0.7, alpha: 1)
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        historyCard.addSubview(arrow)

        NSLayoutConstraint.activate([
            historyCard.topAnchor.constraint(equalTo: trendTrackingCard.bottomAnchor, constant: 12),
            historyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            historyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            historyCard.heightAnchor.constraint(equalToConstant: 64),
            historyCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            iconView.centerYAnchor.constraint(equalTo: historyCard.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: historyCard.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: historyCard.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            arrow.centerYAnchor.constraint(equalTo: historyCard.centerYAnchor),
            arrow.trailingAnchor.constraint(equalTo: historyCard.trailingAnchor, constant: -16),
            arrow.widthAnchor.constraint(equalToConstant: 14),
            arrow.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    // MARK: - Data Loading
    private func loadLatestECGData() {
        ecgRepository.fetchAllRecords { [weak self] records in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard let latestRecord = records.first else {
                    self.showPlaceholderData()
                    return
                }

                // Date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = dateFormatter.date(from: latestRecord.timestamp) {
                    dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
                    self.cardDateLabel.text = dateFormatter.string(from: date)
                }

                // Status + tores
                let score = HealthScoreCalculator.ecgScore(from: latestRecord)
                let status = HealthScoreCalculator.ecgStatusText(
                    isAfib: latestRecord.isAfib,
                    diagnoseType: latestRecord.diagnoseType,
                    heartRate: latestRecord.heartRate,
                    hrv: latestRecord.hrv)
                self.statusLabel.text = status
                self.toresValueLabel.text = score > 0 ? "\(score)" : "--"
                self.summaryArea.backgroundColor = self.summaryColor(for: status)

                // Vitals
                self.hrValueLabel.text  = latestRecord.heartRate > 0 ? "\(latestRecord.heartRate)" : "--"
                self.bpValueLabel.text  = latestRecord.sbp > 0 ? "\(latestRecord.sbp)/\(latestRecord.dbp)" : "--"
                self.hrvValueLabel.text = latestRecord.hrv > 0 ? "\(latestRecord.hrv)" : "--"

                // Waveform
                if !latestRecord.ecgList.isEmpty {
                    self.renderECGChart(ecgData: latestRecord.ecgList)
                }
            }
        }
    }

    private func showPlaceholderData() {
        cardDateLabel.text = "--"
        statusLabel.text = "--"
        toresValueLabel.text = "--"
        hrValueLabel.text  = "--"
        bpValueLabel.text  = "--"
        hrvValueLabel.text = "--"
        graphInfoLabel.text = "Gain: 10mm/mv Speed: 25mm/s Lead I"
        summaryArea.backgroundColor = UIColor(red: 203/255, green: 245/255, blue: 221/255, alpha: 1)
        ecgLineView.datas.removeAllObjects()
        ecgLineView.setNeedsDisplay()
    }

    private func summaryColor(for status: String) -> UIColor {
        switch status {
        case "Normal ECG":
            return UIColor(red: 203/255, green: 245/255, blue: 221/255, alpha: 1) // light green
        case "Atrial Fibrillation", "Ventricular Premature", "Atrial Premature":
            return UIColor(red: 255/255, green: 220/255, blue: 220/255, alpha: 1) // light red
        default: // Sinus Arrhythmia, Bradycardia, Tachycardia
            return UIColor(red: 255/255, green: 235/255, blue: 195/255, alpha: 1) // light orange
        }
    }

    private func renderECGChart(ecgData: [Int]) {
        let dataArray = NSMutableArray()
        for value in ecgData { dataArray.add(NSNumber(value: value)) }

        let pointWidth = CELL_SIZE * 0.3
        let screenWidth = UIScreen.main.bounds.width - 24
        let totalWidth = max(screenWidth, CGFloat(ecgData.count) * pointWidth)

        ecgLineView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: 180)
        ecgScrollView.contentSize = CGSize(width: totalWidth, height: 180)
        ecgLineView.datas = dataArray
        ecgLineView.setNeedsDisplay()
    }

    // MARK: - Device Connection
    private func checkDeviceConnection() {
        let isConnected = BLEStateManager.shared.isConnected
        print(isConnected ? "✅ ECG: Device connected" : "🔴 ECG: Device not connected")
    }

    // MARK: - Actions
    @objc private func startMeasurementTapped() {
        let connected = BLEStateManager.shared.hasConnectedDevice() || BLEStateManager.shared.isConnected
        if !connected {
            Toast.show(message: "Device not connected", in: self.view)
            return
        }
        let vc = ECGMeasureViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func trendTrackingTapped() {
        let vc = ECGTrendTrackingViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func historyTapped() {
        let vc = ECGHistoryViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

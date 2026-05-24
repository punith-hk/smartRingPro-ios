import UIKit
import YCProductSDK

final class ECGDetailViewController: AppBaseViewController {
    
    var ecgRecord: ECGRecord!
    private let CELL_SIZE: CGFloat = 6.25
    private let ecgRepository = ECGRecordRepository()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let pageTitleLabel = UILabel()
    
    // Info Card Components
    private let infoCard    = UIView()
    private let accentBar   = UIView()
    private let dateLabel   = UILabel()
    private let syncBadgeLabel = UILabel()
    private let syncButton  = UIButton(type: .system)
    private let diagnosisLabel = UILabel()
    private let toresValueLabel = UILabel()
    private let toresTitleLabel = UILabel()
    
    // Metrics in info card
    private let hrLabel  = UILabel()
    private let bpLabel  = UILabel()
    private let hrvLabel = UILabel()
    
    // ECG Waveform Card
    private let ecgCard       = UIView()
    private let ecgScrollView = UIScrollView()
    private let ecgLineView   = YCECGDrawLineView()
    private let graphInfoLabel = UILabel()
    
    // View Report Button (below waveform)
    private let reportButton    = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("ECG Detail")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        
        setupUI()
        displayECGData()
    }
    
    private func setupUI() {
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Page Title
        pageTitleLabel.text = "ECG Report Details"
        pageTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        pageTitleLabel.textColor = UIColor(white: 0.08, alpha: 1)
        pageTitleLabel.textAlignment = .center
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageTitleLabel)
        infoCard.backgroundColor = .white
        infoCard.layer.cornerRadius = 14
        infoCard.layer.shadowColor = UIColor.black.cgColor
        infoCard.layer.shadowOpacity = 0.08
        infoCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        infoCard.layer.shadowRadius = 6
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCard)
        
        setupInfoCard()
        
        // ECG Card
        ecgCard.backgroundColor = .white
        ecgCard.layer.cornerRadius = 14
        ecgCard.layer.shadowColor = UIColor.black.cgColor
        ecgCard.layer.shadowOpacity = 0.08
        ecgCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        ecgCard.layer.shadowRadius = 6
        ecgCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ecgCard)
        
        setupECGCard()
        
        // View Report Button (below ECG card)
        reportButton.setTitle("View AI Report", for: .normal)
        reportButton.setImage(UIImage(systemName: "waveform.path.ecg"), for: .normal)
        reportButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        reportButton.tintColor = .white
        reportButton.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        reportButton.layer.cornerRadius = 14
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        reportButton.addTarget(self, action: #selector(viewReportButtonTapped), for: .touchUpInside)
        reportButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        contentView.addSubview(reportButton)
        
        // Loading Indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        reportButton.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            pageTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            pageTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pageTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            infoCard.topAnchor.constraint(equalTo: pageTitleLabel.bottomAnchor, constant: 12),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ecgCard.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 16),
            ecgCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ecgCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            reportButton.topAnchor.constraint(equalTo: ecgCard.bottomAnchor, constant: 16),
            reportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            reportButton.heightAnchor.constraint(equalToConstant: 50),
            reportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: reportButton.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: reportButton.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupInfoCard() {
        // Accent bar
        accentBar.layer.cornerRadius = 3
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(accentBar)
        
        // Date Label
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(dateLabel)
        
        // Sync badge label (read-only status)
        syncBadgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        syncBadgeLabel.layer.cornerRadius = 6
        syncBadgeLabel.layer.masksToBounds = true
        syncBadgeLabel.textAlignment = .center
        syncBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(syncBadgeLabel)
        
        // Sync Button (upload action)
        syncButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill"), for: .normal)
        syncButton.tintColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        syncButton.translatesAutoresizingMaskIntoConstraints = false
        syncButton.addTarget(self, action: #selector(syncButtonTapped), for: .touchUpInside)
        infoCard.addSubview(syncButton)
        
        // Diagnosis Label
        diagnosisLabel.font = .systemFont(ofSize: 17, weight: .bold)
        diagnosisLabel.numberOfLines = 2
        diagnosisLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(diagnosisLabel)
        
        // Tores score (right side)
        toresValueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        toresValueLabel.textColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        toresValueLabel.textAlignment = .center
        toresValueLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(toresValueLabel)
        
        toresTitleLabel.text = "tores"
        toresTitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        toresTitleLabel.textColor = .secondaryLabel
        toresTitleLabel.textAlignment = .center
        toresTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(toresTitleLabel)
        
        // Separator
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.92, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(separator)
        
        // Metrics Stack (HR | BP | HRV)
        let metricsStack = UIStackView(arrangedSubviews: [
            createMetricView(label: hrLabel,  title: "Heart Rate"),
            createMetricView(label: bpLabel,  title: "Blood Pressure"),
            createMetricView(label: hrvLabel, title: "HRV")
        ])
        metricsStack.axis = .horizontal
        metricsStack.spacing = 8
        metricsStack.distribution = .fillEqually
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(metricsStack)
        
        NSLayoutConstraint.activate([
            accentBar.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 14),
            accentBar.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -14),
            accentBar.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            accentBar.widthAnchor.constraint(equalToConstant: 4),
            
            toresValueLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            toresValueLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            toresValueLabel.widthAnchor.constraint(equalToConstant: 48),
            
            toresTitleLabel.topAnchor.constraint(equalTo: toresValueLabel.bottomAnchor, constant: 2),
            toresTitleLabel.centerXAnchor.constraint(equalTo: toresValueLabel.centerXAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: syncBadgeLabel.leadingAnchor, constant: -8),
            
            syncBadgeLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            syncBadgeLabel.trailingAnchor.constraint(equalTo: syncButton.leadingAnchor, constant: -4),
            syncBadgeLabel.heightAnchor.constraint(equalToConstant: 18),
            syncBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),
            
            syncButton.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            syncButton.trailingAnchor.constraint(equalTo: toresValueLabel.leadingAnchor, constant: -8),
            syncButton.widthAnchor.constraint(equalToConstant: 28),
            syncButton.heightAnchor.constraint(equalToConstant: 28),
            
            diagnosisLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            diagnosisLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            diagnosisLabel.trailingAnchor.constraint(equalTo: toresValueLabel.leadingAnchor, constant: -8),
            
            separator.topAnchor.constraint(equalTo: diagnosisLabel.bottomAnchor, constant: 14),
            separator.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            separator.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            metricsStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 14),
            metricsStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            metricsStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            metricsStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func createMetricView(label: UILabel, title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        container.layer.cornerRadius = 10

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = UIColor(white: 0.08, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),

            label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }
    
    private func setupECGCard() {
        let titleLabel = UILabel()
        titleLabel.text = "ECG Waveform"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        ecgCard.addSubview(titleLabel)
        
        // ECG Scroll View
        ecgScrollView.translatesAutoresizingMaskIntoConstraints = false
        ecgScrollView.showsHorizontalScrollIndicator = true
        ecgScrollView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        ecgScrollView.layer.cornerRadius = 8
        ecgCard.addSubview(ecgScrollView)
        
        // ECG Line View
        ecgLineView.backgroundColor = .clear
        ecgLineView.drawReferenceWaveformStype = .top
        ecgScrollView.addSubview(ecgLineView)
        
        // Graph Info Label
        graphInfoLabel.text = "Gain: 10mm/mv Speed: 25mm/s Lead I"
        graphInfoLabel.font = .systemFont(ofSize: 10)
        graphInfoLabel.textColor = .darkGray
        graphInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        ecgCard.addSubview(graphInfoLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: ecgCard.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: ecgCard.leadingAnchor, constant: 16),
            
            ecgScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            ecgScrollView.leadingAnchor.constraint(equalTo: ecgCard.leadingAnchor, constant: 16),
            ecgScrollView.trailingAnchor.constraint(equalTo: ecgCard.trailingAnchor, constant: -16),
            ecgScrollView.heightAnchor.constraint(equalToConstant: 200),
            
            graphInfoLabel.topAnchor.constraint(equalTo: ecgScrollView.bottomAnchor, constant: 8),
            graphInfoLabel.leadingAnchor.constraint(equalTo: ecgCard.leadingAnchor, constant: 16),
            graphInfoLabel.bottomAnchor.constraint(equalTo: ecgCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func displayECGData() {
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: ecgRecord.timestamp) {
            dateFormatter.dateFormat = "MMM dd, yyyy  HH:mm"
            dateLabel.text = dateFormatter.string(from: date)
        } else {
            dateLabel.text = ecgRecord.timestamp
        }
        
        // Show/hide sync button based on isSynced flag
        let synced = ecgRecord.isSynced ?? false
        syncButton.isHidden = synced
        syncBadgeLabel.text = synced ? " ✓ Synced " : " ⏳ Pending "
        syncBadgeLabel.backgroundColor = synced
            ? UIColor(red: 0.25, green: 0.75, blue: 0.50, alpha: 0.12)
            : UIColor(red: 0.95, green: 0.65, blue: 0.15, alpha: 0.15)
        syncBadgeLabel.textColor = synced
            ? UIColor(red: 0.10, green: 0.60, blue: 0.35, alpha: 1)
            : UIColor(red: 0.70, green: 0.45, blue: 0.0, alpha: 1)
        if synced {
            print("[ECG Detail] ✅ Record synced")
        } else {
            print("[ECG Detail] ⚠️ Record NOT synced")
        }
        
        // Diagnosis - colored accent bar + label
        let diagnosisText = getDiagnosisText(ecgRecord.diagnoseType)
        diagnosisLabel.text = diagnosisText
        let isNormal = ecgRecord.diagnoseType == 1
        diagnosisLabel.textColor = isNormal
            ? UIColor(red: 0.10, green: 0.55, blue: 0.35, alpha: 1)
            : UIColor(red: 0.80, green: 0.25, blue: 0.15, alpha: 1)
        accentBar.backgroundColor = isNormal
            ? UIColor(red: 0.25, green: 0.75, blue: 0.50, alpha: 1)
            : UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1)
        
        // Tores score
        let toresScore = HealthScoreCalculator.ecgScore(from: ecgRecord)
        toresValueLabel.text = toresScore > 0 ? "\(toresScore)" : "--"
        
        // Metrics
        hrLabel.text  = "\(ecgRecord.heartRate)\nbpm"
        hrLabel.numberOfLines = 2
        bpLabel.text  = "\(ecgRecord.sbp)/\(ecgRecord.dbp)\nmmHg"
        bpLabel.numberOfLines = 2
        hrvLabel.text = "\(ecgRecord.hrv)\nms"
        hrvLabel.numberOfLines = 2
        
        // Render ECG Chart
        if !ecgRecord.ecgList.isEmpty {
            renderECGChart(ecgData: ecgRecord.ecgList)
        }
    }
    
    private func renderECGChart(ecgData: [Int]) {
        // ecgData is already processed draw data, convert to NSMutableArray
        let dataArray = NSMutableArray()
        for value in ecgData {
            dataArray.add(NSNumber(value: value))
        }
        
        // Each data point width: 0.1 * gridSize * 3
        let pointWidth = CELL_SIZE * 0.3
        var totalWidth = CGFloat(ecgData.count) * pointWidth
        
        // Ensure minimum width is screen width
        let screenWidth = UIScreen.main.bounds.width
        if totalWidth < screenWidth {
            totalWidth = screenWidth
        }
        
        // Set frame for line view
        let chartHeight: CGFloat = 200
        ecgLineView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: chartHeight)
        
        // Set content size for scroll view
        ecgScrollView.contentSize = CGSize(width: totalWidth, height: chartHeight)
        
        // Update line view with processed data
        ecgLineView.datas = dataArray
        ecgLineView.setNeedsDisplay()
    }
    
    private func getDiagnosisText(_ type: Int) -> String {
        switch type {
        case 1: return "Normal ECG"
        case 2: return "Suspected Atrial Fibrillation"
        case 3: return "Suspected Atrial Premature Beats"
        case 4: return "Suspected Ventricular Premature Beats"
        case 5: return "Suspected Bradycardia"
        case 6: return "Suspected Tachycardia"
        case 7: return "Suspected Arrhythmia"
        default: return "Unknown"
        }
    }
    
    @objc private func viewReportButtonTapped() {
        print("[ECG Detail] 📄 Opening AI Report...")
        print("[ECG Detail] 🔍 Record timestamp: \(ecgRecord.timestamp)")
        print("[ECG Detail] 🔍 ECG data count in record: \(ecgRecord.ecgList.count)")
        
        // Start loading
        reportButton.isEnabled = false
        loadingIndicator.startAnimating()
        reportButton.setTitle("Loading...", for: .normal)
        reportButton.setImage(nil, for: .normal)
        
        // Validate data format before showing report
        let ecgDataArray = ecgRecord.ecgList
        let isValidData = validateECGDataForReport(ecgDataArray)
        
        if !isValidData {
            // Stop loading
            stopLoading()
            
            print("[ECG Detail] ⚠️ Invalid data format detected - showing alert")
            showDataFormatAlert()
            return
        }
        
        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            // Stop loading
            self.stopLoading()
            
            // Convert ECGRecord to YCHealthLocalECGInfo
            let ecgInfo = self.convertToReportData(self.ecgRecord)
            
            // Present report view
            let reportVC = YCECGReportViewController()
            reportVC.ecgInfo = ecgInfo
            self.navigationController?.pushViewController(reportVC, animated: true)
        }
    }
    
    private func stopLoading() {
        reportButton.isEnabled = true
        loadingIndicator.stopAnimating()
        reportButton.setTitle("View AI Report", for: .normal)
        reportButton.setImage(UIImage(systemName: "doc.text.fill"), for: .normal)
    }
    
    private func validateECGDataForReport(_ data: [Int]) -> Bool {
        print("[ECG Detail] 🔍 Validation starting...")
        print("[ECG Detail] 🔍 Data count: \(data.count)")
        print("[ECG Detail] 🔍 First 10 values: \(Array(data.prefix(10)))")
        
        if let minVal = data.min(), let maxVal = data.max() {
            print("[ECG Detail] 🔍 Value range: \(minVal) to \(maxVal)")
        }
        
        // Check if data count is reasonable (raw device data ~2800-15000 samples)
        guard data.count >= 1000 && data.count <= 20000 else {
            print("[ECG Detail] ❌ Invalid data count: \(data.count) (expected 1000-20000)")
            return false
        }
        
        // Check if first 10 values are not all zeros (processed data signature)
        let firstTen = Array(data.prefix(10))
        let allZeros = firstTen.allSatisfy { $0 == 0 }
        if allZeros {
            print("[ECG Detail] ❌ First 10 values are all zeros - invalid/processed data")
            return false
        }
        
        print("[ECG Detail] ✅ Data validation passed")
        return true
    }
    
    private func showDataFormatAlert() {
        let alert = UIAlertController(
            title: "Data Format Issue",
            message: "This ECG record uses an older data format that is not compatible with the AI report. Please take a new ECG measurement to view the AI analysis report.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    /// Convert ECGRecord to YCHealthLocalECGInfo for AI report
    private func convertToReportData(_ record: ECGRecord) -> YCHealthLocalECGInfo {
        let ecgInfo = YCHealthLocalECGInfo()
        
        ecgInfo.heartRate = record.heartRate
        ecgInfo.hrv = record.hrv
        ecgInfo.systolicBloodPressure = record.sbp
        ecgInfo.diastolicBloodPressure = record.dbp
        ecgInfo.afflag = record.isAfib
        ecgInfo.qrsType = record.diagnoseType
        
        // Add user profile data
        ecgInfo.age = UserDefaultsManager.shared.profileAge
        ecgInfo.gender = UserDefaultsManager.shared.profileGender ?? "Male"
        
        // Convert [Int] to [Int32] for AI report
        ecgInfo.ecgDatas = record.ecgList.map { Int32($0) }
        
        print("[ECG Detail] ✅ Converted to report data - HR=\(ecgInfo.heartRate), Count=\(ecgInfo.ecgDatas.count)")
        
        return ecgInfo
    }
    
    @objc private func syncButtonTapped() {
        // Disable button during sync
        syncButton.isEnabled = false
        syncButton.alpha = 0.5
        
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else {
            showSyncError("User not logged in")
            return
        }
        
        print("[ECG Detail] 📤 Syncing ECG record to server...")
        
        HealthService.shared.uploadECGRecords(userId: userId, records: [ecgRecord]) { [weak self] result in
            DispatchQueue.main.async {
                self?.syncButton.isEnabled = true
                self?.syncButton.alpha = 1.0
                
                switch result {
                case .success(let response):
                    print("[ECG Detail] ✅ Sync successful: \(response.message)")
                    
                    // Mark as synced in database
                    self?.ecgRepository.markAsSynced(timestamp: self?.ecgRecord.timestamp ?? "") { success in
                        if success {
                            print("[ECG Detail] 🔄 Marked as synced in database")
                            DispatchQueue.main.async {
                                // Hide sync button after successful sync
                                self?.syncButton.isHidden = true
                                self?.syncBadgeLabel.text = " ✓ Synced "
                                self?.syncBadgeLabel.backgroundColor = UIColor(red: 0.25, green: 0.75, blue: 0.50, alpha: 0.12)
                                self?.syncBadgeLabel.textColor = UIColor(red: 0.10, green: 0.60, blue: 0.35, alpha: 1)
                                self?.showSyncSuccess()
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("[ECG Detail] ❌ Sync failed: \(error)")
                    self?.showSyncError(error.localizedDescription)
                }
            }
        }
    }
    
    private func showSyncSuccess() {
        let alert = UIAlertController(
            title: "Sync Successful",
            message: "ECG record has been synced to the server.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSyncError(_ message: String) {
        syncButton.isEnabled = true
        syncButton.alpha = 1.0
        
        let alert = UIAlertController(
            title: "Sync Failed",
            message: "Unable to sync ECG record: \(message)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

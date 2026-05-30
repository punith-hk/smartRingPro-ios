import UIKit
import YCProductSDK

final class ECGHistoryViewController: AppBaseViewController {
    
    private let ecgRepository = ECGRecordRepository()
    private var ecgRecords: [ECGRecord] = []
    
    private let tableView = UITableView()
    private let emptyStateLabel = UILabel()
    private let pageTitleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("ECG History")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        
        setupUI()
        loadECGHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch from server first to sync isSynced flags
        fetchECGRecordsFromServer()
        
        // Then load local history
        loadECGHistory()
    }
    
    private func setupUI() {
        // Page Title
        pageTitleLabel.text = "ECG History"
        pageTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        pageTitleLabel.textColor = UIColor(white: 0.08, alpha: 1)
        pageTitleLabel.textAlignment = .center
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageTitleLabel)

        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ECGHistoryCell.self, forCellReuseIdentifier: "ECGHistoryCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Empty State Label
        emptyStateLabel.text = "No ECG records yet.\nStart your first measurement!"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .gray
        emptyStateLabel.font = .systemFont(ofSize: 16)
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            pageTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            pageTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pageTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: pageTitleLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func loadECGHistory() {
        ecgRepository.fetchAllRecords { [weak self] records in
            DispatchQueue.main.async {
                self?.ecgRecords = records
                self?.tableView.reloadData()
                self?.emptyStateLabel.isHidden = !records.isEmpty
                self?.backfillToresIfNeeded(records: records)
            }
        }
    }
    
    /// For any legacy record saved before tores calculation was added (tores == 0),
    /// compute a tores score now and persist it to the local DB.
    private func backfillToresIfNeeded(records: [ECGRecord]) {
        let needsBackfill = records.filter { $0.tores == 0 }
        guard !needsBackfill.isEmpty else { return }
        
        print("[ECGHistory] 🔄 Backfilling tores for \(needsBackfill.count) record(s)")
        var updatedCount = 0
        
        for record in needsBackfill {
            let computed = HealthScoreCalculator.ecgScore(from: record)
            guard computed > 0 else { continue }   // still no data to compute from
            
            ecgRepository.updateTores(timestamp: record.timestamp, tores: computed) { [weak self] success in
                guard let self = self, success else { return }
                updatedCount += 1
                
                // Refresh UI once the last update is done
                if updatedCount == needsBackfill.filter({ HealthScoreCalculator.ecgScore(from: $0) > 0 }).count {
                    self.ecgRepository.fetchAllRecords { records in
                        DispatchQueue.main.async {
                            self.ecgRecords = records
                            self.tableView.reloadData()
                            print("[ECGHistory] ✅ Backfilled tores for \(updatedCount) record(s)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Server Sync
    
    /// Fetch ECG records from server and update sync status in local DB
    private func fetchECGRecordsFromServer() {
        let userId = UserDefaultsManager.shared.userId
        guard userId > 0 else {
            print("[ECGHistory] ⚠️ No user ID, skipping server fetch")
            return
        }
        
        HealthService.shared.fetchECGRecords(userId: userId, limit: 100, offset: 0) { [weak self] result in
            switch result {
            case .success(let response):
                let serverRecords = response.data ?? []
                print("[ECGHistory] 📥 ✅ Fetched \(serverRecords.count) ECG record(s) from server (limit: 5)")
                
                // Log timestamps
                if !serverRecords.isEmpty {
                    print("[ECGHistory] 📋 Timestamps from server:")
                    for (index, record) in serverRecords.prefix(5).enumerated() {
                        let hr = record.heartRate.map { "\($0)" } ?? "N/A"
                        let bp = "\(record.sbp ?? 0)/\(record.dbp ?? 0)"
                        print("  [\(index + 1)] ID:\(record.id ?? 0) - \(record.recordTimestamp)")
                        print("       HR: \(hr), BP: \(bp)")
                    }
                    if serverRecords.count > 5 {
                        print("       ... and \(serverRecords.count - 5) more")
                    }
                } else {
                    print("[ECGHistory] ℹ️ No ECG records on server")
                }
                
                // Compare with local database and update isSynced flags
                self?.compareLocalWithServer(serverRecords: serverRecords)
                
            case .failure(let error):
                print("[ECGHistory] ❌ Failed to fetch ECG records: \(error)")
            }
        }
    }
    
    /// Compare local records with server records and update isSynced flags in local DB
    /// Server is the source of truth - we compare timestamps directly
    private func compareLocalWithServer(serverRecords: [ECGRecordDTO]) {
        ecgRepository.fetchAllRecords { [weak self] allLocalRecords in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Convert server timestamps to local format for comparison
                let serverTimestamps = Set(serverRecords.compactMap { record -> String? in
                    self.convertServerTimestampToLocal(record.recordTimestamp)
                })
                
                print("[ECGHistory] 🔍 Comparing timestamps:")
                print("       • Server has \(serverTimestamps.count) timestamps")
                print("       • Local has \(allLocalRecords.count) records")
                
                // Only mark as synced — never downgrade a record that's already synced
                // (server response may be paginated and not contain all records)
                var syncedCount = 0
                
                for record in allLocalRecords {
                    let isOnServer = serverTimestamps.contains(record.timestamp)
                    if isOnServer {
                        self.ecgRepository.markAsSynced(timestamp: record.timestamp) { _ in }
                        syncedCount += 1
                    }
                }
                
                let unsyncedCount = allLocalRecords.count - syncedCount
                
                print("[ECGHistory] ✅ Updated sync status:")
                print("       • \(syncedCount) records marked as synced")
                print("       • \(unsyncedCount) records marked as unsynced")
                
                // Log overall sync health
                self.logSyncHealth(localUnsynced: unsyncedCount, serverTotal: serverRecords.count)
            }
        }
    }
    
    /// Convert server ISO8601 timestamp to local format
    private func convertServerTimestampToLocal(_ isoTimestamp: String) -> String? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: isoTimestamp) else {
            return nil
        }
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return localFormatter.string(from: date)
    }
    
    /// Log overall sync health
    private func logSyncHealth(localUnsynced: Int, serverTotal: Int) {
        if localUnsynced == 0 {
            print("[ECGHistory] 💚 Sync Health: EXCELLENT - All records synced")
        } else if localUnsynced <= 2 {
            print("[ECGHistory] 💛 Sync Health: GOOD - \(localUnsynced) record(s) need syncing")
        } else {
            print("[ECGHistory] 🧡 Sync Health: NEEDS ATTENTION - \(localUnsynced) records need syncing")
        }
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
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ECGHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ecgRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ECGHistoryCell", for: indexPath) as! ECGHistoryCell
        let record = ecgRecords[indexPath.row]
        cell.configure(with: record)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let record = ecgRecords[indexPath.row]
        let detailVC = ECGDetailViewController()
        detailVC.ecgRecord = record
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - ECG History Cell
class ECGHistoryCell: UITableViewCell {
    
    private let cardView      = UIView()
    private let accentBar     = UIView()
    private let dateLabel     = UILabel()
    // private let syncBadge  = UILabel()  // TODO: add proper sync logic later
    private let diagnosisLabel = UILabel()
    private let hrLabel       = UILabel()
    private let bpLabel       = UILabel()
    private let hrvLabel      = UILabel()
    private let toresValueLabel = UILabel()
    private let toresTitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Card
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // Left accent bar
        accentBar.layer.cornerRadius = 3
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(accentBar)
        
        // Date
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateLabel)
        
        // Sync badge — commented out, TODO: add proper sync logic later
        // syncBadge.font = .systemFont(ofSize: 11, weight: .semibold)
        // syncBadge.layer.cornerRadius = 6
        // syncBadge.layer.masksToBounds = true
        // syncBadge.textAlignment = .center
        // syncBadge.translatesAutoresizingMaskIntoConstraints = false
        // cardView.addSubview(syncBadge)
        
        // Diagnosis
        diagnosisLabel.font = .systemFont(ofSize: 16, weight: .bold)
        diagnosisLabel.textColor = UIColor(white: 0.08, alpha: 1)
        diagnosisLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(diagnosisLabel)
        
        // Metrics
        [hrLabel, bpLabel, hrvLabel].forEach { label in
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
        }
        let metricsStack = UIStackView(arrangedSubviews: [hrLabel, bpLabel, hrvLabel])
        metricsStack.axis = .horizontal
        metricsStack.spacing = 12
        metricsStack.distribution = .fill
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(metricsStack)
        
        // Tores score (right side)
        toresValueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        toresValueLabel.textColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        toresValueLabel.textAlignment = .center
        toresValueLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(toresValueLabel)
        
        toresTitleLabel.text = "tores"
        toresTitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        toresTitleLabel.textColor = .secondaryLabel
        toresTitleLabel.textAlignment = .center
        toresTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(toresTitleLabel)
        
        // Chevron
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor.lightGray
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            accentBar.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            accentBar.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            accentBar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            accentBar.widthAnchor.constraint(equalToConstant: 4),
            
            toresValueLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor, constant: -8),
            toresValueLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            toresValueLabel.widthAnchor.constraint(equalToConstant: 44),
            
            toresTitleLabel.topAnchor.constraint(equalTo: toresValueLabel.bottomAnchor, constant: 2),
            toresTitleLabel.centerXAnchor.constraint(equalTo: toresValueLabel.centerXAnchor),
            
            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14),
            
            dateLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            dateLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: toresValueLabel.leadingAnchor, constant: -8),
            
            // syncBadge constraints — commented out, TODO: add proper sync logic later
            // syncBadge.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            // syncBadge.trailingAnchor.constraint(equalTo: toresValueLabel.leadingAnchor, constant: -8),
            // syncBadge.heightAnchor.constraint(equalToConstant: 18),
            // syncBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),
            
            diagnosisLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 6),
            diagnosisLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            diagnosisLabel.trailingAnchor.constraint(equalTo: toresValueLabel.leadingAnchor, constant: -8),
            
            metricsStack.topAnchor.constraint(equalTo: diagnosisLabel.bottomAnchor, constant: 8),
            metricsStack.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            metricsStack.trailingAnchor.constraint(equalTo: toresValueLabel.leadingAnchor, constant: -8),
            metricsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }
    
    func configure(with record: ECGRecord) {
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: record.timestamp) {
            dateFormatter.dateFormat = "MMM dd, yyyy  HH:mm"
            dateLabel.text = dateFormatter.string(from: date)
        } else {
            dateLabel.text = record.timestamp
        }
        
        // Diagnosis
        diagnosisLabel.text = getDiagnosisText(record.diagnoseType)
        
        // Accent bar color
        let isNormal = record.diagnoseType == 1
        accentBar.backgroundColor = isNormal
            ? UIColor(red: 0.25, green: 0.75, blue: 0.50, alpha: 1)
            : UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1)
        
        // Metrics
        hrLabel.text  = "HR \(record.heartRate) bpm"
        bpLabel.text  = "BP \(record.sbp)/\(record.dbp)"
        hrvLabel.text = "HRV \(record.hrv) ms"
        
        // Tores
        toresValueLabel.text = "\(record.tores)"
        
        // Sync badge — commented out, TODO: add proper sync logic later
        // let synced = record.isSynced ?? false
        // syncBadge.text = synced ? " ✓ Synced " : " ⏳ Pending "
        // syncBadge.backgroundColor = synced
        //     ? UIColor(red: 0.25, green: 0.75, blue: 0.50, alpha: 0.12)
        //     : UIColor(red: 0.95, green: 0.65, blue: 0.15, alpha: 0.15)
        // syncBadge.textColor = synced
        //     ? UIColor(red: 0.10, green: 0.60, blue: 0.35, alpha: 1)
        //     : UIColor(red: 0.70, green: 0.45, blue: 0.0, alpha: 1)
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
}

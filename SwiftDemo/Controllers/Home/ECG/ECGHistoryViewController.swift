import UIKit
import YCProductSDK

final class ECGHistoryViewController: AppBaseViewController {
    
    private let ecgRepository = ECGRecordRepository()
    private var ecgRecords: [ECGRecord] = []
    
    private let tableView = UITableView()
    private let emptyStateLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("ECG History")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
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
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ECGHistoryCell.self, forCellReuseIdentifier: "ECGHistoryCell")
        tableView.rowHeight = 100
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
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
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        
        HealthService.shared.fetchECGRecords(userId: userId, limit: 5, offset: 0) { [weak self] result in
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
                
                // Update isSynced flag for all records
                var syncedCount = 0
                var unsyncedCount = 0
                
                for record in allLocalRecords {
                    let isOnServer = serverTimestamps.contains(record.timestamp)
                    
                    // Update isSynced flag in database
                    if isOnServer {
                        self.ecgRepository.markAsSynced(timestamp: record.timestamp) { _ in }
                        syncedCount += 1
                    } else {
                        self.ecgRepository.markAsUnsynced(timestamp: record.timestamp) { _ in }
                        unsyncedCount += 1
                    }
                }
                
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
    
    private let cardView = UIView()
    private let dateLabel = UILabel()
    private let diagnosisLabel = UILabel()
    private let hrLabel = UILabel()
    private let bpLabel = UILabel()
    private let hrvLabel = UILabel()
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
        
        // Card View
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // Date Label
        dateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = .black
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateLabel)
        
        // Diagnosis Label
        diagnosisLabel.font = .systemFont(ofSize: 12)
        diagnosisLabel.textColor = .gray
        diagnosisLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(diagnosisLabel)
        
        // Metrics Stack
        let metricsStack = UIStackView(arrangedSubviews: [hrLabel, bpLabel, hrvLabel])
        metricsStack.axis = .horizontal
        metricsStack.spacing = 16
        metricsStack.distribution = .fillEqually
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(metricsStack)
        
        [hrLabel, bpLabel, hrvLabel].forEach { label in
            label.font = .systemFont(ofSize: 11)
            label.textColor = .darkGray
            label.textAlignment = .left
        }
        
        // Chevron
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .lightGray
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            diagnosisLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            diagnosisLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            metricsStack.topAnchor.constraint(equalTo: diagnosisLabel.bottomAnchor, constant: 8),
            metricsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            metricsStack.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            metricsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    func configure(with record: ECGRecord) {
        // Format date
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
        
        // Metrics
        hrLabel.text = "HR: \(record.heartRate) bpm"
        bpLabel.text = "BP: \(record.sbp)/\(record.dbp)"
        hrvLabel.text = "HRV: \(record.hrv) ms"
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

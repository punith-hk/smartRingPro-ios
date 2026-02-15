import UIKit
import Charts

class ECGTrendTrackingViewController: AppBaseViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Pie Chart
    private let pieChartCard = UIView()
    private let pieChartView = PieChartView()
    
    // List Card with Tabs
    private let listCard = UIView()
    
    // Tab Buttons
    private let tabContainer = UIView()
    private let normalTabButton = UIButton(type: .system)
    private let abnormalTabButton = UIButton(type: .system)
    
    // Table View
    private let tableView = UITableView()
    private let emptyStateLabel = UILabel()
    
    // Data
    private var allRecords: [ECGRecord] = []
    private var filteredRecords: [ECGRecord] = []
    private var selectedTab: TabType = .normal
    private var normalCount = 0
    private var abnormalCount = 0
    
    enum TabType {
        case normal
        case abnormal
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("ECG Trend Tracking")
        
        setupUI()
        setupPieChart()
        setupTabs()
        setupTableView()
        
        fetchLocalECGRecords()
    }
    
    // MARK: - UI Setup
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
    }
    
    private func setupPieChart() {
        // Card
        pieChartCard.backgroundColor = .white
        pieChartCard.layer.cornerRadius = 12
        pieChartCard.layer.shadowColor = UIColor.black.cgColor
        pieChartCard.layer.shadowOpacity = 0.1
        pieChartCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        pieChartCard.layer.shadowRadius = 4
        pieChartCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pieChartCard)
        
        // Chart View
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        pieChartView.chartDescription.enabled = false
        pieChartView.drawHoleEnabled = true
        pieChartView.holeRadiusPercent = 0.58
        pieChartView.transparentCircleRadiusPercent = 0.61
        pieChartView.drawCenterTextEnabled = true
        pieChartView.centerText = ""
        pieChartView.centerTextRadiusPercent = 1.0
        pieChartView.rotationEnabled = false
        pieChartView.highlightPerTapEnabled = true
        pieChartView.drawEntryLabelsEnabled = false
        pieChartView.delegate = self
        pieChartView.legend.enabled = true
        pieChartView.legend.horizontalAlignment = .left
        pieChartView.legend.verticalAlignment = .bottom
        pieChartView.legend.orientation = .horizontal
        pieChartView.legend.font = .systemFont(ofSize: 12)
        pieChartView.legend.formSize = 12
        pieChartView.legend.xEntrySpace = 10
        pieChartView.legend.yEntrySpace = 5
        pieChartCard.addSubview(pieChartView)
        
        NSLayoutConstraint.activate([
            pieChartCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            pieChartCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pieChartCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            pieChartCard.heightAnchor.constraint(equalToConstant: 280),
            
            pieChartView.topAnchor.constraint(equalTo: pieChartCard.topAnchor, constant: 16),
            pieChartView.leadingAnchor.constraint(equalTo: pieChartCard.leadingAnchor, constant: 16),
            pieChartView.trailingAnchor.constraint(equalTo: pieChartCard.trailingAnchor, constant: -16),
            pieChartView.bottomAnchor.constraint(equalTo: pieChartCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupTabs() {
        // List Card (contains tabs and table)
        listCard.backgroundColor = .white
        listCard.layer.cornerRadius = 12
        listCard.layer.shadowColor = UIColor.black.cgColor
        listCard.layer.shadowOpacity = 0.1
        listCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        listCard.layer.shadowRadius = 4
        listCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(listCard)
        
        // Tab Container inside list card
        tabContainer.backgroundColor = .clear
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        listCard.addSubview(tabContainer)
        
        // Normal Tab
        normalTabButton.setTitle("Normal", for: .normal)
        normalTabButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        normalTabButton.translatesAutoresizingMaskIntoConstraints = false
        normalTabButton.addTarget(self, action: #selector(normalTabTapped), for: .touchUpInside)
        tabContainer.addSubview(normalTabButton)
        
        // Abnormal Tab
        abnormalTabButton.setTitle("Abnormal", for: .normal)
        abnormalTabButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        abnormalTabButton.translatesAutoresizingMaskIntoConstraints = false
        abnormalTabButton.addTarget(self, action: #selector(abnormalTabTapped), for: .touchUpInside)
        tabContainer.addSubview(abnormalTabButton)
        
        NSLayoutConstraint.activate([
            listCard.topAnchor.constraint(equalTo: pieChartCard.bottomAnchor, constant: 16),
            listCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            listCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            listCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            listCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            
            tabContainer.topAnchor.constraint(equalTo: listCard.topAnchor, constant: 8),
            tabContainer.leadingAnchor.constraint(equalTo: listCard.leadingAnchor, constant: 8),
            tabContainer.trailingAnchor.constraint(equalTo: listCard.trailingAnchor, constant: -8),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            normalTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            normalTabButton.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            normalTabButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            normalTabButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5),
            
            abnormalTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            abnormalTabButton.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            abnormalTabButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            abnormalTabButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5)
        ])
        
        updateTabSelection()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ECGTrendRecordCell.self, forCellReuseIdentifier: "ECGTrendRecordCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        listCard.addSubview(tableView)
        
        // Empty State Label
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .gray
        emptyStateLabel.font = .systemFont(ofSize: 16)
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        listCard.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: listCard.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: listCard.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: listCard.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: listCard.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: listCard.centerYAnchor, constant: 30),
            emptyStateLabel.leadingAnchor.constraint(equalTo: listCard.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: listCard.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchLocalECGRecords() {
        let repo = ECGRecordRepository()
        repo.fetchAllRecords { [weak self] records in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.allRecords = records
                self.calculateStatistics()
                self.updatePieChart()
                self.filterRecords()
            }
        }
    }
    
    private func calculateStatistics() {
        normalCount = allRecords.filter { $0.diagnoseType == 1 }.count
        abnormalCount = allRecords.filter { $0.diagnoseType >= 2 && $0.diagnoseType <= 7 }.count
    }
    
    private func updatePieChart() {
        guard normalCount > 0 || abnormalCount > 0 else {
            // No data
            pieChartView.data = nil
            return
        }
        
        var entries: [PieChartDataEntry] = []
        var colors: [UIColor] = []
        
        if normalCount > 0 {
            entries.append(PieChartDataEntry(value: Double(normalCount), label: "Normal ECG (Sinus rhythm)"))
            colors.append(UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1))  // Green for normal
        }
        
        if abnormalCount > 0 {
            entries.append(PieChartDataEntry(value: Double(abnormalCount), label: "Suspected Sinus arrhythmia"))
            colors.append(UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1))  // Cyan/Blue for abnormal
        }
        
        let dataSet = PieChartDataSet(entries: entries)
        dataSet.label = nil
        dataSet.colors = colors
        dataSet.sliceSpace = 2
        dataSet.selectionShift = 8
        dataSet.valueFont = .boldSystemFont(ofSize: 16)
        dataSet.valueTextColor = .white
        dataSet.drawValuesEnabled = true
        dataSet.xValuePosition = .insideSlice
        dataSet.yValuePosition = .insideSlice
        dataSet.entryLabelFont = .systemFont(ofSize: 0)
        dataSet.drawIconsEnabled = false
        
        // Show percentage only
        let totalCount = Double(normalCount + abnormalCount)
        let data = PieChartData(dataSet: dataSet)
        data.setValueFormatter(PercentFormatter(total: totalCount))
        
        pieChartView.data = data
        pieChartView.animate(xAxisDuration: 0.5, easingOption: .easeOutBack)
    }
    
    private func filterRecords() {
        switch selectedTab {
        case .normal:
            filteredRecords = allRecords.filter { $0.diagnoseType == 1 }
            if filteredRecords.isEmpty {
                emptyStateLabel.text = "No Normal ECG data available"
                emptyStateLabel.isHidden = false
                tableView.isHidden = true
            } else {
                emptyStateLabel.isHidden = true
                tableView.isHidden = false
            }
        case .abnormal:
            filteredRecords = allRecords.filter { $0.diagnoseType >= 2 && $0.diagnoseType <= 7 }
            if filteredRecords.isEmpty {
                emptyStateLabel.text = "No Abnormal ECG data available"
                emptyStateLabel.isHidden = false
                tableView.isHidden = true
            } else {
                emptyStateLabel.isHidden = true
                tableView.isHidden = false
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Tab Actions
    @objc private func normalTabTapped() {
        guard selectedTab != .normal else { return }
        selectedTab = .normal
        updateTabSelection()
        filterRecords()
    }
    
    @objc private func abnormalTabTapped() {
        guard selectedTab != .abnormal else { return }
        selectedTab = .abnormal
        updateTabSelection()
        filterRecords()
    }
    
    private func updateTabSelection() {
        normalTabButton.layer.cornerRadius = 8
        normalTabButton.layer.masksToBounds = true
        abnormalTabButton.layer.cornerRadius = 8
        abnormalTabButton.layer.masksToBounds = true
        
        if selectedTab == .normal {
            normalTabButton.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
            normalTabButton.setTitleColor(.white, for: .normal)
            abnormalTabButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            abnormalTabButton.setTitleColor(.darkGray, for: .normal)
        } else {
            abnormalTabButton.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
            abnormalTabButton.setTitleColor(.white, for: .normal)
            normalTabButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            normalTabButton.setTitleColor(.darkGray, for: .normal)
        }
    }
    
    private func getDiagnosisText(_ type: Int) -> String {
        switch type {
        case 1: return "Normal ECG (Sinus rhythm)"
        case 2: return "Suspected sinus arrhythmia"
        case 3: return "Suspected Atrial Premature Beats"
        case 4: return "Suspected Ventricular Premature Beats"
        case 5: return "Suspected Bradycardia"
        case 6: return "Suspected Tachycardia"
        case 7: return "Suspected Arrhythmia"
        default: return "Unknown"
        }
    }
}

// MARK: - ChartViewDelegate
extension ECGTrendTrackingViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // Update center text with selection details
        if let pieEntry = entry as? PieChartDataEntry {
            let total = Double(normalCount + abnormalCount)
            let percentage = (entry.y / total) * 100.0
            let label = pieEntry.label ?? ""
            let count = Int(entry.y)
            
            let text = NSMutableAttributedString()
            text.append(NSAttributedString(
                string: label + "\n",
                attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.darkGray]
            ))
            text.append(NSAttributedString(
                string: "\(count) (\(String(format: "%.1f%%", percentage)))",
                attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black]
            ))
            
            pieChartView.centerAttributedText = text
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        pieChartView.centerAttributedText = nil
    }
}

// MARK: - UITableViewDataSource
extension ECGTrendTrackingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ECGTrendRecordCell", for: indexPath) as! ECGTrendRecordCell
        let record = filteredRecords[indexPath.row]
        cell.configure(with: record, diagnosisText: getDiagnosisText(record.diagnoseType))
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ECGTrendTrackingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let record = filteredRecords[indexPath.row]
        let detailVC = ECGDetailViewController()
        detailVC.ecgRecord = record
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Custom Table Cell
class ECGTrendRecordCell: UITableViewCell {
    
    private let diagnosisLabel = UILabel()
    private let timestampLabel = UILabel()
    private let heartRateLabel = UILabel()
    private let arrowIcon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        diagnosisLabel.font = .boldSystemFont(ofSize: 16)
        diagnosisLabel.textColor = .black
        diagnosisLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(diagnosisLabel)
        
        timestampLabel.font = .systemFont(ofSize: 13)
        timestampLabel.textColor = .gray
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timestampLabel)
        
        heartRateLabel.font = .systemFont(ofSize: 15)
        heartRateLabel.textColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heartRateLabel)
        
        arrowIcon.image = UIImage(systemName: "chevron.right")
        arrowIcon.tintColor = .lightGray
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(arrowIcon)
        
        NSLayoutConstraint.activate([
            diagnosisLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            diagnosisLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            diagnosisLabel.trailingAnchor.constraint(equalTo: heartRateLabel.leadingAnchor, constant: -8),
            
            timestampLabel.topAnchor.constraint(equalTo: diagnosisLabel.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            heartRateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            heartRateLabel.trailingAnchor.constraint(equalTo: arrowIcon.leadingAnchor, constant: -12),
            
            arrowIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with record: ECGRecord, diagnosisText: String) {
        diagnosisLabel.text = diagnosisText
        timestampLabel.text = record.timestamp
        heartRateLabel.text = "\(record.heartRate) bpm"
    }
}

// MARK: - Percent Formatter for Pie Chart
class PercentFormatter: ValueFormatter {
    private var totalValue: Double = 0.0
    
    init(total: Double) {
        self.totalValue = total
    }
    
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        let percent = (value / totalValue) * 100.0
        return String(format: "%.1f%%", percent)
    }
}

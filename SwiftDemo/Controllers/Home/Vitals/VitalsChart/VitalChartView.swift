import UIKit
import Charts

class VitalChartView: UIView {
    
    // MARK: - Properties
    weak var dataSource: VitalChartDataSource?
    weak var delegate: VitalChartDelegate?
    
    private let vitalType: VitalType
    private var selectedRange: VitalChartRange = .day
    private var selectedDate = Date()
    
    private var weekStartDate: Date?
    private var weekEndDate: Date?
    private var monthStartDate: Date?
    private var monthEndDate: Date?
    
    private var currentDataPoints: [VitalDataPoint] = []
    
    // MARK: - UI Components
    private let segmentedControl = UISegmentedControl(items: ["Day", "Week", "Month"])
    private let chartCard = UIView()
    private let lineChart = LineChartView()
    private let barChart = BarChartView()
    
    // Date header
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let dateLabel = UILabel()
    
    // Value labels (top right)
    private let timeLabel = UILabel()
    private let valueLabel = UILabel()
    
    // Legend label
    private let legendLabel = UILabel()
    
    // MARK: - Initialization
    init(vitalType: VitalType) {
        self.vitalType = vitalType
        super.init(frame: .zero)
        setupUI()
        setupChart()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(rangeChanged), for: .valueChanged)
        
        // Chart card
        chartCard.backgroundColor = .white
        chartCard.layer.cornerRadius = 12
        chartCard.layer.shadowColor = UIColor.black.cgColor
        chartCard.layer.shadowOpacity = 0.1
        chartCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        chartCard.layer.shadowRadius = 4
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartCard)
        
        // Date header
        prevButton.setTitle("‹", for: .normal)
        prevButton.titleLabel?.font = .boldSystemFont(ofSize: 32)
        prevButton.setTitleColor(.systemBlue, for: .normal)
        prevButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        prevButton.addTarget(self, action: #selector(prevDateTapped), for: .touchUpInside)
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(prevButton)
        
        dateLabel.textAlignment = .center
        dateLabel.font = .boldSystemFont(ofSize: 16)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(dateLabel)
        
        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .boldSystemFont(ofSize: 32)
        nextButton.setTitleColor(.systemBlue, for: .normal)
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nextButton.addTarget(self, action: #selector(nextDateTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(nextButton)
        
        // Time and value labels (centered)
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .gray
        timeLabel.textAlignment = .center
        timeLabel.text = "--:--"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(timeLabel)
        
        valueLabel.font = .systemFont(ofSize: 13)
        valueLabel.textColor = .gray
        valueLabel.textAlignment = .center
        valueLabel.text = "-- \(vitalType.unit)"
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(valueLabel)
        
        // Line chart or Bar chart based on vitalType
        if vitalType.useBarChart {
            barChart.translatesAutoresizingMaskIntoConstraints = false
            chartCard.addSubview(barChart)
        } else {
            lineChart.translatesAutoresizingMaskIntoConstraints = false
            chartCard.addSubview(lineChart)
        }
        
        // Legend label
        // legendLabel.font = .systemFont(ofSize: 11)
        // legendLabel.textColor = .gray
        // legendLabel.textAlignment = .center
        // legendLabel.text = vitalType.displayName
        // legendLabel.translatesAutoresizingMaskIntoConstraints = false
        // chartCard.addSubview(legendLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            chartCard.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            chartCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartCard.heightAnchor.constraint(equalToConstant: 230),
            
            dateLabel.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 12),
            dateLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
            
            prevButton.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            prevButton.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -12),
            
            nextButton.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 12),
            
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            timeLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            valueLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
        ])
        
        // Add chart-specific constraints
        if vitalType.useBarChart {
            NSLayoutConstraint.activate([
                barChart.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: -8),
                barChart.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 6),
                barChart.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -12),
                barChart.heightAnchor.constraint(equalToConstant: 160),
            ])
        } else {
            NSLayoutConstraint.activate([
                lineChart.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: -8),
                lineChart.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 6),
                lineChart.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -12),
                lineChart.heightAnchor.constraint(equalToConstant: 160),
            ])
        }
        
        NSLayoutConstraint.activate([
            // legendLabel.topAnchor.constraint(equalTo: lineChart.bottomAnchor, constant: 2),
            // legendLabel.centerXAnchor.constraint(equalTo: chartCard.centerXAnchor),
            // legendLabel.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -4),
            
            bottomAnchor.constraint(equalTo: chartCard.bottomAnchor)
        ])
    }
    
    private func setupChart() {
        if vitalType.useBarChart {
            setupBarChart()
        } else {
            setupLineChart()
        }
    }
    
    private func setupLineChart() {
        lineChart.delegate = self
        lineChart.backgroundColor = .clear
        
        // Enable legend only for BP to show Systolic/Diastolic
        lineChart.legend.enabled = (vitalType == .bloodPressure)
        if vitalType == .bloodPressure {
            lineChart.legend.form = .circle
            lineChart.legend.horizontalAlignment = .left
            lineChart.legend.verticalAlignment = .bottom
            lineChart.legend.orientation = .horizontal
            lineChart.legend.drawInside = false
            lineChart.legend.yOffset = 0
            lineChart.extraBottomOffset = 5
        }
        
        lineChart.rightAxis.enabled = false
        
        lineChart.dragEnabled = true
        lineChart.setScaleEnabled(true)
        lineChart.pinchZoomEnabled = true
        lineChart.doubleTapToZoomEnabled = false
        lineChart.scaleXEnabled = true
        lineChart.scaleYEnabled = false
        
        lineChart.dragDecelerationEnabled = true
        lineChart.dragDecelerationFrictionCoef = 0.9
        
        let xAxis = lineChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.granularity = 1.0
        xAxis.labelCount = 5
        xAxis.yOffset = vitalType == .bloodPressure ? 5 : 0
        
        let leftAxis = lineChart.leftAxis
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftAxis.axisMinimum = 0
    }
    
    private func setupBarChart() {
        barChart.delegate = self
        barChart.backgroundColor = .clear
        barChart.legend.enabled = false
        barChart.rightAxis.enabled = false
        
        barChart.dragEnabled = true
        barChart.setScaleEnabled(true)
        barChart.pinchZoomEnabled = true
        barChart.doubleTapToZoomEnabled = false
        barChart.scaleXEnabled = true
        barChart.scaleYEnabled = false
        
        barChart.dragDecelerationEnabled = true
        barChart.dragDecelerationFrictionCoef = 0.9
        
        let xAxis = barChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.granularity = 1.0
        xAxis.labelCount = 5
        
        let leftAxis = barChart.leftAxis
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftAxis.axisMinimum = 0
    }
    
    // MARK: - Public Methods
    func reloadData() {
        fetchAndDisplayData()
    }
    
    // MARK: - Data Fetching
    private func fetchAndDisplayData() {
        // Calculate date ranges BEFORE fetching data
        switch selectedRange {
        case .week:
            calculateWeekRange(from: selectedDate)
        case .month:
            calculateMonthRange(from: selectedDate)
        case .day:
            break
        }
        
        // Update date UI immediately with calculated ranges
        updateDateUI()
        
        dataSource?.fetchChartData(for: selectedRange, date: selectedDate) { [weak self] dataPoints in
            guard let self = self else { return }
            self.currentDataPoints = dataPoints
            
            // For BP, also fetch diastolic data
            if self.vitalType == .bloodPressure {
                self.dataSource?.fetchSecondaryChartData(for: self.selectedRange, date: self.selectedDate) { [weak self] secondaryDataPoints in
                    guard let self = self else { return }
                    self.populateChart(with: dataPoints, secondaryData: secondaryDataPoints)
                    
                    // Update labels with latest value
                    if !dataPoints.isEmpty {
                        let latest = dataPoints.max(by: { $0.timestamp < $1.timestamp })!
                        self.updateLabelsForDataPoint(latest)
                    } else {
                        self.timeLabel.text = "--:--"
                        self.valueLabel.text = "-- \(self.vitalType.unit)"
                        self.delegate?.chartShouldUpdateLabels(time: "--:--", value: "-- \(self.vitalType.unit)")
                    }
                }
            } else {
                self.populateChart(with: dataPoints, secondaryData: nil)
                
                // Update labels with latest value
                if !dataPoints.isEmpty {
                    let latest = dataPoints.max(by: { $0.timestamp < $1.timestamp })!
                    self.updateLabelsForDataPoint(latest)
                } else {
                    self.timeLabel.text = "--:--"
                    self.valueLabel.text = "-- \(self.vitalType.unit)"
                    self.delegate?.chartShouldUpdateLabels(time: "--:--", value: "-- \(self.vitalType.unit)")
                }
            }
        }
    }
    
    private func populateChart(with dataPoints: [VitalDataPoint], secondaryData: [VitalDataPoint]? = nil) {
        if vitalType.useBarChart {
            populateBarChart(with: dataPoints)
        } else {
            populateLineChart(with: dataPoints, secondaryData: secondaryData)
        }
    }
    
    private func populateBarChart(with dataPoints: [VitalDataPoint]) {
        guard !dataPoints.isEmpty else {
            barChart.data = nil
            barChart.setNeedsDisplay()
            return
        }
        
        var entries: [BarChartDataEntry] = []
        
        switch selectedRange {
        case .day:
            // X-axis: hour (0-24)
            for point in dataPoints {
                let date = Date(timeIntervalSince1970: TimeInterval(point.timestamp))
                let calendar = Calendar.current
                let hour = Double(calendar.component(.hour, from: date))
                let minute = Double(calendar.component(.minute, from: date))
                let xValue = hour + (minute / 60.0)
                entries.append(BarChartDataEntry(x: xValue, y: point.value))
            }
            entries.sort { $0.x < $1.x }
            
            barChart.xAxis.valueFormatter = TimeValueFormatter()
            barChart.xAxis.axisMinimum = 0
            barChart.xAxis.axisMaximum = 24
            barChart.xAxis.labelCount = 7
            barChart.xAxis.granularity = 4.0
            barChart.setVisibleXRangeMaximum(24)
            
        case .week:
            // X-axis: day index (0-6)
            guard let startDate = weekStartDate else { return }
            
            let calendar = Calendar.current
            var dayLabels: [String] = []
            let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
            
            for i in 0..<7 {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                let weekdayComponent = calendar.component(.weekday, from: currentDate)
                dayLabels.append(weekDays[(weekdayComponent + 5) % 7])
                
                // Find data for this day
                let dayStart = calendar.startOfDay(for: currentDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                if let point = dataPoints.first(where: {
                    let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                    return pointDate >= dayStart && pointDate < dayEnd
                }) {
                    entries.append(BarChartDataEntry(x: Double(i), y: point.value))
                }
            }
            
            barChart.xAxis.valueFormatter = WeekValueFormatter(dayLabels: dayLabels)
            barChart.xAxis.axisMinimum = -0.5
            barChart.xAxis.axisMaximum = 6.5
            barChart.xAxis.labelCount = 7
            barChart.xAxis.granularity = 1.0
            barChart.dragEnabled = true
            barChart.setScaleEnabled(false)
            
        case .month:
            // X-axis: day of month (0-30)
            guard let startDate = monthStartDate else { return }
            
            let calendar = Calendar.current
            let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count
            
            for i in 0..<daysInMonth {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                let dayStart = calendar.startOfDay(for: currentDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                if let point = dataPoints.first(where: {
                    let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                    return pointDate >= dayStart && pointDate < dayEnd
                }) {
                    entries.append(BarChartDataEntry(x: Double(i), y: point.value))
                }
            }
            
            barChart.xAxis.valueFormatter = MonthValueFormatter(daysInMonth: daysInMonth)
            barChart.xAxis.axisMinimum = 0
            barChart.xAxis.axisMaximum = Double(daysInMonth - 1)
            barChart.xAxis.labelCount = 6
            barChart.xAxis.granularity = 5.0
            barChart.dragEnabled = true
            barChart.setScaleEnabled(false)
        }
        
        guard !entries.isEmpty else {
            barChart.data = nil
            barChart.setNeedsDisplay()
            return
        }
        
        // Create bar data set
        let dataSet = BarChartDataSet(entries: entries, label: vitalType.displayName)
        dataSet.drawValuesEnabled = false
        dataSet.setColor(vitalType.color)
        dataSet.highlightEnabled = true
        
        let maxValue = entries.map({ $0.y }).max() ?? 0
        barChart.leftAxis.axisMaximum = maxValue + vitalType.yAxisPadding
        barChart.data = BarChartData(dataSet: dataSet)
        
        // Set bar width
        if let barData = barChart.data as? BarChartData {
            barData.barWidth = selectedRange == .day ? 0.4 : 0.6
        }
        
        // Force layout update to fix label alignment on first load
        barChart.notifyDataSetChanged()
        barChart.setNeedsLayout()
        barChart.layoutIfNeeded()
        
        // Reset zoom to fit all data
        barChart.fitScreen()
        barChart.setNeedsDisplay()
    }
    
    private func populateLineChart(with dataPoints: [VitalDataPoint], secondaryData: [VitalDataPoint]? = nil) {
        guard !dataPoints.isEmpty else {
            lineChart.data = nil
            lineChart.setNeedsDisplay()
            return
        }
        
        var entries: [ChartDataEntry] = []
        var secondaryEntries: [ChartDataEntry] = []
        
        switch selectedRange {
        case .day:
            // X-axis: hour (0-24)
            for point in dataPoints {
                let date = Date(timeIntervalSince1970: TimeInterval(point.timestamp))
                let calendar = Calendar.current
                let hour = Double(calendar.component(.hour, from: date))
                let minute = Double(calendar.component(.minute, from: date))
                let xValue = hour + (minute / 60.0)
                entries.append(ChartDataEntry(x: xValue, y: point.value))
            }
            entries.sort { $0.x < $1.x }
            
            lineChart.xAxis.valueFormatter = TimeValueFormatter()
            lineChart.xAxis.axisMinimum = 0
            lineChart.xAxis.axisMaximum = 24
            lineChart.xAxis.labelCount = 5
            lineChart.xAxis.granularity = 1.0
            lineChart.setVisibleXRangeMaximum(5)
            
        case .week:
            // X-axis: day index (0-6)
            guard let startDate = weekStartDate else { return }
            
            let calendar = Calendar.current
            var dayLabels: [String] = []
            let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
            
            for i in 0..<7 {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                let weekdayComponent = calendar.component(.weekday, from: currentDate)
                dayLabels.append(weekDays[(weekdayComponent + 5) % 7])
                
                // Find data for this day
                let dayStart = calendar.startOfDay(for: currentDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                if let point = dataPoints.first(where: {
                    let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                    return pointDate >= dayStart && pointDate < dayEnd
                }) {
                    entries.append(ChartDataEntry(x: Double(i), y: point.value))
                }
            }
            
            lineChart.xAxis.valueFormatter = WeekValueFormatter(dayLabels: dayLabels)
            lineChart.xAxis.axisMinimum = -0.5
            lineChart.xAxis.axisMaximum = 6.5
            lineChart.xAxis.labelCount = 7
            lineChart.xAxis.granularity = 1.0
            lineChart.dragEnabled = true
            lineChart.setScaleEnabled(false)
            
        case .month:
            // X-axis: day of month (0-30)
            guard let startDate = monthStartDate else { return }
            
            let calendar = Calendar.current
            let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count
            
            for i in 0..<daysInMonth {
                let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                let dayStart = calendar.startOfDay(for: currentDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                if let point = dataPoints.first(where: {
                    let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                    return pointDate >= dayStart && pointDate < dayEnd
                }) {
                    entries.append(ChartDataEntry(x: Double(i), y: point.value))
                }
            }
            
            lineChart.xAxis.valueFormatter = MonthValueFormatter(daysInMonth: daysInMonth)
            lineChart.xAxis.axisMinimum = 0
            lineChart.xAxis.axisMaximum = Double(daysInMonth - 1)
            lineChart.xAxis.labelCount = 6
            lineChart.xAxis.granularity = 5.0
            lineChart.dragEnabled = true
            lineChart.setScaleEnabled(false)
        }
        
        guard !entries.isEmpty else {
            lineChart.data = nil
            lineChart.setNeedsDisplay()
            return
        }
        
        // Primary data set (systolic for BP, or main data for other vitals)
        let dataSet = LineChartDataSet(entries: entries, label: vitalType == .bloodPressure ? "Systolic" : vitalType.displayName)
        dataSet.drawValuesEnabled = false
        dataSet.setColor(vitalType.color)
        dataSet.setCircleColor(.systemBlue)
        dataSet.circleRadius = 4
        
        var dataSets: [LineChartDataSet] = [dataSet]
        var maxValue = entries.map({ $0.y }).max() ?? 0
        
        // Add secondary data set for BP (diastolic)
        if let secondaryData = secondaryData, !secondaryData.isEmpty {
            switch selectedRange {
            case .day:
                for point in secondaryData {
                    let date = Date(timeIntervalSince1970: TimeInterval(point.timestamp))
                    let calendar = Calendar.current
                    let hour = Double(calendar.component(.hour, from: date))
                    let minute = Double(calendar.component(.minute, from: date))
                    let xValue = hour + (minute / 60.0)
                    secondaryEntries.append(ChartDataEntry(x: xValue, y: point.value))
                }
                secondaryEntries.sort { $0.x < $1.x }
                
            case .week:
                guard let startDate = weekStartDate else { break }
                let calendar = Calendar.current
                
                for i in 0..<7 {
                    let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                    let dayStart = calendar.startOfDay(for: currentDate)
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                    
                    if let point = secondaryData.first(where: {
                        let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                        return pointDate >= dayStart && pointDate < dayEnd
                    }) {
                        secondaryEntries.append(ChartDataEntry(x: Double(i), y: point.value))
                    }
                }
                
            case .month:
                guard let startDate = monthStartDate else { break }
                let calendar = Calendar.current
                let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count
                
                for i in 0..<daysInMonth {
                    let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
                    let dayStart = calendar.startOfDay(for: currentDate)
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                    
                    if let point = secondaryData.first(where: {
                        let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                        return pointDate >= dayStart && pointDate < dayEnd
                    }) {
                        secondaryEntries.append(ChartDataEntry(x: Double(i), y: point.value))
                    }
                }
            }
            
            if !secondaryEntries.isEmpty {
                let secondaryDataSet = LineChartDataSet(entries: secondaryEntries, label: "Diastolic")
                secondaryDataSet.drawValuesEnabled = false
                secondaryDataSet.setColor(.systemRed)
                secondaryDataSet.setCircleColor(.systemRed)
                secondaryDataSet.circleRadius = 4
                dataSets.append(secondaryDataSet)
                
                // Update max value to include secondary data
                if let secondaryMax = secondaryEntries.map({ $0.y }).max() {
                    maxValue = max(maxValue, secondaryMax)
                }
            }
        }
        
        lineChart.leftAxis.axisMaximum = maxValue + vitalType.yAxisPadding
        lineChart.data = LineChartData(dataSets: dataSets)
        
        // Notify chart and force layout update
        lineChart.notifyDataSetChanged()
        lineChart.setNeedsLayout()
        lineChart.layoutIfNeeded()
        
        // Reset zoom to fit all data for week/month, move to last for day
        switch selectedRange {
        case .day:
            if let lastEntry = entries.last {
                lineChart.moveViewToX(lastEntry.x)
            }
        case .week, .month:
            lineChart.fitScreen()
        }
        
        lineChart.setNeedsDisplay()
    }
    
    private func updateLabelsForDataPoint(_ point: VitalDataPoint) {
        let date = Date(timeIntervalSince1970: TimeInterval(point.timestamp))
        let value = Int(point.value)
        
        let timeString: String
        // Try custom format first, fallback to default
        let valueString = delegate?.chartCustomValueFormat(for: point.timestamp) ?? "\(value) \(vitalType.unit)"
        
        switch selectedRange {
        case .day:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            timeString = formatter.string(from: date)
            
        case .week, .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, yyyy-MM-dd"
            timeString = formatter.string(from: date)
        }
        
        // Update internal labels
        timeLabel.text = timeString
        valueLabel.text = valueString
        
        // Also notify delegate
        delegate?.chartShouldUpdateLabels(time: timeString, value: valueString)
    }
    
    // MARK: - Date Management
    private func updateDateUI() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        let calendar = Calendar.current
        let today = Date()
        
        switch selectedRange {
        case .day:
            dateLabel.text = formatter.string(from: selectedDate)
            // Enable next if selected date is before today
            nextButton.isEnabled = !calendar.isDate(selectedDate, inSameDayAs: today)
            
        case .week:
            guard let start = weekStartDate, let end = weekEndDate else { return }
            dateLabel.text = "\(formatter.string(from: start)) - \(formatter.string(from: end))"
            // Enable next if week end is before today
            nextButton.isEnabled = calendar.compare(end, to: today, toGranularity: .day) == .orderedAscending
            
        case .month:
            guard let start = monthStartDate, let end = monthEndDate else { return }
            dateLabel.text = "\(formatter.string(from: start)) - \(formatter.string(from: end))"
            // Enable next if month end is before today
            nextButton.isEnabled = calendar.compare(end, to: today, toGranularity: .day) == .orderedAscending
        }
        
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.3
    }
    
    private func calculateWeekRange(from date: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        
        let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        
        weekStartDate = start
        weekEndDate = end
    }
    
    private func calculateMonthRange(from date: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        
        monthStartDate = start
        monthEndDate = end
    }
    
    // MARK: - Actions
    @objc private func rangeChanged() {
        // Reset to current date when switching tabs
        selectedDate = Date()
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: selectedRange = .day
        case 1: selectedRange = .week
        case 2: selectedRange = .month
        default: break
        }
        
        fetchAndDisplayData()
    }
    
    @objc private func prevDateTapped() {
        let calendar = Calendar.current
        
        switch selectedRange {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
        }
        
        fetchAndDisplayData()
    }
    
    @objc private func nextDateTapped() {
        guard nextButton.isEnabled else { return }
        
        let calendar = Calendar.current
        
        switch selectedRange {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate)!
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
        }
        
        fetchAndDisplayData()
    }
}

// MARK: - ChartViewDelegate
extension VitalChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let value = Int(entry.y)
        var timestamp: Int64 = 0
        
        // Find the actual data point that matches this entry
        switch selectedRange {
        case .day:
            // Find point by matching hour/minute
            let hour = Int(entry.x)
            let minute = Int((entry.x - Double(hour)) * 60)
            
            if let point = currentDataPoints.first(where: {
                let date = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                let calendar = Calendar.current
                let h = calendar.component(.hour, from: date)
                let m = calendar.component(.minute, from: date)
                return h == hour && abs(m - minute) < 5
            }) {
                timestamp = point.timestamp
            } else {
                timestamp = Int64(Date().timeIntervalSince1970)
            }
            
        case .week:
            // Find point by day index
            guard let startDate = weekStartDate else { return }
            let calendar = Calendar.current
            let dayIndex = Int(round(entry.x))
            let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: startDate)!
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            if let point = currentDataPoints.first(where: {
                let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                return pointDate >= dayStart && pointDate < dayEnd
            }) {
                timestamp = point.timestamp
            } else {
                timestamp = Int64(targetDate.timeIntervalSince1970)
            }
            
        case .month:
            // Find point by day of month
            guard let startDate = monthStartDate else { return }
            let calendar = Calendar.current
            let dayIndex = Int(round(entry.x))
            let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: startDate)!
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            if let point = currentDataPoints.first(where: {
                let pointDate = Date(timeIntervalSince1970: TimeInterval($0.timestamp))
                return pointDate >= dayStart && pointDate < dayEnd
            }) {
                timestamp = point.timestamp
            } else {
                timestamp = Int64(targetDate.timeIntervalSince1970)
            }
        }
        
        let point = VitalDataPoint(timestamp: timestamp, value: Double(value))
        updateLabelsForDataPoint(point)
    }
}

// MARK: - Value Formatters
class TimeValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let hour = Int(value)
        let minute = Int((value - Double(hour)) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
}

class WeekValueFormatter: AxisValueFormatter {
    let dayLabels: [String]
    
    init(dayLabels: [String]) {
        self.dayLabels = dayLabels
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard index >= 0 && index < dayLabels.count else { return "" }
        return dayLabels[index]
    }
}

class MonthValueFormatter: AxisValueFormatter {
    let daysInMonth: Int
    
    init(daysInMonth: Int) {
        self.daysInMonth = daysInMonth
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(Int(value) + 1)
    }
}

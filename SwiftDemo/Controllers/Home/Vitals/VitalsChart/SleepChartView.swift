import UIKit
import Charts

class SleepChartView: UIView, ChartViewDelegate {
    
    // MARK: - Properties
    private var sleepSegments: [SleepChartSegment] = []
    private var sessions: [SleepSessionEntity] = []
    private var earliestTime: Date?
    private var latestTime: Date?
    
    // Callback for showing selected sleep info
    var onSleepSegmentSelected: ((Date, String) -> Void)?
    
    // MARK: - UI Components
    private let lineChart = LineChartView()
    private let customLegendStack = UIStackView()
    
    // MARK: - Sleep Colors
    private let deepSleepColor = UIColor(red: 0.48, green: 0.41, blue: 0.93, alpha: 1.0) // #7B68EE
    private let lightSleepColor = UIColor(red: 0.0, green: 0.90, blue: 1.0, alpha: 1.0) // #00E5FF
    private let remSleepColor = UIColor(red: 0.69, green: 0.61, blue: 0.85, alpha: 1.0) // #B19CD9
    private let awakeColor = UIColor(red: 0.56, green: 0.93, blue: 0.56, alpha: 1.0) // #90EE90
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupChart()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupChart()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineChart)
        
        // Custom legend stack
        customLegendStack.axis = .horizontal
        customLegendStack.distribution = .fillEqually
        customLegendStack.alignment = .center
        customLegendStack.spacing = 4
        customLegendStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customLegendStack)
        
        // Create legend items
        let lightLabel = createLegendLabel(text: "Light sleep", color: lightSleepColor)
        let deepLabel = createLegendLabel(text: "Deep sleep", color: deepSleepColor)
        let remLabel = createLegendLabel(text: "REM", color: remSleepColor)
        let awakeLabel = createLegendLabel(text: "Awake", color: awakeColor)
        
        [lightLabel, deepLabel, remLabel, awakeLabel].forEach {
            customLegendStack.addArrangedSubview($0)
        }
        
        NSLayoutConstraint.activate([
            lineChart.topAnchor.constraint(equalTo: topAnchor),
            lineChart.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineChart.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineChart.bottomAnchor.constraint(equalTo: customLegendStack.topAnchor, constant: -4),
            
            customLegendStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            customLegendStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            customLegendStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            customLegendStack.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func createLegendLabel(text: String, color: UIColor) -> UIView {
        let container = UIView()
        
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dot)
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
            
            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 4),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func setupChart() {
        lineChart.delegate = self
        lineChart.backgroundColor = .clear
        lineChart.dragEnabled = true
        lineChart.setScaleEnabled(false)
        lineChart.pinchZoomEnabled = false
        lineChart.doubleTapToZoomEnabled = false
        lineChart.chartDescription.enabled = false
        lineChart.highlightPerTapEnabled = true
        lineChart.highlightPerDragEnabled = true
        
        // Legend (disabled - using custom legend)
        lineChart.legend.enabled = false
        
        // X-Axis (Time)
        let xAxis = lineChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 9)
        xAxis.labelTextColor = .gray
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineColor = .lightGray
        xAxis.granularity = 1
        xAxis.labelCount = 6
        xAxis.avoidFirstLastClippingEnabled = false
        xAxis.forceLabelsEnabled = true
        xAxis.valueFormatter = SleepTimeAxisFormatter()
        
        // Left Y-Axis (Sleep stages as levels)
        let leftAxis = lineChart.leftAxis
        leftAxis.enabled = false
        
        // Right Y-Axis
        let rightAxis = lineChart.rightAxis
        rightAxis.enabled = false
        
        // Offsets (increased left/right to prevent label clipping)
        lineChart.extraTopOffset = 8
        lineChart.extraBottomOffset = 4
        lineChart.extraLeftOffset = 20
        lineChart.extraRightOffset = 20
    }
    
    // MARK: - Public Methods
    
    /// Load multiple sleep sessions for a day and display chart
    func loadSleepSessions(sessions: [SleepSessionEntity]) {
        // Clear any previous selection/highlight to prevent index out of range errors
        lineChart.highlightValue(nil)
        
        guard !sessions.isEmpty else {
            clearChart()
            return
        }
        
        self.sessions = sessions
        print("[SleepChartView] Loading \(sessions.count) session(s)")
        
        // Convert all sessions to chart segments
        var allSegments: [SleepChartSegment] = []
        
        for session in sessions {
            let segments = convertToChartSegments(session: session)
            allSegments.append(contentsOf: segments)
        }
        
        // Sort by start time
        sleepSegments = allSegments.sorted { $0.startTime < $1.startTime }
        
        // Find time range
        if let first = sleepSegments.first, let last = sleepSegments.last {
            earliestTime = first.startTime
            latestTime = last.endTime
        }
        
        // Update chart
        updateChartData()
    }
    
    /// Load sleep data and display chart (single session - backward compatibility)
    func loadSleepSession(session: SleepSessionEntity) {
        loadSleepSessions(sessions: [session])
    }
    
    /// Clear chart
    func clearChart() {
        // Clear selection first
        lineChart.highlightValue(nil)
        
        sleepSegments = []
        sessions = []
        earliestTime = nil
        latestTime = nil
        lineChart.data = nil
        lineChart.notifyDataSetChanged()
    }
    
    // MARK: - Data Conversion
    
    private func convertToChartSegments(session: SleepSessionEntity) -> [SleepChartSegment] {
        guard let details = session.details?.allObjects as? [SleepDetailEntity] else {
            print("[SleepChartView] No details found")
            return []
        }
        
        // Sort by start time
        let sortedDetails = details.sorted { $0.startTime < $1.startTime }
        
        var segments: [SleepChartSegment] = []
        
        for detail in sortedDetails {
            let segment = SleepChartSegment(
                startTime: Date(timeIntervalSince1970: TimeInterval(detail.startTime)),
                endTime: Date(timeIntervalSince1970: TimeInterval(detail.endTime)),
                duration: Int(detail.duration),
                sleepType: Int(detail.sleepType)
            )
            segments.append(segment)
        }
        
        print("[SleepChartView] Converted \(segments.count) segments")
        return segments
    }
    
    private func updateChartData() {
        guard !sleepSegments.isEmpty, let startTime = earliestTime, let endTime = latestTime else {
            lineChart.data = nil
            lineChart.notifyDataSetChanged()
            return
        }
        
        print("[SleepChartView] Updating chart with \(sleepSegments.count) segments")
        
        // Reference start time for x-axis calculation
        let referenceTime = startTime.timeIntervalSince1970
        
        var dataSets: [LineChartDataSet] = []
        
        // Track which sleep types we've seen to avoid duplicate legend entries
        var addedTypes: Set<Int> = []
        
        // Create a separate dataset for each segment to get proper coloring
        for (index, segment) in sleepSegments.enumerated() {
            let xStart = segment.startTime.timeIntervalSince1970 - referenceTime
            let xEnd = segment.endTime.timeIntervalSince1970 - referenceTime
            
            // Safety check
            guard xStart >= 0, xEnd > xStart else {
                print("[SleepChartView] ⚠️ Invalid segment \(index): xStart=\(xStart), xEnd=\(xEnd)")
                continue
            }
            
            let yValue: Double
            switch segment.sleepType {
            case 1: yValue = 4.0
            case 2: yValue = 3.0
            case 3: yValue = 2.0
            case 4: yValue = 1.0
            default: yValue = 0.5
            }
            
            var entries: [ChartDataEntry] = []
            let startEntry = ChartDataEntry(x: xStart, y: yValue)
            startEntry.data = segment.sleepType as AnyObject
            entries.append(startEntry)
            
            let endEntry = ChartDataEntry(x: xEnd, y: yValue)
            endEntry.data = segment.sleepType as AnyObject
            entries.append(endEntry)
            
            // Check if this is the first occurrence of this sleep type
            let isFirstOccurrence = !addedTypes.contains(segment.sleepType)
            
            // Set label only for first occurrence of each type (for legend)
            let label = isFirstOccurrence ? getSleepTypeName(segment.sleepType) : ""
            
            let segmentDataSet = LineChartDataSet(entries: entries, label: label)
            segmentDataSet.drawCirclesEnabled = false
            segmentDataSet.drawValuesEnabled = false
            segmentDataSet.lineWidth = 0
            segmentDataSet.drawFilledEnabled = true
            segmentDataSet.fillColor = getColorForSleepType(segment.sleepType)
            segmentDataSet.fillAlpha = 1.0
            segmentDataSet.highlightEnabled = true
            segmentDataSet.highlightColor = UIColor.black.withAlphaComponent(0.5)
            segmentDataSet.highlightLineWidth = 1
            segmentDataSet.mode = .linear
            
            // Set color for legend (only for first occurrence)
            if isFirstOccurrence {
                segmentDataSet.setColor(getColorForSleepType(segment.sleepType))
                addedTypes.insert(segment.sleepType)
            } else {
                // For duplicates, set transparent color to avoid multiple legend entries
                segmentDataSet.setColor(.clear)
            }
            
            dataSets.append(segmentDataSet)
        }
        
        guard !dataSets.isEmpty else {
            print("[SleepChartView] ⚠️ No valid datasets created")
            lineChart.data = nil
            lineChart.notifyDataSetChanged()
            return
        }
        
        // Set chart data
        let chartData = LineChartData(dataSets: dataSets)
        lineChart.data = chartData
        
        // Configure X-axis range
        let totalDuration = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
        lineChart.xAxis.axisMinimum = -totalDuration * 0.02
        lineChart.xAxis.axisMaximum = totalDuration * 1.02
        
        // Configure Y-axis range
        lineChart.leftAxis.axisMinimum = 0
        lineChart.leftAxis.axisMaximum = 5
        
        // Update time formatter
        if let formatter = lineChart.xAxis.valueFormatter as? SleepTimeAxisFormatter {
            formatter.startTime = startTime
        }
        
        lineChart.notifyDataSetChanged()
        print("[SleepChartView] ✅ Chart updated successfully")
    }
    
    private func getColorForSleepType(_ type: Int) -> UIColor {
        switch type {
        case 1: return deepSleepColor
        case 2: return lightSleepColor
        case 3: return remSleepColor
        case 4: return awakeColor
        default: return .lightGray
        }
    }
    
    private func getSleepTypeName(_ type: Int) -> String {
        switch type {
        case 1: return "Deep sleep"
        case 2: return "Light sleep"
        case 3: return "REM"
        case 4: return "Awake"
        default: return "Unknown"
        }
    }
    
    // MARK: - ChartViewDelegate
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let startTime = earliestTime else {
            print("[SleepChartView] ⚠️ No start time available")
            return
        }
        
        // Validate chart data exists
        guard let chartData = chartView.data else {
            print("[SleepChartView] ⚠️ No chart data available")
            return
        }
        
        // Validate highlight data with proper bounds checking
        guard highlight.dataSetIndex >= 0,
              highlight.dataSetIndex < chartData.dataSetCount,
              highlight.dataSetIndex < chartData.dataSets.count else {
            print("[SleepChartView] ⚠️ Invalid highlight index: \(highlight.dataSetIndex), dataSetCount: \(chartData.dataSetCount)")
            return
        }
        
        // Calculate actual time from x value
        let timeOffset = entry.x
        let actualTime = startTime.addingTimeInterval(timeOffset)
        
        // Get sleep type from entry data
        let sleepType = entry.data as? Int ?? 0
        let sleepTypeName = getSleepTypeName(sleepType)
        
        // Trigger callback
        onSleepSegmentSelected?(actualTime, sleepTypeName)
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Optional: Clear selection display
    }
}

// MARK: - Chart Data Model

struct SleepChartSegment {
    let startTime: Date
    let endTime: Date
    let duration: Int // seconds
    let sleepType: Int // 1=Deep, 2=Light, 3=REM, 4=Awake
}

// MARK: - Time Axis Formatter

class SleepTimeAxisFormatter: AxisValueFormatter {
    var startTime: Date?
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let startTime = startTime else { return "" }
        
        let date = startTime.addingTimeInterval(value)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

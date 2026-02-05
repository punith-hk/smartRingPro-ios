import UIKit

/// Blood Pressure Chart - Shows TWO lines (Systolic and Diastolic)
/// Similar to VitalsLineChartView but handles dual data series
class BloodPressureDualLineChartView: UIView {
    
    // MARK: - Data Models
    
    struct BloodPressureDataPoint {
        let timestamp: Int64
        let systolicValue: Double
        let diastolicValue: Double
    }
    
    // MARK: - Properties
    
    private var dataPoints: [BloodPressureDataPoint] = []
    private let topPadding: CGFloat = 40
    private let bottomPadding: CGFloat = 60
    private let sidePadding: CGFloat = 20
    
    private let systolicColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0) // Red
    private let diastolicColor = UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0) // Blue
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    // MARK: - Public Methods
    
    func updateData(_ data: [BloodPressureDataPoint]) {
        self.dataPoints = data.sorted { $0.timestamp < $1.timestamp }
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !dataPoints.isEmpty else {
            drawEmptyState(in: rect)
            return
        }
        
        let chartRect = CGRect(
            x: sidePadding,
            y: topPadding,
            width: rect.width - 2 * sidePadding,
            height: rect.height - topPadding - bottomPadding
        )
        
        // Draw grid and axes
        drawGrid(in: chartRect)
        drawYAxisLabels(in: chartRect)
        drawXAxisLabels(in: chartRect)
        
        // Draw both lines
        drawSystolicLine(in: chartRect)
        drawDiastolicLine(in: chartRect)
        
        // Draw legend
        drawLegend(in: rect)
    }
    
    private func drawEmptyState(in rect: CGRect) {
        let label = "No data available"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        
        let size = label.size(withAttributes: attributes)
        let point = CGPoint(
            x: (rect.width - size.width) / 2,
            y: (rect.height - size.height) / 2
        )
        
        label.draw(at: point, withAttributes: attributes)
    }
    
    private func drawGrid(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(0.5)
        
        // Horizontal grid lines (5 lines)
        for i in 0...4 {
            let y = rect.minY + (rect.height / 4) * CGFloat(i)
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        
        context.strokePath()
    }
    
    private func drawYAxisLabels(in rect: CGRect) {
        let systolicValues = dataPoints.map { $0.systolicValue }
        let diastolicValues = dataPoints.map { $0.diastolicValue }
        let allValues = systolicValues + diastolicValues
        
        guard let minValue = allValues.min(), let maxValue = allValues.max() else { return }
        
        let range = maxValue - minValue
        let paddedMin = max(0, minValue - range * 0.1)
        let paddedMax = maxValue + range * 0.1
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        for i in 0...4 {
            let value = paddedMax - (paddedMax - paddedMin) * (Double(i) / 4.0)
            let label = String(format: "%.0f", value)
            
            let y = rect.minY + (rect.height / 4) * CGFloat(i) - 6
            label.draw(at: CGPoint(x: 2, y: y), withAttributes: attributes)
        }
    }
    
    private func drawXAxisLabels(in rect: CGRect) {
        guard !dataPoints.isEmpty else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        let labelCount = min(5, dataPoints.count)
        let step = max(1, dataPoints.count / labelCount)
        
        for i in 0..<labelCount {
            let index = min(i * step, dataPoints.count - 1)
            let dataPoint = dataPoints[index]
            
            let date = Date(timeIntervalSince1970: TimeInterval(dataPoint.timestamp))
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let label = formatter.string(from: date)
            
            let x = rect.minX + (rect.width / CGFloat(labelCount - 1)) * CGFloat(i)
            let y = rect.maxY + 10
            
            let size = label.size(withAttributes: attributes)
            label.draw(at: CGPoint(x: x - size.width / 2, y: y), withAttributes: attributes)
        }
    }
    
    private func drawSystolicLine(in rect: CGRect) {
        guard !dataPoints.isEmpty else { return }
        
        let systolicValues = dataPoints.map { $0.systolicValue }
        let allValues = dataPoints.flatMap { [$0.systolicValue, $0.diastolicValue] }
        
        guard let minValue = allValues.min(), let maxValue = allValues.max() else { return }
        
        let range = maxValue - minValue
        let paddedMin = max(0, minValue - range * 0.1)
        let paddedMax = maxValue + range * 0.1
        
        let path = UIBezierPath()
        
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = rect.minX + (rect.width / CGFloat(max(1, dataPoints.count - 1))) * CGFloat(index)
            let normalizedValue = (dataPoint.systolicValue - paddedMin) / (paddedMax - paddedMin)
            let y = rect.maxY - CGFloat(normalizedValue) * rect.height
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        systolicColor.setStroke()
        path.lineWidth = 2.0
        path.stroke()
        
        // Draw dots
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = rect.minX + (rect.width / CGFloat(max(1, dataPoints.count - 1))) * CGFloat(index)
            let normalizedValue = (dataPoint.systolicValue - paddedMin) / (paddedMax - paddedMin)
            let y = rect.maxY - CGFloat(normalizedValue) * rect.height
            
            let dotPath = UIBezierPath(
                arcCenter: CGPoint(x: x, y: y),
                radius: 4,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            systolicColor.setFill()
            dotPath.fill()
            
            UIColor.white.setStroke()
            dotPath.lineWidth = 1.5
            dotPath.stroke()
        }
    }
    
    private func drawDiastolicLine(in rect: CGRect) {
        guard !dataPoints.isEmpty else { return }
        
        let diastolicValues = dataPoints.map { $0.diastolicValue }
        let allValues = dataPoints.flatMap { [$0.systolicValue, $0.diastolicValue] }
        
        guard let minValue = allValues.min(), let maxValue = allValues.max() else { return }
        
        let range = maxValue - minValue
        let paddedMin = max(0, minValue - range * 0.1)
        let paddedMax = maxValue + range * 0.1
        
        let path = UIBezierPath()
        
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = rect.minX + (rect.width / CGFloat(max(1, dataPoints.count - 1))) * CGFloat(index)
            let normalizedValue = (dataPoint.diastolicValue - paddedMin) / (paddedMax - paddedMin)
            let y = rect.maxY - CGFloat(normalizedValue) * rect.height
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        diastolicColor.setStroke()
        path.lineWidth = 2.0
        path.stroke()
        
        // Draw dots
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = rect.minX + (rect.width / CGFloat(max(1, dataPoints.count - 1))) * CGFloat(index)
            let normalizedValue = (dataPoint.diastolicValue - paddedMin) / (paddedMax - paddedMin)
            let y = rect.maxY - CGFloat(normalizedValue) * rect.height
            
            let dotPath = UIBezierPath(
                arcCenter: CGPoint(x: x, y: y),
                radius: 4,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            diastolicColor.setFill()
            dotPath.fill()
            
            UIColor.white.setStroke()
            dotPath.lineWidth = 1.5
            dotPath.stroke()
        }
    }
    
    private func drawLegend(in rect: CGRect) {
        let legendY = rect.maxY - bottomPadding + 45
        let legendSpacing: CGFloat = 100
        let startX = (rect.width - legendSpacing) / 2
        
        // Systolic legend
        drawLegendItem(
            color: systolicColor,
            label: "Systolic BP",
            x: startX,
            y: legendY
        )
        
        // Diastolic legend
        drawLegendItem(
            color: diastolicColor,
            label: "Diastolic BP",
            x: startX + legendSpacing,
            y: legendY
        )
    }
    
    private func drawLegendItem(color: UIColor, label: String, x: CGFloat, y: CGFloat) {
        // Draw colored square
        let squareSize: CGFloat = 12
        let squarePath = UIBezierPath(
            rect: CGRect(x: x, y: y - squareSize / 2, width: squareSize, height: squareSize)
        )
        color.setFill()
        squarePath.fill()
        
        // Draw label
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        
        label.draw(at: CGPoint(x: x + squareSize + 6, y: y - 8), withAttributes: attributes)
    }
}

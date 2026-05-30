import UIKit

/// Semi-circular BMI gauge drawn entirely in Core Graphics.
/// Set `bmi`, `heightCm`, and `weightKg` to update the display.
final class BMIMeterView: UIView {

    // MARK: - Public data

    var bmi: CGFloat = 0      { didSet { setNeedsDisplay() } }
    var heightCm: Int = 0     { didSet { setNeedsDisplay() } }
    var weightKg: Int = 0     { didSet { setNeedsDisplay() } }

    // MARK: - Segment definitions

    private struct Segment {
        let color: UIColor
        let lines: [String]
        let lo: CGFloat
        let hi: CGFloat
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw   // re-draw when bounds change (e.g. height constraint update)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .redraw
    }

    private let segments: [Segment] = [
        Segment(color: UIColor(red: 79/255,  green: 195/255, blue: 247/255, alpha: 1),
                lines: ["UNDER", "WEIGHT", "< 18.5"], lo: 0,    hi: 18.5),
        Segment(color: UIColor(red: 76/255,  green: 175/255, blue: 80/255,  alpha: 1),
                lines: ["NORMAL", "18.5–24.9"],        lo: 18.5, hi: 25),
        Segment(color: UIColor(red: 255/255, green: 193/255, blue: 7/255,   alpha: 1),
                lines: ["OVER", "WEIGHT", "25–29.9"],  lo: 25,   hi: 30),
        Segment(color: UIColor(red: 255/255, green: 112/255, blue: 67/255,  alpha: 1),
                lines: ["OBESE", "30–39.9"],            lo: 30,   hi: 40),
        Segment(color: UIColor(red: 244/255, green: 67/255,  blue: 54/255,  alpha: 1),
                lines: ["SEVERELY", "OBESE", "≥ 40"],  lo: 40,   hi: 50),
    ]

    // MARK: - Layout helpers

    /// Height needed for a given display width (used by the VC to size this view).
    func neededHeight(for width: CGFloat) -> CGFloat {
        let radius      = width  * 0.36
        let stroke      = radius * 0.60
        let topPad      = stroke / 2 + 8
        let arcBottom   = topPad + radius + stroke / 2
        let circleR = stroke * 0.22
        let labelH  = stroke * 0.18
        let valueH  = stroke * 0.42
        let hwH     = stroke * 0.16
        let statusH = stroke * 0.24
        // cy = topPad + radius; text starts at cy + circleR + 6 (just below circle)
        // gap BMI→value = 10; h/w row bottom = hwH*1.5 below value bottom
        return topPad + radius + circleR + 6 + labelH + 10 + valueH + 4 + (hwH * 1.5) + 4 + statusH + 8
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let w           = rect.width
        let radius      = w  * 0.36
        let stroke      = radius * 0.60
        let topPad      = stroke / 2 + 8
        let cx          = w / 2
        let cy          = topPad + radius

        drawArcs(cx: cx, cy: cy, radius: radius, strokeWidth: stroke)
        drawSegmentLabels(cx: cx, cy: cy, radius: radius, strokeWidth: stroke)
        drawNeedle(cx: cx, cy: cy, radius: radius, strokeWidth: stroke)
        drawCenterCircle(cx: cx, cy: cy, strokeWidth: stroke)
        drawTextArea(cx: cx, cy: cy, radius: radius, strokeWidth: stroke, ctx: ctx)
    }

    // MARK: - Arc segments

    private func drawArcs(cx: CGFloat, cy: CGFloat, radius: CGFloat, strokeWidth: CGFloat) {
        let startDeg: CGFloat = 180
        let sweep:    CGFloat = 36

        for (i, seg) in segments.enumerated() {
            let start = deg2rad(startDeg + CGFloat(i) * sweep)
            let end   = deg2rad(startDeg + CGFloat(i + 1) * sweep)

            let path = UIBezierPath(
                arcCenter:  CGPoint(x: cx, y: cy),
                radius:     radius,
                startAngle: start,
                endAngle:   end,
                clockwise:  true
            )
            path.lineWidth   = strokeWidth
            path.lineCapStyle = .butt
            seg.color.setStroke()
            path.stroke()
        }
    }

    // MARK: - Segment labels

    private func drawSegmentLabels(cx: CGFloat, cy: CGFloat, radius: CGFloat, strokeWidth: CGFloat) {
        let labelFontSize = max(7, strokeWidth * 0.14)
        let font = UIFont.systemFont(ofSize: labelFontSize, weight: .bold)

        for (i, seg) in segments.enumerated() {
            let midDeg: CGFloat = 180 + CGFloat(i) * 36 + 18
            let midRad = deg2rad(midDeg)
            let labelX = cx + radius * cos(midRad)
            let labelY = cy + radius * sin(midRad)

            drawMultilineCenter(lines: seg.lines,
                                center: CGPoint(x: labelX, y: labelY),
                                font: font,
                                color: .white,
                                lineSpacing: 1)
        }
    }

    // MARK: - Needle

    private func drawNeedle(cx: CGFloat, cy: CGFloat, radius: CGFloat, strokeWidth: CGFloat) {
        let angleDeg = bmi > 0 ? bmiToAngleDeg(bmi) : 180
        let angleRad = deg2rad(angleDeg)
        let needleLen     = radius * 0.88
        let baseHalfWidth = radius * 0.065

        let perpAngle = angleRad + .pi / 2

        let tipPt   = CGPoint(x: cx + needleLen * cos(angleRad), y: cy + needleLen * sin(angleRad))
        let base1   = CGPoint(x: cx + baseHalfWidth * cos(perpAngle), y: cy + baseHalfWidth * sin(perpAngle))
        let base2   = CGPoint(x: cx - baseHalfWidth * cos(perpAngle), y: cy - baseHalfWidth * sin(perpAngle))

        let path = UIBezierPath()
        path.move(to: tipPt)
        path.addLine(to: base1)
        path.addLine(to: base2)
        path.close()

        UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1).setFill()
        path.fill()
    }

    // MARK: - Center circle

    private func drawCenterCircle(cx: CGFloat, cy: CGFloat, strokeWidth: CGFloat) {
        let circleR    = strokeWidth * 0.22
        let borderW    = max(1, strokeWidth * 0.025)
        let dotR       = circleR * 0.35

        let outerPath = UIBezierPath(
            arcCenter: CGPoint(x: cx, y: cy),
            radius: circleR - borderW / 2,
            startAngle: 0, endAngle: .pi * 2, clockwise: true
        )
        UIColor.white.setFill()
        outerPath.fill()
        UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1).setStroke()
        outerPath.lineWidth = borderW
        outerPath.stroke()

        let dotPath = UIBezierPath(
            arcCenter: CGPoint(x: cx, y: cy),
            radius: dotR,
            startAngle: 0, endAngle: .pi * 2, clockwise: true
        )
        UIColor.black.setFill()
        dotPath.fill()
    }

    // MARK: - Text area

    private func drawTextArea(cx: CGFloat, cy: CGFloat, radius: CGFloat, strokeWidth: CGFloat, ctx: CGContext) {
        let circleR        = strokeWidth * 0.22
        let bmiLabelFontSz = max(9,  strokeWidth * 0.18)
        let valueFontSz    = max(18, strokeWidth * 0.42)
        let unitFontSz     = max(9,  strokeWidth * 0.16)
        let hwFontSz       = max(9,  strokeWidth * 0.16)
        let statusFontSz   = max(11, strokeWidth * 0.24)

        let topY = cy + circleR + 6   // sit just below the center circle

        // "BMI" label
        let bmiLabelColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
        let bmiLabelY = topY + bmiLabelFontSz / 2
        drawCenteredText("BMI",
                         center: CGPoint(x: cx, y: bmiLabelY),
                         font: .systemFont(ofSize: bmiLabelFontSz, weight: .semibold),
                         color: bmiLabelColor)

        // Numeric value + unit
        let bmiText = bmi > 0 ? String(format: "%.1f", bmi) : "--"
        let valueY  = bmiLabelY + bmiLabelFontSz / 2 + 10 + valueFontSz / 2

        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: valueFontSz),
            .foregroundColor: UIColor.black
        ]
        let unitAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: unitFontSz),
            .foregroundColor: UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
        ]
        let combo = NSMutableAttributedString(string: bmiText, attributes: valueAttr)
        combo.append(NSAttributedString(string: " kg/m²", attributes: unitAttr))
        drawAttributedCenter(combo, at: CGPoint(x: cx, y: valueY))

        // Height / Weight row
        let hwY = valueY + valueFontSz / 2 + 4 + hwFontSz
        let hwColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
        let hwFont  = UIFont.boldSystemFont(ofSize: hwFontSz)

        if heightCm > 0 {
            drawCenteredText("\(heightCm) cm",
                             center: CGPoint(x: cx - bounds.width * 0.18, y: hwY),
                             font: hwFont, color: hwColor)
        }
        if weightKg > 0 {
            drawCenteredText("\(weightKg) kg",
                             center: CGPoint(x: cx + bounds.width * 0.18, y: hwY),
                             font: hwFont, color: hwColor)
        }

        // Status text
        let (statusText, statusColor) = bmiCategory()
        let statusY = hwY + hwFontSz / 2 + 4 + statusFontSz / 2
        drawCenteredText(statusText,
                         center: CGPoint(x: cx, y: statusY),
                         font: .boldSystemFont(ofSize: statusFontSz),
                         color: statusColor)
    }

    // MARK: - Helpers

    private func deg2rad(_ degrees: CGFloat) -> CGFloat {
        degrees * .pi / 180
    }

    private func bmiToAngleDeg(_ value: CGFloat) -> CGFloat {
        let clamped = max(0, min(50, value))
        let breakpoints: [CGFloat] = [0, 18.5, 25, 30, 40, 50]
        for i in 0..<5 {
            let lo = breakpoints[i]
            let hi = breakpoints[i + 1]
            if clamped <= hi {
                let fraction = (clamped - lo) / (hi - lo)
                return 180 + CGFloat(i) * 36 + fraction * 36
            }
        }
        return 360
    }

    private func bmiCategory() -> (String, UIColor) {
        if bmi <= 0  { return ("--",               UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)) }
        if bmi < 18.5 { return ("Underweight",     UIColor(red: 79/255,  green: 195/255, blue: 247/255, alpha: 1)) }
        if bmi < 25   { return ("Normal",          UIColor(red: 76/255,  green: 175/255, blue: 80/255,  alpha: 1)) }
        if bmi < 30   { return ("Overweight",      UIColor(red: 255/255, green: 193/255, blue: 7/255,   alpha: 1)) }
        if bmi < 40   { return ("Obese",           UIColor(red: 255/255, green: 112/255, blue: 67/255,  alpha: 1)) }
        return            ("Severely Obese",       UIColor(red: 244/255, green: 67/255,  blue: 54/255,  alpha: 1))
    }

    private func drawCenteredText(_ text: String, center: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let str  = NSAttributedString(string: text, attributes: attrs)
        let size = str.boundingRect(with: CGSize(width: 300, height: 200),
                                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                                    context: nil).size
        str.draw(at: CGPoint(x: center.x - size.width / 2,
                             y: center.y - size.height / 2))
    }

    private func drawMultilineCenter(lines: [String], center: CGPoint, font: UIFont, color: UIColor, lineSpacing: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let lineHeight = font.lineHeight + lineSpacing
        let totalH = lineHeight * CGFloat(lines.count) - lineSpacing
        var y = center.y - totalH / 2

        for line in lines {
            let str  = NSAttributedString(string: line, attributes: attrs)
            let size = str.boundingRect(with: CGSize(width: 200, height: 100),
                                        options: [.usesLineFragmentOrigin],
                                        context: nil).size
            str.draw(at: CGPoint(x: center.x - size.width / 2, y: y))
            y += lineHeight
        }
    }

    private func drawAttributedCenter(_ str: NSAttributedString, at center: CGPoint) {
        let size = str.boundingRect(with: CGSize(width: 400, height: 100),
                                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                                    context: nil).size
        str.draw(at: CGPoint(x: center.x - size.width / 2,
                             y: center.y - size.height / 2))
    }
}

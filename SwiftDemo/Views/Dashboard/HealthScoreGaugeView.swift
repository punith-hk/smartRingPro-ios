import UIKit

/// Semicircular gauge showing the health score.
/// Arc spans ~220° (110° each side from bottom centre).
/// Left→right gradient: blue (#4FC3F7) → green (#66BB6A).
/// Unfilled remainder: light grey. White circle container behind numbers.
final class HealthScoreGaugeView: UIView {

    // MARK: - Public state
    var score: Int = 0 { didSet { updateAll() } }
    var yesterdayScore: Int = 0 { didSet { updateAll() } }

    // MARK: - Sub-views
    private let arcLayer   = CAShapeLayer()   // unfilled track
    private let fillLayer  = CAGradientLayer() // gradient fill mask
    private let fillMask   = CAShapeLayer()   // arc mask for gradient

    private let whiteCircle  = UIView()
    private let scoreLabel   = UILabel()      // "80"
    private let outOfLabel   = UILabel()      // "/100"
    private let titleLabel   = UILabel()      // "HEALTH SCORE"
    private let badgeLabel   = UILabel()      // "Good"
    private let compareLabel = UILabel()      // "↑ 3pts vs Yesterday"

    // MARK: - Constants
    private let startAngle: CGFloat  = .pi * (5.0 / 6.0)   // 8 o'clock (150° from right)
    private let endAngle: CGFloat    = .pi * (13.0 / 6.0)  // 4 o'clock — 240° span
    private let lineWidth: CGFloat   = 30

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupLayers()
        setupSubviews()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutArc()
        layoutWhiteCircle()
        layoutLabels()
    }

    // MARK: - Arc Layers
    private func setupLayers() {
        // Track (grey background arc)
        arcLayer.fillColor   = UIColor.clear.cgColor
        arcLayer.strokeColor = UIColor(white: 0.88, alpha: 1).cgColor
        arcLayer.lineWidth   = lineWidth
        arcLayer.lineCap     = .round
        layer.addSublayer(arcLayer)

        // Gradient layer clipped to arc shape
        fillLayer.colors = [
            UIColor(red: 0.31, green: 0.76, blue: 0.97, alpha: 1).cgColor,  // blue
            UIColor(red: 0.40, green: 0.73, blue: 0.41, alpha: 1).cgColor   // green
        ]
        fillLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fillLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        fillLayer.mask       = fillMask

        fillMask.fillColor   = UIColor.clear.cgColor
        fillMask.strokeColor = UIColor.white.cgColor
        fillMask.lineWidth   = lineWidth
        fillMask.lineCap     = .round

        layer.addSublayer(fillLayer)
    }

    private func layoutArc() {
        let r    = min(bounds.width, bounds.height) / 2 - lineWidth / 2 - 4
        let cx   = bounds.midX
        let cy   = r + lineWidth / 2 + 2   // top of arc flush with view top edge
        let centre = CGPoint(x: cx, y: cy)

        let trackPath = UIBezierPath(
            arcCenter: centre,
            radius: r,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        arcLayer.path = trackPath.cgPath

        let fillPath = UIBezierPath(
            arcCenter: centre,
            radius: r,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        fillMask.path = fillPath.cgPath

        // Animate stroke end to score fraction
        let fraction = max(0, min(1, CGFloat(score) / 100))
        fillMask.strokeEnd = fraction

        fillLayer.frame = bounds
        arcLayer.frame  = bounds
    }

    private func layoutWhiteCircle() {
        let size: CGFloat = bounds.width * 0.38
        let r    = min(bounds.width, bounds.height) / 2 - lineWidth / 2 - 4
        let cy   = r + lineWidth / 2 + 2
        whiteCircle.frame = CGRect(
            x: bounds.midX - size / 2,
            y: cy - size / 2,
            width: size,
            height: size
        )
        whiteCircle.layer.cornerRadius = size / 2
    }

    private func layoutLabels() {
        guard whiteCircle.frame != .zero else { return }
        let cx = whiteCircle.frame.midX
        let cy = whiteCircle.frame.midY

        // Score row  "80  /100"
        scoreLabel.sizeToFit()
        outOfLabel.sizeToFit()
        let gap: CGFloat = 2
        let rowW = scoreLabel.bounds.width + gap + outOfLabel.bounds.width
        let rowY = cy - 58
        scoreLabel.frame   = CGRect(x: cx - rowW / 2, y: rowY, width: scoreLabel.bounds.width, height: scoreLabel.bounds.height)
        outOfLabel.frame   = CGRect(x: scoreLabel.frame.maxX + gap, y: rowY + 16, width: outOfLabel.bounds.width, height: outOfLabel.bounds.height)

        // "HEALTH SCORE"
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: cx - titleLabel.bounds.width / 2,
                                  y: scoreLabel.frame.maxY + 2,
                                  width: titleLabel.bounds.width,
                                  height: titleLabel.bounds.height)

        // Badge
        badgeLabel.sizeToFit()
        let bW = badgeLabel.bounds.width + 20
        let bH: CGFloat = 22
        badgeLabel.frame = CGRect(x: cx - bW / 2,
                                  y: titleLabel.frame.maxY + 12,
                                  width: bW,
                                  height: bH)

        // Comparison
        compareLabel.sizeToFit()
        compareLabel.frame = CGRect(x: cx - compareLabel.bounds.width / 2,
                                    y: badgeLabel.frame.maxY + 12,
                                    width: compareLabel.bounds.width,
                                    height: compareLabel.bounds.height)
    }

    // MARK: - Sub-views Setup
    private func setupSubviews() {
        // Inner circle — transparent, no background
        whiteCircle.backgroundColor  = .clear
        whiteCircle.layer.shadowOpacity = 0
        addSubview(whiteCircle)

        // Score value label
        scoreLabel.font      = .systemFont(ofSize: 46, weight: .bold)
        scoreLabel.textColor = .black
        scoreLabel.text      = "0"
        addSubview(scoreLabel)

        // "/100"
        outOfLabel.font      = .systemFont(ofSize: 22, weight: .medium)
        outOfLabel.textColor = UIColor(white: 0.37, alpha: 1)
        outOfLabel.text      = "/100"
        addSubview(outOfLabel)

        // "HEALTH SCORE"
        titleLabel.font      = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.text      = "HEALTH SCORE"
        addSubview(titleLabel)

        // Badge
        badgeLabel.font            = .systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.textAlignment   = .center
        badgeLabel.layer.cornerRadius = 11
        badgeLabel.layer.masksToBounds = true
        addSubview(badgeLabel)

        // Comparison
        compareLabel.font      = .systemFont(ofSize: 11)
        compareLabel.textColor = UIColor(white: 0.3, alpha: 1)
        addSubview(compareLabel)

        updateAll()
    }

    // MARK: - Update
    private func updateAll() {
        scoreLabel.text = "\(score)"
        applyBadge()
        applyComparison()
        setNeedsLayout()
    }

    private func applyBadge() {
        let (text, textColor, bgColor) = scoreStatus(score)
        badgeLabel.text            = text
        badgeLabel.textColor       = textColor
        badgeLabel.backgroundColor = bgColor
    }

    private func applyComparison() {
        let diff = score - yesterdayScore
        if diff == 0 {
            compareLabel.attributedText = nil
            compareLabel.text      = "No change vs Yesterday"
            compareLabel.textColor = UIColor(white: 0.35, alpha: 1)
        } else {
            let arrow  = diff > 0 ? "↑" : "↓"
            let color  = diff > 0 ? UIColor(red: 0.18, green: 0.64, blue: 0.18, alpha: 1) : UIColor(red: 0.78, green: 0.16, blue: 0.16, alpha: 1)
            let full   = "\(arrow) \(abs(diff))pts vs Yesterday"
            let attrStr = NSMutableAttributedString(string: full)
            attrStr.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: 1))
            attrStr.addAttribute(.foregroundColor, value: UIColor(white: 0.35, alpha: 1), range: NSRange(location: 1, length: full.count - 1))
            compareLabel.attributedText = attrStr
        }
    }

    // MARK: - Helpers
    private func scoreStatus(_ s: Int) -> (String, UIColor, UIColor) {
        switch s {
        case 85...:
            return ("Excellent",
                    UIColor(red: 0.0, green: 0.35, blue: 0.04, alpha: 1),
                    UIColor(red: 0.80, green: 0.96, blue: 0.80, alpha: 1))
        case 70...:
            return ("Good",
                    UIColor(red: 0.60, green: 0.38, blue: 0.0, alpha: 1),
                    UIColor(red: 1.0, green: 0.93, blue: 0.80, alpha: 1))
        case 50...:
            return ("Fair",
                    UIColor(red: 0.60, green: 0.35, blue: 0.0, alpha: 1),
                    UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1))
        default:
            return ("Poor",
                    UIColor(red: 0.78, green: 0.10, blue: 0.10, alpha: 1),
                    UIColor(red: 1.0, green: 0.88, blue: 0.88, alpha: 1))
        }
    }
}

import UIKit

enum StatAlignment {
    case left
    case center
    case right
}

class StepProgressView: UIView {

    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()

    private let stepsLabel = UILabel()
    private let stepsTextLabel = UILabel()
    
    private var currentProgress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCenterLabels()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCenterLabels()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupCircle()
    }

    // MARK: - Circle
    private func setupCircle() {

        layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })

        let center = CGPoint(x: bounds.midX, y: bounds.midY - 18)
        let radius: CGFloat = 50
        let lineWidth: CGFloat = 18

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.fillColor = UIColor.clear.cgColor

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        progressLayer.strokeEnd = currentProgress
    }

    // MARK: - Center Labels
    private func setupCenterLabels() {

        stepsLabel.text = "0"
        stepsLabel.font = .boldSystemFont(ofSize: 24)
        stepsLabel.textColor = .white
        stepsLabel.textAlignment = .center

        stepsTextLabel.text = "Steps"
        stepsTextLabel.font = .systemFont(ofSize: 14)
        stepsTextLabel.textColor = .white
        stepsTextLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [stepsLabel, stepsTextLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -18)
        ])
    }

    // MARK: - Public
    func setProgress(current: Int, total: Int) {
        let progress = total == 0 ? 0 : CGFloat(current) / CGFloat(total)

        // ensure visible minimum
        currentProgress = progress > 0 && progress < 0.03 ? 0.03 : progress

        progressLayer.strokeEnd = min(max(currentProgress, 0), 1)
        stepsLabel.text = "\(current)"
    }

}

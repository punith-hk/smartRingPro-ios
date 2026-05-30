import UIKit
import YCProductSDK

/// View that displays the ECG measurement card with graph, electrode status, and metrics
final class ECGMeasurementCardView: UIView {
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let ecgGraphContainer = UIView()
    let ecgLineView: YCECGDrawLineView = YCECGDrawLineView()
    private let ecgInfoLabel = UILabel()
    
    // Electrode Status
    let electrodeStatusView = UIView()
    let electrodeStatusLabel = UILabel()
    
    // Metrics
    private let metricsStack = UIStackView()
    let hrValueLabel = UILabel()
    let bpValueLabel = UILabel()
    let hrvValueLabel = UILabel()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Card View
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)
        
        // Title
        titleLabel.text = "Real-time ECG"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        // Electrode Status (on title row, right side)
        electrodeStatusView.backgroundColor = UIColor.systemRed
        electrodeStatusView.layer.cornerRadius = 8
        electrodeStatusView.isHidden = true  // Hidden until measurement starts
        electrodeStatusView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(electrodeStatusView)
        
        electrodeStatusLabel.text = "✗ electrode off"
        electrodeStatusLabel.font = .boldSystemFont(ofSize: 12)
        electrodeStatusLabel.textColor = .white
        electrodeStatusLabel.textAlignment = .center
        electrodeStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        electrodeStatusView.addSubview(electrodeStatusLabel)
        
        // ECG Graph Container
        ecgGraphContainer.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        ecgGraphContainer.layer.cornerRadius = 8
        ecgGraphContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ecgGraphContainer)
        
        // ECG Line View
        ecgLineView.drawReferenceWaveformStype = .top
        ecgLineView.translatesAutoresizingMaskIntoConstraints = false
        ecgGraphContainer.addSubview(ecgLineView)
        
        // Set grid offset to position dark lines near 25% and 75%
        // Big dark line spacing: 25 cells * 6.25pt = 156.25pt
        // Move reference waveform to start of graph
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let viewWidth = self.ecgGraphContainer.bounds.width
            // Position second dark line at 75% of width
            // offset + 156.25 = 0.75 * width  →  offset = 0.75 * width - 156.25
            let bigLineSpacing: CGFloat = 156.25  // 25 cells * 6.25pt
            self.ecgLineView.gridOffsetX = (viewWidth * 0.75) - bigLineSpacing
            // Position reference waveform at the start
            self.ecgLineView.referenceWaveformOffsetX = 0
            self.ecgLineView.setNeedsDisplay()
        }
        
        // ECG Info Label - will overlay on bottom of chart
        ecgInfoLabel.text = "Gain: 10mm/mv  Travel speed: 25mm/s  I  lead"
        ecgInfoLabel.font = .systemFont(ofSize: 11)
        ecgInfoLabel.textColor = .darkGray
        ecgInfoLabel.textAlignment = .left
        ecgInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ecgInfoLabel)  // Add to cardView so it appears on top
        
        // Metrics Stack
        metricsStack.axis = .horizontal
        metricsStack.spacing = 16
        metricsStack.distribution = .fillEqually
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(metricsStack)
        
        let hrContainer = createMetricView(title: "HR (bpm)", valueLabel: hrValueLabel)
        let bpContainer = createMetricView(title: "BP (mmHg)", valueLabel: bpValueLabel)
        let hrvContainer = createMetricView(title: "HRV (ms)", valueLabel: hrvValueLabel)
        
        metricsStack.addArrangedSubview(hrContainer)
        metricsStack.addArrangedSubview(bpContainer)
        metricsStack.addArrangedSubview(hrvContainer)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            electrodeStatusView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            electrodeStatusView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            electrodeStatusView.heightAnchor.constraint(equalToConstant: 30),
            electrodeStatusView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            electrodeStatusLabel.topAnchor.constraint(equalTo: electrodeStatusView.topAnchor, constant: 6),
            electrodeStatusLabel.leadingAnchor.constraint(equalTo: electrodeStatusView.leadingAnchor, constant: 12),
            electrodeStatusLabel.trailingAnchor.constraint(equalTo: electrodeStatusView.trailingAnchor, constant: -12),
            electrodeStatusLabel.bottomAnchor.constraint(equalTo: electrodeStatusView.bottomAnchor, constant: -6),
            
            ecgGraphContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            ecgGraphContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            ecgGraphContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            ecgGraphContainer.heightAnchor.constraint(equalToConstant: 290),
            
            ecgLineView.topAnchor.constraint(equalTo: ecgGraphContainer.topAnchor),
            ecgLineView.leadingAnchor.constraint(equalTo: ecgGraphContainer.leadingAnchor),
            ecgLineView.trailingAnchor.constraint(equalTo: ecgGraphContainer.trailingAnchor),
            ecgLineView.bottomAnchor.constraint(equalTo: ecgGraphContainer.bottomAnchor),
            
            // Position info label to overlay on bottom of chart
            ecgInfoLabel.bottomAnchor.constraint(equalTo: ecgGraphContainer.bottomAnchor, constant: -8),
            ecgInfoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            
            metricsStack.topAnchor.constraint(equalTo: ecgGraphContainer.bottomAnchor, constant: 12),
            metricsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            metricsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            metricsStack.heightAnchor.constraint(equalToConstant: 50),
            metricsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createMetricView(title: String, valueLabel: UILabel) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .gray
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        valueLabel.text = "--"
        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textColor = .black
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Public Methods
    func updateElectrodeStatus(isConnected: Bool) {
        electrodeStatusView.isHidden = false
        
        if isConnected {
            electrodeStatusView.backgroundColor = UIColor(red: 0, green: 196.0/255.0, blue: 149.0/255.0, alpha: 1.0)
            electrodeStatusLabel.text = "✓ electrode on"
        } else {
            electrodeStatusView.backgroundColor = UIColor.systemRed
            electrodeStatusLabel.text = "✗ electrode off"
        }
    }
}

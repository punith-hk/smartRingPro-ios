import UIKit
import YCProductSDK

/// Progress bar with overlaid start/stop button
final class ECGProgressView: UIView {
    
    let progressView = YCGradientProgressView()
    let progressLabel = UILabel()
    let startStopButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Progress bar background
        progressView.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        progressView.progressColors = [.systemRed]
        progressView.animationDuration = 0.0
        progressView.progress = 0.0
        progressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressView)
        
        // Progress percentage label (right side)
        progressLabel.text = ""
        progressLabel.font = .boldSystemFont(ofSize: 18)
        progressLabel.textColor = .white
        progressLabel.textAlignment = .right
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressLabel)
        
        // Button (overlays center)
        startStopButton.setTitle("Start", for: .normal)
        startStopButton.setTitleColor(.white, for: .normal)
        startStopButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        startStopButton.backgroundColor = .clear
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(startStopButton)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            progressLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            startStopButton.topAnchor.constraint(equalTo: topAnchor),
            startStopButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            startStopButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            startStopButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    func updateForMeasuring(_ isMeasuring: Bool) {
        if isMeasuring {
            // During measurement: show "Stop" button on left, percentage on right
            startStopButton.setTitle("Stop", for: .normal)
            progressView.backgroundColor = UIColor(red: 0.6, green: 0.9, blue: 0.85, alpha: 1)
            progressLabel.isHidden = false
        } else {
            // When stopped: center "Start" button, hide percentage, reset progress and color
            startStopButton.setTitle("Start", for: .normal)
            progressView.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
            progressView.progress = 0.0
            progressLabel.text = ""
            progressLabel.isHidden = true
        }
    }
}

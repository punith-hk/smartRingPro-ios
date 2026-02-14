import UIKit
import YCProductSDK

/// Tips overlay shown before starting ECG measurement
final class ECGTipsOverlayView: UIView {
    
    var onConfirm: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    private let overlayView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let instructionImageView = UIImageView()
    private let handPositionLabel = UILabel()
    
    // Hand selection UI
    private let leftHandButton = UIButton(type: .custom)
    private let rightHandButton = UIButton(type: .custom)
    private let leftHandImageView = UIImageView()
    private let rightHandImageView = UIImageView()
    private let leftHandLabel = UILabel()
    private let rightHandLabel = UILabel()
    
    private let confirmButton = UIButton(type: .system)
    
    // Track selected hand (default to left)
    private var selectedHand: YCDeviceWearingPositionType = .left
    
    // Constraint to animate instruction image position
    private var instructionImageCenterXConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        isHidden = true
        
        // Semi-transparent background
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlayView)
        
        // White card
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.3
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(cardView)
        
        // Title - "wearing tips"
        titleLabel.text = "wearing tips"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        // Message
        messageLabel.text = "Please wear the ring tightly, so that the back metal sheet is close to the skin, and your fingers touch the metal sheet on the ring."
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(messageLabel)
        
        // Instruction image (will move based on selection)
        instructionImageView.image = UIImage(systemName: "hand.point.up.left.fill")
        instructionImageView.tintColor = .lightGray
        instructionImageView.contentMode = .scaleAspectFit
        instructionImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(instructionImageView)
        
        // Hand position label (shows "Left" or "Right" next to instruction image)
        handPositionLabel.text = "Left"
        handPositionLabel.font = .systemFont(ofSize: 14)
        handPositionLabel.textColor = .darkGray
        handPositionLabel.textAlignment = .center
        handPositionLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(handPositionLabel)
        
        // Left hand selection
        leftHandButton.backgroundColor = .clear
        leftHandButton.layer.borderWidth = 2
        leftHandButton.layer.borderColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1).cgColor
        leftHandButton.layer.cornerRadius = 8
        leftHandButton.translatesAutoresizingMaskIntoConstraints = false
        leftHandButton.addTarget(self, action: #selector(leftHandTapped), for: .touchUpInside)
        cardView.addSubview(leftHandButton)
        
        leftHandImageView.image = UIImage(systemName: "hand.point.up.left.fill")
        leftHandImageView.tintColor = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1)
        leftHandImageView.contentMode = .scaleAspectFit
        leftHandImageView.translatesAutoresizingMaskIntoConstraints = false
        leftHandButton.addSubview(leftHandImageView)
        
        leftHandLabel.text = "Left"
        leftHandLabel.font = .systemFont(ofSize: 14)
        leftHandLabel.textColor = .darkGray
        leftHandLabel.textAlignment = .center
        leftHandLabel.translatesAutoresizingMaskIntoConstraints = false
        leftHandButton.addSubview(leftHandLabel)
        
        // Right hand selection
        rightHandButton.backgroundColor = .clear
        rightHandButton.layer.borderWidth = 2
        rightHandButton.layer.borderColor = UIColor.lightGray.cgColor
        rightHandButton.layer.cornerRadius = 8
        rightHandButton.translatesAutoresizingMaskIntoConstraints = false
        rightHandButton.addTarget(self, action: #selector(rightHandTapped), for: .touchUpInside)
        cardView.addSubview(rightHandButton)
        
        // Use same icon as left but flip it horizontally
        rightHandImageView.image = UIImage(systemName: "hand.point.up.left.fill")
        rightHandImageView.tintColor = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1)
        rightHandImageView.contentMode = .scaleAspectFit
        rightHandImageView.transform = CGAffineTransform(scaleX: -1, y: 1)  // Flip horizontally
        rightHandImageView.translatesAutoresizingMaskIntoConstraints = false
        rightHandButton.addSubview(rightHandImageView)
        
        rightHandLabel.text = "Right"
        rightHandLabel.font = .systemFont(ofSize: 14)
        rightHandLabel.textColor = .darkGray
        rightHandLabel.textAlignment = .center
        rightHandLabel.translatesAutoresizingMaskIntoConstraints = false
        rightHandButton.addSubview(rightHandLabel)
        
        // Confirm button
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        confirmButton.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        confirmButton.layer.cornerRadius = 25
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cardView.addSubview(confirmButton)
        
        // Tap outside to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Create constraint for instruction image that can be animated
        instructionImageCenterXConstraint = instructionImageView.centerXAnchor.constraint(equalTo: leftHandButton.centerXAnchor)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            cardView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 40),
            cardView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            instructionImageView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            instructionImageCenterXConstraint,
            instructionImageView.widthAnchor.constraint(equalToConstant: 120),
            instructionImageView.heightAnchor.constraint(equalToConstant: 80),
            
            handPositionLabel.topAnchor.constraint(equalTo: instructionImageView.bottomAnchor, constant: 4),
            handPositionLabel.centerXAnchor.constraint(equalTo: instructionImageView.centerXAnchor),
            handPositionLabel.widthAnchor.constraint(equalToConstant: 60),
            
            // Left hand button
            leftHandButton.topAnchor.constraint(equalTo: handPositionLabel.bottomAnchor, constant: 16),
            leftHandButton.trailingAnchor.constraint(equalTo: cardView.centerXAnchor, constant: -12),
            leftHandButton.widthAnchor.constraint(equalToConstant: 100),
            leftHandButton.heightAnchor.constraint(equalToConstant: 100),
            
            leftHandImageView.topAnchor.constraint(equalTo: leftHandButton.topAnchor, constant: 16),
            leftHandImageView.centerXAnchor.constraint(equalTo: leftHandButton.centerXAnchor),
            leftHandImageView.widthAnchor.constraint(equalToConstant: 50),
            leftHandImageView.heightAnchor.constraint(equalToConstant: 50),
            
            leftHandLabel.topAnchor.constraint(equalTo: leftHandImageView.bottomAnchor, constant: 8),
            leftHandLabel.centerXAnchor.constraint(equalTo: leftHandButton.centerXAnchor),
            
            // Right hand button
            rightHandButton.topAnchor.constraint(equalTo: handPositionLabel.bottomAnchor, constant: 16),
            rightHandButton.leadingAnchor.constraint(equalTo: cardView.centerXAnchor, constant: 12),
            rightHandButton.widthAnchor.constraint(equalToConstant: 100),
            rightHandButton.heightAnchor.constraint(equalToConstant: 100),
            
            rightHandImageView.topAnchor.constraint(equalTo: rightHandButton.topAnchor, constant: 16),
            rightHandImageView.centerXAnchor.constraint(equalTo: rightHandButton.centerXAnchor),
            rightHandImageView.widthAnchor.constraint(equalToConstant: 50),
            rightHandImageView.heightAnchor.constraint(equalToConstant: 50),
            
            rightHandLabel.topAnchor.constraint(equalTo: rightHandImageView.bottomAnchor, constant: 8),
            rightHandLabel.centerXAnchor.constraint(equalTo: rightHandButton.centerXAnchor),
            
            confirmButton.topAnchor.constraint(equalTo: leftHandButton.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
        
        // Default to left hand selected
        updateHandSelection()
    }
    
    func show() {
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    @objc private func leftHandTapped() {
        selectedHand = .left
        updateHandSelection()
    }
    
    @objc private func rightHandTapped() {
        selectedHand = .right
        updateHandSelection()
    }
    
    private func updateHandSelection() {
        // Deactivate old constraint
        instructionImageCenterXConstraint.isActive = false
        
        if selectedHand == .left {
            // Update left button - SELECTED
            leftHandButton.layer.borderWidth = 3
            leftHandButton.layer.borderColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1).cgColor
            leftHandButton.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 0.2)
            leftHandButton.layer.shadowColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 0.5).cgColor
            leftHandButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            leftHandButton.layer.shadowRadius = 8
            leftHandButton.layer.shadowOpacity = 0.8
            
            // Update right button - UNSELECTED
            rightHandButton.layer.borderWidth = 2
            rightHandButton.layer.borderColor = UIColor.lightGray.cgColor
            rightHandButton.backgroundColor = .clear
            rightHandButton.layer.shadowOpacity = 0
            
            // Move instruction image to left
            instructionImageCenterXConstraint = instructionImageView.centerXAnchor.constraint(equalTo: leftHandButton.centerXAnchor)
            
            // Reset flip (normal orientation)
            instructionImageView.transform = .identity
            
            // Update label
            handPositionLabel.text = "Left"
            
        } else {
            // Update left button - UNSELECTED
            leftHandButton.layer.borderWidth = 2
            leftHandButton.layer.borderColor = UIColor.lightGray.cgColor
            leftHandButton.backgroundColor = .clear
            leftHandButton.layer.shadowOpacity = 0
            
            // Update right button - SELECTED
            rightHandButton.layer.borderWidth = 3
            rightHandButton.layer.borderColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1).cgColor
            rightHandButton.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 0.2)
            rightHandButton.layer.shadowColor = UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 0.5).cgColor
            rightHandButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            rightHandButton.layer.shadowRadius = 8
            rightHandButton.layer.shadowOpacity = 0.8
            
            // Move instruction image to right
            instructionImageCenterXConstraint = instructionImageView.centerXAnchor.constraint(equalTo: rightHandButton.centerXAnchor)
            
            // Flip horizontally for right hand
            instructionImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
            
            // Update label
            handPositionLabel.text = "Right"
        }
        
        // Activate new constraint
        instructionImageCenterXConstraint.isActive = true
        
        // Animate the change
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func confirmTapped() {
        // First, set the wearing position on the device
        YCProduct.setDeviceWearingPosition(wearingPosition: selectedHand) { [weak self] state, response in
            DispatchQueue.main.async {
                if state == .succeed {
                    print("[ECG] Wearing position set to: \(self?.selectedHand == .left ? "Left" : "Right")")
                } else {
                    print("[ECG] Failed to set wearing position: \(String(describing: response))")
                }
                
                // Continue with measurement regardless (device may handle it)
                self?.hide()
                self?.onConfirm?()
            }
        }
    }
    
    @objc private func dismissTapped() {
        hide()
        onDismiss?()
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
            self.alpha = 1
        }
    }
}

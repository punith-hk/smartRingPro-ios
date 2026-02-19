import UIKit

class ReferFriendViewController: AppBaseViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let illustrationImageView = UIImageView()
    private let shareLabel = UILabel()
    
    private let whatsappButton = UIButton(type: .custom)
    private let facebookButton = UIButton(type: .custom)
    private let messageButton = UIButton(type: .custom)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle("Refer a friend")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title Label
        titleLabel.text = "Refer a friend & get 20% offer for first treatment"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Illustration Image
        illustrationImageView.image = UIImage(systemName: "person.2.fill")
        illustrationImageView.tintColor = .white
        illustrationImageView.contentMode = .scaleAspectFit
        illustrationImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(illustrationImageView)
        
        // Share Label
        shareLabel.text = "Share Link via"
        shareLabel.font = .systemFont(ofSize: 16, weight: .regular)
        shareLabel.textColor = .white
        shareLabel.textAlignment = .center
        shareLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shareLabel)
        
        // Social Media Buttons Container
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 40
        buttonStackView.distribution = .equalSpacing
        buttonStackView.alignment = .center
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStackView)
        
        // WhatsApp Button
        configureButton(whatsappButton, systemIcon: "message.circle.fill", size: 60)
        buttonStackView.addArrangedSubview(whatsappButton)
        
        // Facebook Button
        configureButton(facebookButton, systemIcon: "f.circle.fill", size: 60)
        buttonStackView.addArrangedSubview(facebookButton)
        
        // Message Button
        configureButton(messageButton, systemIcon: "message.fill", size: 60)
        buttonStackView.addArrangedSubview(messageButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            illustrationImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            illustrationImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            illustrationImageView.widthAnchor.constraint(equalToConstant: 150),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 150),
            
            shareLabel.topAnchor.constraint(equalTo: illustrationImageView.bottomAnchor, constant: 40),
            shareLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            buttonStackView.topAnchor.constraint(equalTo: shareLabel.bottomAnchor, constant: 24),
            buttonStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Configure Button
    private func configureButton(_ button: UIButton, systemIcon: String, size: CGFloat) {
        button.setImage(UIImage(systemName: systemIcon), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
    }
}



import UIKit

final class SpecialistCell: UITableViewCell {
    
    static let reuseId = "SpecialistCell"
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let availableDoctorsButton = UIButton(type: .system)
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Card View
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        // Icon Image View
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 25
        iconImageView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconImageView)
        
        // Name Label
        nameLabel.font = .boldSystemFont(ofSize: 18)
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)
        
        // Description Label
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 1
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(descriptionLabel)
        
        // Available Doctors Button
        availableDoctorsButton.setTitle("Available Doctors", for: .normal)
        availableDoctorsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        availableDoctorsButton.setTitleColor(.white, for: .normal)
        availableDoctorsButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        availableDoctorsButton.layer.cornerRadius = 12
        availableDoctorsButton.isUserInteractionEnabled = false
        availableDoctorsButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(availableDoctorsButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            // Card View
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.heightAnchor.constraint(equalToConstant: 100),
            
            // Icon Image
            iconImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Available Doctors Button
            availableDoctorsButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            availableDoctorsButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            availableDoctorsButton.widthAnchor.constraint(equalToConstant: 145),
            availableDoctorsButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Configure
    func configure(with specialist: Specialization) {
        nameLabel.text = specialist.name
        descriptionLabel.text = specialist.description
        
        // Set icon based on specialization
        switch specialist.name.lowercased() {
        case "general physician":
            iconImageView.image = UIImage(systemName: "stethoscope")
            iconImageView.tintColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1)
            iconImageView.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1)
        case "cardiology":
            iconImageView.image = UIImage(systemName: "heart.fill")
            iconImageView.tintColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
            iconImageView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1)
        case "pediatrician":
            iconImageView.image = UIImage(systemName: "figure.2.and.child.holdinghands")
            iconImageView.tintColor = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1)
            iconImageView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)
        case "dermatology":
            iconImageView.image = UIImage(systemName: "face.smiling")
            iconImageView.tintColor = UIColor(red: 0.9, green: 0.6, blue: 0.4, alpha: 1)
            iconImageView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1)
        case "psychiatrist":
            iconImageView.image = UIImage(systemName: "brain.head.profile")
            iconImageView.tintColor = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1)
            iconImageView.backgroundColor = UIColor(red: 0.95, green: 0.9, blue: 1.0, alpha: 1)
        case "others":
            iconImageView.image = UIImage(systemName: "medical.thermometer")
            iconImageView.tintColor = UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1)
            iconImageView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)
        default:
            iconImageView.image = UIImage(systemName: "cross.case")
            iconImageView.tintColor = .systemBlue
            iconImageView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)
        }
    }
}

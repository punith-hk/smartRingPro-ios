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
    func configure(with department: DepartmentItem) {
        nameLabel.text = department.description
        descriptionLabel.text = "Specialists in \(department.description.lowercased())"

        if let iconURL = department.iconURL {
            iconImageView.image = UIImage(systemName: "cross.case")
            iconImageView.tintColor = .systemBlue
            iconImageView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)
            iconImageView.loadImage(from: iconURL)
        } else {
            applySymbolIcon(for: department.description)
        }
    }

    // MARK: - Symbol icon fallback (used when server provides no icon URL)
    private func applySymbolIcon(for name: String) {
        let key = name.lowercased()

        let mapping: [(keywords: [String], symbol: String, tint: UIColor, bg: UIColor)] = [
            (["general", "physician"],  "stethoscope",                UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1), UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1)),
            (["cardio"],                "heart.fill",                  UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1), UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1)),
            (["allerg"],                "allergens",                   UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1), UIColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1)),
            (["derma"],                 "face.smiling",                UIColor(red: 0.9, green: 0.6, blue: 0.4, alpha: 1), UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1)),
            (["endoc"],                 "waveform.path.ecg",           UIColor(red: 0.5, green: 0.8, blue: 0.4, alpha: 1), UIColor(red: 0.93, green: 1.0, blue: 0.93, alpha: 1)),
            (["gastro"],                "fork.knife",                  UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1), UIColor(red: 1.0, green: 0.96, blue: 0.9, alpha: 1)),
            (["infect"],                "cross.vial.fill",             UIColor(red: 0.4, green: 0.7, blue: 0.5, alpha: 1), UIColor(red: 0.9, green: 1.0, blue: 0.94, alpha: 1)),
            (["neuro"],                 "brain.head.profile",          UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1), UIColor(red: 0.95, green: 0.9, blue: 1.0, alpha: 1)),
            (["pulmo", "lung"],         "lungs.fill",                  UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1), UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)),
            (["rheuma"],                "figure.walk",                 UIColor(red: 0.7, green: 0.3, blue: 0.5, alpha: 1), UIColor(red: 1.0, green: 0.92, blue: 0.96, alpha: 1)),
            (["vascular"],              "chart.line.uptrend.xyaxis",   UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1), UIColor(red: 1.0, green: 0.92, blue: 0.92, alpha: 1)),
            (["other"],                 "medical.thermometer",         UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1), UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)),
            (["pediatr", "child"],      "figure.2.and.child.holdinghands", UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1), UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)),
            (["psych"],                 "brain",                       UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1), UIColor(red: 0.95, green: 0.9, blue: 1.0, alpha: 1)),
        ]

        for entry in mapping {
            if entry.keywords.contains(where: { key.contains($0) }) {
                iconImageView.image = UIImage(systemName: entry.symbol)
                iconImageView.tintColor = entry.tint
                iconImageView.backgroundColor = entry.bg
                return
            }
        }

        // Default fallback
        iconImageView.image = UIImage(systemName: "cross.case")
        iconImageView.tintColor = .systemBlue
        iconImageView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1)
    }
}

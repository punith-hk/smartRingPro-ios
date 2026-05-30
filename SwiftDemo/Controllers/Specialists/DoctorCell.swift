import UIKit

final class DoctorCell: UITableViewCell {
    
    static let reuseId = "DoctorCell"
    
    // MARK: - UI Components
    private let cardView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let qualificationLabel = UILabel()
    private let specializationLabel = UILabel()
    private let bookButton = UIButton(type: .system)
    
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
        
        // Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(profileImageView)
        
        // Name Label
        nameLabel.font = .boldSystemFont(ofSize: 17)
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)
        
        // Qualification Label
        qualificationLabel.font = .systemFont(ofSize: 13)
        qualificationLabel.textColor = .darkGray
        qualificationLabel.numberOfLines = 1
        qualificationLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(qualificationLabel)
        
        // Specialization Label
        specializationLabel.font = .systemFont(ofSize: 12)
        specializationLabel.textColor = .gray
        specializationLabel.numberOfLines = 1
        specializationLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(specializationLabel)
        
        // Book Button
        bookButton.setTitle("Book Now", for: .normal)
        bookButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        bookButton.layer.cornerRadius = 18
        bookButton.isUserInteractionEnabled = false
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(bookButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            // Card View
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            // Profile Image
            profileImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: bookButton.leadingAnchor, constant: -12),
            
            // Qualification Label
            qualificationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            qualificationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            qualificationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Specialization Label
            specializationLabel.topAnchor.constraint(equalTo: qualificationLabel.bottomAnchor, constant: 3),
            specializationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            specializationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Book Button
            bookButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            bookButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            bookButton.widthAnchor.constraint(equalToConstant: 90),
            bookButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    // MARK: - Configure
    func configure(with doctor: Doctor) {
        nameLabel.text = doctor.displayName
        qualificationLabel.text = doctor.qualificationsText
        specializationLabel.text = doctor.specializationText.uppercased()
        
        // Load profile image
        if let imageURL = doctor.profileImageURL {
            profileImageView.loadImage(from: imageURL)
        } else {
            // Default placeholder
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .lightGray
        }
    }
}

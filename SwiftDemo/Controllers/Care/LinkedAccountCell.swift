import UIKit

final class LinkedAccountCell: UITableViewCell {

    static let reuseId = "LinkedAccountCell"

    private let cardView      = UIView()
    private let initialsView  = UIView()       // SQUARE avatar
    private let initialsLabel = UILabel()
    private let nameLabel     = UILabel()
    private let relationLabel = UILabel()
    private let tapHintLabel  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.07
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Square avatar (cornerRadius 8 = slightly rounded square)
        initialsView.layer.cornerRadius = 8
        initialsView.clipsToBounds = true
        initialsView.translatesAutoresizingMaskIntoConstraints = false

        initialsLabel.font = .systemFont(ofSize: 22, weight: .bold)
        initialsLabel.textColor = .white
        initialsLabel.textAlignment = .center
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsView.addSubview(initialsLabel)

        // Name
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Relation (blue)
        relationLabel.font = .systemFont(ofSize: 13, weight: .medium)
        relationLabel.textColor = UIColor(red: 0.00, green: 0.47, blue: 0.83, alpha: 1)
        relationLabel.translatesAutoresizingMaskIntoConstraints = false

        // Tap hint
        tapHintLabel.text = "Tap to view health data"
        tapHintLabel.font = .systemFont(ofSize: 12)
        tapHintLabel.textColor = UIColor(white: 0.55, alpha: 1)
        tapHintLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(initialsView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(relationLabel)
        cardView.addSubview(tapHintLabel)

        NSLayoutConstraint.activate([
            // Card insets
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Square avatar
            initialsView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            initialsView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            initialsView.widthAnchor.constraint(equalToConstant: 52),
            initialsView.heightAnchor.constraint(equalToConstant: 52),

            // Initials label centered in square
            initialsLabel.centerXAnchor.constraint(equalTo: initialsView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: initialsView.centerYAnchor),

            // Name
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: initialsView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            // Relation
            relationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            relationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            relationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            // Tap hint
            tapHintLabel.topAnchor.constraint(equalTo: relationLabel.bottomAnchor, constant: 3),
            tapHintLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            tapHintLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            tapHintLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    func configure(with model: LinkedAccountInfo) {
        nameLabel.text = model.name
        let rel = model.relation ?? ""
        relationLabel.text = rel.isEmpty ? "Family member" : rel
        initialsLabel.text = initials(for: model.name)
        initialsView.backgroundColor = avatarColor(for: model.name)
    }

    // MARK: - Helpers

    private func initials(for name: String) -> String {
        let first = name.split(separator: " ").first?.prefix(1) ?? ""
        return String(first).uppercased()
    }

    private func avatarColor(for name: String) -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 0.13, green: 0.47, blue: 0.71, alpha: 1),
            UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1),
            UIColor(red: 0.58, green: 0.15, blue: 0.68, alpha: 1),
            UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1),
            UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),
            UIColor(red: 0.00, green: 0.59, blue: 0.53, alpha: 1),
        ]
        return colors[abs(name.hashValue) % colors.count]
    }
}

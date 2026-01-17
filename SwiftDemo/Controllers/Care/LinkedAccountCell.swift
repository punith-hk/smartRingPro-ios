import UIKit

final class LinkedAccountCell: UITableViewCell {

    static let reuseId = "LinkedAccountCell"

    private let cardView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let relationLabel = UILabel()

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

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.layer.cornerRadius = 22
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        relationLabel.font = .systemFont(ofSize: 13)
        relationLabel.textColor = .darkGray

        let textStack = UIStackView(arrangedSubviews: [nameLabel, relationLabel])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let topStack = UIStackView(arrangedSubviews: [profileImageView, textStack])
        topStack.axis = .horizontal
        topStack.spacing = 12
        topStack.alignment = .top
        topStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(topStack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            profileImageView.widthAnchor.constraint(equalToConstant: 44),
            profileImageView.heightAnchor.constraint(equalToConstant: 44),

            topStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            topStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            topStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with model: LinkedAccountInfo) {
        nameLabel.text = model.name
        relationLabel.text = "Relation : \(model.relation ?? "-")"
    }
}

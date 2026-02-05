import UIKit

final class FamilyMemberCell: UITableViewCell {

    static let reuseId = "FamilyMemberCell"

    // MARK: - UI
    private let cardView = UIView()
    private let profileImageView = UIImageView()

    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()

    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    private var compressedImageData: Data?

    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

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

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.translatesAutoresizingMaskIntoConstraints = false

        profileImageView.layer.cornerRadius = 22
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        detailsLabel.font = .systemFont(ofSize: 13)
        detailsLabel.numberOfLines = 0
        detailsLabel.textColor = .darkGray

        editButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let actionStack = UIStackView(arrangedSubviews: [editButton, deleteButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 12

        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailsLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        let topStack = UIStackView(arrangedSubviews: [profileImageView, textStack, actionStack])
        topStack.spacing = 12
        topStack.alignment = .top
        topStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(topStack)
        contentView.addSubview(cardView)

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

    func configure(with member: FamilyMember) {

        nameLabel.text = member.name

        let genderText: String
        switch member.gender {
        case "M": genderText = "Male"
        case "F": genderText = "Female"
        default:  genderText = "-"
        }

        let dobText: String
        if let dob = member.dob, !dob.isEmpty {
            dobText = formatDOB(dob)
        } else {
            dobText = "-"
        }

        detailsLabel.text =
        """
        Relation : \(member.relation)
        Gender   : \(genderText)
        DOB      : \(dobText)
        Blood    : \(member.blood_group ?? "-")
        """

        if let urlStr = member.dependent_image_url,
           let url = URL(string: urlStr),
           !urlStr.isEmpty {
            profileImageView.loadImage(from: url)
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    private func formatDOB(_ value: String) -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd-MM-yyyy"

        if let date = inputFormatter.date(from: value) {
            return outputFormatter.string(from: date)
        }

        return value // fallback (safe)
    }



    @objc private func editTapped() {
        onEdit?()
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}

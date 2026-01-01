import UIKit

final class MultiSelectCell: UITableViewCell {

    static let reuseId = "MultiSelectCell"

    private let titleLabel = UILabel()
    private let checkBox = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {

        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        checkBox.translatesAutoresizingMaskIntoConstraints = false
        checkBox.contentMode = .scaleAspectFit

        contentView.addSubview(titleLabel)
        contentView.addSubview(checkBox)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            checkBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 22),
            checkBox.heightAnchor.constraint(equalToConstant: 22),
        ])
    }
    
    func configure(
        title: String,
        selected: Bool,
        disabled: Bool
    ) {
        titleLabel.text = title

        let imageName = selected ? "checkmark.square.fill" : "square"
        checkBox.image = UIImage(systemName: imageName)
        checkBox.tintColor = selected ? .systemTeal : .lightGray

        titleLabel.textColor = disabled ? .lightGray : .black
        contentView.alpha = disabled ? 0.5 : 1.0

        // 🚫 DO NOT disable interaction
        isUserInteractionEnabled = true
    }


}

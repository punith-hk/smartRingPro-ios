import UIKit

class VitalCardView: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    // ✅ Tap callback
    var onTap: (() -> Void)?

    init(icon: UIImage?, title: String, value: String) {
        super.init(frame: .zero)
        setupUI()
        configure(icon: icon, title: title, value: value)
        setupTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false

        iconView.tintColor = .systemGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private func configure(icon: UIImage?, title: String, value: String) {
        iconView.image = icon
        titleLabel.text = title
        valueLabel.text = value
    }

    // ✅ Tap setup
    private func setupTap() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tap)
    }

    @objc private func cardTapped() {
        onTap?()
    }

    // ✅ Update value later
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}

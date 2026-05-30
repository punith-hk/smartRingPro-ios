import UIKit

final class InfoCardView: UIView {

    // MARK: - UI
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: - Tap Callback
    var onTap: (() -> Void)?

    // MARK: - Init
    init(icon: String, title: String, subtitle: String) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 14

        // Icon
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .black

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.text = title

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.text = subtitle

        [iconView, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])

        setupTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Tap
    private func setupTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func cardTapped() {
        onTap?()
    }

    // MARK: - Public API
    func updateSubtitle(_ text: String) {
        subtitleLabel.text = text
    }
}

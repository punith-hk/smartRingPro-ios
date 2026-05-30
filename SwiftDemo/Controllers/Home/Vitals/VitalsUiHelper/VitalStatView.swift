import UIKit

final class VitalStatView: UIView {

    private let valueLabel = UILabel()

    init(title: String, value: String, color: UIColor, icon: UIImage? = nil, titleFont: UIFont? = nil) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 14

        let iconContainer = UIView()
        iconContainer.backgroundColor = color
        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add icon image if provided
        if let icon = icon {
            let iconImageView = UIImageView(image: icon)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(iconImageView)
            
            NSLayoutConstraint.activate([
                iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
                iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 12),
                iconImageView.heightAnchor.constraint(equalToConstant: 12)
            ])
        }

        valueLabel.font = .boldSystemFont(ofSize: 20)
        valueLabel.textAlignment = .center
        valueLabel.text = value

        let titleLabel = UILabel()
        titleLabel.font = titleFont ?? .systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .darkGray
        titleLabel.text = title

        let stack = UIStackView(arrangedSubviews: [iconContainer, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 20),
            iconContainer.heightAnchor.constraint(equalToConstant: 20),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // ✅ THIS FIXES YOUR ERROR
    func updateValue(_ value: String) {
        valueLabel.text = value
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

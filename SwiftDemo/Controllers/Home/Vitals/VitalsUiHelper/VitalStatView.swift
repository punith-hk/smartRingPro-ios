import UIKit

final class VitalStatView: UIView {

    private let valueLabel = UILabel()

    init(title: String, value: String, color: UIColor, titleFont: UIFont? = nil) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 14

        let icon = UIView()
        icon.backgroundColor = color
        icon.layer.cornerRadius = 10
        icon.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .boldSystemFont(ofSize: 20)
        valueLabel.textAlignment = .center
        valueLabel.text = value

        let titleLabel = UILabel()
        titleLabel.font = titleFont ?? .systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .darkGray
        titleLabel.text = title

        let stack = UIStackView(arrangedSubviews: [icon, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),

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

import UIKit

/// A single vital-metric card used in the new dashboard grid (3-column layout).
///
/// Layout (from screenshot):
/// ┌─────────────────────────────┐
/// │ [●icon]  Title (13pt bold)  │  ← top row: circle icon + title (can wrap)
/// │                             │
/// │  Value (28pt bold)  unit    │  ← middle: large value + small grey unit
/// │                             │
/// │ ● Status text (11pt)        │  ← bottom-left: coloured dot + status
/// └─────────────────────────────┘
final class DashboardVitalCardV2: UIView {

    // MARK: - Public config
    struct Config {
        var iconImage: UIImage?
        var iconTint: UIColor       = .systemRed
        var iconBgColor: UIColor    = UIColor(red: 1, green: 0.88, blue: 0.88, alpha: 1)
        var title: String           = ""
        var value: String           = "--"
        var unit: String            = ""
        var statusText: String      = ""
        var statusColor: UIColor    = .gray
    }

    var config: Config = Config() { didSet { apply() } }
    var onTap: (() -> Void)?

    // MARK: - Sub-views
    private let iconContainer = UIView()
    private let iconView      = UIImageView()
    private let titleLabel    = UILabel()
    private let valueLabel    = UILabel()
    private let unitLabel     = UILabel()
    private let dotLabel      = UILabel()   // "●"
    private let statusLabel   = UILabel()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // convenience
    init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setup()
        apply()
    }

    // MARK: - Setup
    private func setup() {
        backgroundColor          = .white
        layer.cornerRadius       = 12
        layer.shadowColor        = UIColor.black.cgColor
        layer.shadowOpacity      = 0.08
        layer.shadowRadius       = 6
        layer.shadowOffset       = CGSize(width: 0, height: 2)
        layer.masksToBounds      = false

        // Icon circle
        iconContainer.layer.cornerRadius = 14   // 28pt diameter → 14 radius
        iconContainer.layer.masksToBounds = true
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
        ])

        // Title
        titleLabel.font          = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor     = UIColor(white: 0.2, alpha: 1)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Value
        valueLabel.font          = .systemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor     = .black
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        // Unit
        unitLabel.font           = .systemFont(ofSize: 11, weight: .regular)
        unitLabel.textColor      = UIColor(white: 0.5, alpha: 1)
        unitLabel.numberOfLines  = 2
        unitLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status dot
        dotLabel.text            = "●"
        dotLabel.font            = .systemFont(ofSize: 10)
        dotLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status text
        statusLabel.font         = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.numberOfLines = 1
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Hierarchy
        [iconContainer, titleLabel, valueLabel, unitLabel, dotLabel, statusLabel].forEach {
            addSubview($0)
        }

        // --- Constraints ---
        // Icon container: 28×28, top-left
        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconContainer.widthAnchor.constraint(equalToConstant: 28),
            iconContainer.heightAnchor.constraint(equalToConstant: 28),
        ])

        // Title: to the right of icon, vertically centred with icon
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        // Value + unit row: below icon, left-aligned
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),

            unitLabel.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: -2),
            unitLabel.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 3),
            unitLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
        ])

        // Status row: pinned to bottom-left
        NSLayoutConstraint.activate([
            dotLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            dotLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),

            statusLabel.centerYAnchor.constraint(equalTo: dotLabel.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: dotLabel.trailingAnchor, constant: 3),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
        ])

        // Tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    // MARK: - Apply config
    private func apply() {
        iconView.image               = config.iconImage?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor           = config.iconTint
        iconContainer.backgroundColor = config.iconBgColor
        titleLabel.text              = config.title
        valueLabel.text              = config.value
        unitLabel.text               = config.unit
        dotLabel.textColor           = config.statusColor
        statusLabel.text             = config.statusText
        statusLabel.textColor        = config.statusColor
    }

    @objc private func tapped() { onTap?() }

    // MARK: - Convenience updaters
    func updateValue(_ value: String, unit: String? = nil) {
        valueLabel.text = value
        if let u = unit { unitLabel.text = u }
    }

    func updateStatus(text: String, color: UIColor) {
        statusLabel.text   = text
        statusLabel.textColor = color
        dotLabel.textColor = color
    }
}

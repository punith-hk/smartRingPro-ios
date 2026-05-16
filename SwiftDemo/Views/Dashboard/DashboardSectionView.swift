import UIKit

/// A rounded section card used in the new dashboard.
///
/// Renders:
///   • Section title (18pt bold) top-left with horizontal padding
///   • Rows of 3 cards (DashboardVitalCardV2) added via addRow(cards:)
///   • Background colour + corner radius set at init
///
/// Usage:
///   let section = DashboardSectionView(title: "Cardiovascular Vitality",
///                                      backgroundColor: UIColor(hex: "D9EDFF"))
///   section.addRow(cards: [heartRateCard, hrvCard, ecgCard])
///   section.addRow(cards: [ecgDetailsCard, bpCard, spo2Card])
final class DashboardSectionView: UIView {

    // MARK: - Sub-views
    private let titleLabel = UILabel()
    private let stackView  = UIStackView()

    // MARK: - Init
    init(title: String, sectionColor: UIColor = UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1)) {
        super.init(frame: .zero)
        setup(title: title, color: sectionColor)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setup(title: String, color: UIColor) {
        backgroundColor      = color
        layer.cornerRadius   = 16
        layer.masksToBounds  = true

        // Title
        titleLabel.text      = title
        titleLabel.font      = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = UIColor(white: 0.10, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Vertical stack for card rows
        stackView.axis         = .vertical
        stackView.spacing      = 10
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }

    // MARK: - Public API

    /// Add a row of 1–3 cards. Pass fewer than 3 and empty spacers fill the gaps.
    func addRow(cards: [UIView]) {
        let row = UIStackView()
        row.axis         = .horizontal
        row.spacing      = 8
        row.distribution = .fillEqually
        row.alignment    = .fill

        // Ensure exactly 3 slots
        var views: [UIView] = cards
        while views.count < 3 {
            let spacer = UIView()
            spacer.backgroundColor = .clear
            views.append(spacer)
        }

        views.forEach { row.addArrangedSubview($0) }

        // Fixed card height
        row.heightAnchor.constraint(equalToConstant: 130).isActive = true
        stackView.addArrangedSubview(row)
    }
}

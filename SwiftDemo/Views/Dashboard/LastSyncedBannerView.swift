import UIKit

/// Banner showing last sync time + a manual sync button.
///
/// Screenshot layout:
///   🟢  Last synced: just now                    ↻
final class LastSyncedBannerView: UIView {

    // MARK: - Callback
    var onSyncTapped: (() -> Void)?

    // MARK: - Sub-views
    private let dotView    = UIView()
    private let textLabel  = UILabel()
    private let spinner    = UIActivityIndicatorView(style: .medium)
    private let syncButton = UIButton(type: .system)

    // MARK: - State
    private(set) var isSyncing = false
    private var lastSyncDate: Date?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setup() {
        backgroundColor = .clear

        // Dot
        dotView.layer.cornerRadius = 5
        dotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dotView)

        // Label
        textLabel.font      = .systemFont(ofSize: 13, weight: .medium)
        textLabel.textColor = UIColor(red: 0.33, green: 0.43, blue: 0.47, alpha: 1)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)

        // Spinner (shown during active sync; replaces dot)
        spinner.color = UIColor(red: 0.33, green: 0.43, blue: 0.47, alpha: 1)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        // Sync button (↻)
        let icon = UIImage(systemName: "arrow.clockwise")?.withRenderingMode(.alwaysTemplate)
        syncButton.setImage(icon, for: .normal)
        syncButton.tintColor = UIColor(red: 0.12, green: 0.47, blue: 0.71, alpha: 1)
        syncButton.addTarget(self, action: #selector(syncTapped), for: .touchUpInside)
        syncButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(syncButton)

        NSLayoutConstraint.activate([
            // Dot
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 10),
            dotView.heightAnchor.constraint(equalToConstant: 10),

            // Spinner (same position as dot)
            spinner.centerXAnchor.constraint(equalTo: dotView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: dotView.centerYAnchor),

            // Text
            textLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 6),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: syncButton.leadingAnchor, constant: -8),

            // Sync button (right side)
            syncButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            syncButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            syncButton.widthAnchor.constraint(equalToConstant: 32),
            syncButton.heightAnchor.constraint(equalToConstant: 32),
        ])

        updateDisplay()
    }

    // MARK: - Public API

    /// Call when a sync completes (or when the view first appears)
    func markSynced(date: Date = Date()) {
        lastSyncDate = date
        setSyncing(false)
    }

    /// Call while sync is in progress
    func setSyncing(_ active: Bool) {
        isSyncing = active
        dotView.isHidden = active
        if active {
            spinner.startAnimating()
            textLabel.text = "Syncing…"
        } else {
            spinner.stopAnimating()
            updateDisplay()
        }
    }

    // MARK: - Display
    private func updateDisplay() {
        guard let date = lastSyncDate else {
            textLabel.text  = "Last synced: No data yet"
            dotView.backgroundColor = UIColor(white: 0.65, alpha: 1)
            return
        }
        let elapsed = Date().timeIntervalSince(date)
        textLabel.text          = "Last synced: \(relativeTime(elapsed))"
        dotView.backgroundColor = dotColor(elapsed)
    }

    private func relativeTime(_ seconds: TimeInterval) -> String {
        switch seconds {
        case ..<60:         return "just now"
        case ..<3600:       return "\(Int(seconds / 60)) min ago"
        case ..<86400:      return "\(Int(seconds / 3600)) hr\(Int(seconds / 3600) == 1 ? "" : "s") ago"
        default:            return "\(Int(seconds / 86400)) day\(Int(seconds / 86400) == 1 ? "" : "s") ago"
        }
    }

    private func dotColor(_ seconds: TimeInterval) -> UIColor {
        switch seconds {
        case ..<7200:   return UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)  // green < 2 h
        case ..<43200:  return UIColor(red: 1.00, green: 0.65, blue: 0.15, alpha: 1)  // orange 2–12 h
        default:        return UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1)  // red > 12 h
        }
    }

    @objc private func syncTapped() {
        onSyncTapped?()
    }
}

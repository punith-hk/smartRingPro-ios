import UIKit

final class Loader {

    static let shared = Loader()
    private init() {}

    private var overlay: UIView?
    private var timeoutWork: DispatchWorkItem?

    func show(on view: UIView, message: String = "Loading...", timeout: TimeInterval = 0) {
        if overlay != nil { return }

        // Full-screen dim overlay
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Card
        let card = UIView()
        card.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(card)

        // Spinner
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        card.addSubview(spinner)

        // Label
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 220),
            card.heightAnchor.constraint(equalToConstant: 120),

            spinner.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])

        view.addSubview(overlayView)
        overlay = overlayView

        // Auto-hide after timeout if specified
        if timeout > 0 {
            let work = DispatchWorkItem { [weak self] in self?.hide() }
            timeoutWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
        }
    }

    func hide() {
        timeoutWork?.cancel()
        timeoutWork = nil
        overlay?.removeFromSuperview()
        overlay = nil
    }
}

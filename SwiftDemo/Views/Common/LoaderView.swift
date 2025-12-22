import UIKit

final class Loader {

    static let shared = Loader()
    private init() {}

    private var overlay: UIView?

    func show(on view: UIView) {
        if overlay != nil { return }

        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.center = overlayView.center
        spinner.startAnimating()

        overlayView.addSubview(spinner)
        view.addSubview(overlayView)

        overlay = overlayView
    }

    func hide() {
        overlay?.removeFromSuperview()
        overlay = nil
    }
}

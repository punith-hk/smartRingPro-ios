import UIKit

/// A UINavigationController subclass that pins the logo permanently to the
/// center of the navigation bar — so it never slides during push/pop transitions.
final class LogoNavigationController: UINavigationController {

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "ic_logo_hearto"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = false
        return iv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 150),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
}

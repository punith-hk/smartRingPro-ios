import UIKit

final class SplashViewController: UIViewController {

    private let destination: UIViewController
    private let splashDuration: TimeInterval = 2.0

    init(destination: UIViewController) {
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let logoImageView = UIImageView(image: UIImage(named: "launch_logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        logoImageView.layer.cornerRadius = 24
        logoImageView.layer.masksToBounds = true

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) { [weak self] in
            guard let self = self,
                  let window = self.view.window else { return }

            window.rootViewController = self.destination
            UIView.transition(with: window,
                              duration: 0.4,
                              options: .transitionCrossDissolve,
                              animations: nil)
        }
    }
}

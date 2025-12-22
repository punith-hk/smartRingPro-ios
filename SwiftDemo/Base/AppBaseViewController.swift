import UIKit

class AppBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }

    // MARK: - Nav Bar Style
    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(
            red: 0.85,
            green: 0.92,
            blue: 0.97,
            alpha: 1
        )
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    // MARK: - Title
    func setScreenTitle(_ title: String) {
        navigationItem.title = title
    }

    // MARK: - Hamburger
    func showHamburger() {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        btn.tintColor = .black
        btn.addTarget(self, action: #selector(hamburgerTapped), for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
    }

    func hideHamburger() {
        navigationItem.leftBarButtonItem = nil
    }

    @objc private func hamburgerTapped() {
        print("🍔 Hamburger tapped")
        SideMenuContainerController.shared?.toggleMenu()
    }

}

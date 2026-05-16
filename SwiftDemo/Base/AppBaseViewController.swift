import UIKit

class AppBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupLogoTitleView()
        setupNotificationButton()
    }

    // MARK: - Nav Bar Style
    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false

        // Dark blue #15558D
        let navColor = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navColor
        // Hide text title — logo replaces it
        appearance.titleTextAttributes = [.foregroundColor: UIColor.clear]
        // Hide back button text, keep white arrow
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

        // Back arrow & bar buttons tint → white
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - Fixed Logo Title View (logo is now pinned to LogoNavigationController's nav bar)
    private func setupLogoTitleView() {
        // No-op: logo is rendered as a permanent subview of LogoNavigationController
        // so it never animates during push/pop transitions.
    }

    // MARK: - Notification Bell (right bar button)
    private func setupNotificationButton() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        let bellBtn = UIButton(type: .system)
        bellBtn.frame = CGRect(x: 2, y: 2, width: 40, height: 40)
        bellBtn.setImage(UIImage(systemName: "bell"), for: .normal)
        bellBtn.tintColor = .white
        bellBtn.addTarget(self, action: #selector(notificationTapped), for: .touchUpInside)
        container.addSubview(bellBtn)

        let badge = UILabel()
        badge.frame = CGRect(x: 24, y: 2, width: 18, height: 18)
        badge.backgroundColor = UIColor(red: 211/255, green: 47/255, blue: 47/255, alpha: 1)
        badge.textColor = .white
        badge.font = .systemFont(ofSize: 10, weight: .bold)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 9
        badge.layer.masksToBounds = true
        badge.isHidden = true
        badge.tag = 9001
        container.addSubview(badge)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
    }

    // MARK: - Badge Update
    func updateNotificationBadge(count: Int) {
        guard let container = navigationItem.rightBarButtonItem?.customView,
              let badge = container.viewWithTag(9001) as? UILabel else { return }
        if count > 0 {
            badge.text = count > 99 ? "99+" : "\(count)"
            badge.isHidden = false
        } else {
            badge.isHidden = true
        }
    }

    @objc private func notificationTapped() {
        // Navigation will be wired up later
    }

    // MARK: - Title (kept for back-button label — not displayed in nav bar)
    func setScreenTitle(_ title: String) {
        navigationItem.title = title
    }

    // MARK: - Hamburger
    func showHamburger() {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        btn.tintColor = .white
        btn.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        btn.addTarget(self, action: #selector(hamburgerTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
    }

    func hideHamburger() {
        navigationItem.leftBarButtonItem = nil
    }

    @objc private func hamburgerTapped() {
        SideMenuContainerController.shared?.toggleMenu()
    }

}

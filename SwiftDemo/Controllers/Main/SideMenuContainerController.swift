import UIKit
import YCProductSDK

class SideMenuContainerController: UIViewController, SideMenuDelegate {

    static weak var shared: SideMenuContainerController?

    private let menuWidth: CGFloat = 280
    private var isMenuOpen = false

    private let sideMenuVC = SideMenuViewController()
    private let mainTabsVC = MainTabBarController()
    private let dimmingView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        SideMenuContainerController.shared = self
        setupChildren()
    }

    // MARK: - Setup
    private func setupChildren() {

        sideMenuVC.delegate = self

        // MAIN CONTENT
        addChild(mainTabsVC)
        mainTabsVC.view.frame = view.bounds
        view.addSubview(mainTabsVC.view)
        mainTabsVC.didMove(toParent: self)

        // DIMMING VIEW
        dimmingView.frame = view.bounds
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.alpha = 0
        dimmingView.isUserInteractionEnabled = false
        view.addSubview(dimmingView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeMenu))
        dimmingView.addGestureRecognizer(tap)

        // SIDE MENU
        addChild(sideMenuVC)
        sideMenuVC.view.frame = CGRect(
            x: -menuWidth,
            y: 0,
            width: menuWidth,
            height: view.bounds.height
        )
        view.addSubview(sideMenuVC.view)
        sideMenuVC.didMove(toParent: self)

        setupPanGesture()
    }

    // MARK: - Menu Control
    func toggleMenu() {
        isMenuOpen.toggle()
        animateMenu()
    }

    @objc func closeMenu() {
        isMenuOpen = false
        animateMenu()
    }

    // MARK: - Animation
    private func animateMenu() {

        dimmingView.isUserInteractionEnabled = isMenuOpen

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                self.sideMenuVC.view.frame.origin.x =
                    self.isMenuOpen ? 0 : -self.menuWidth

                self.dimmingView.alpha = self.isMenuOpen ? 1 : 0
            },
            completion: nil
        )
    }

    // MARK: - Swipe Gesture
    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translationX = gesture.translation(in: view).x

        switch gesture.state {

        case .changed:
            let x = min(0, max(-menuWidth, -menuWidth + translationX))
            sideMenuVC.view.frame.origin.x = x
            dimmingView.alpha = min(1, translationX / menuWidth)

        case .ended:
            let shouldOpen = translationX > menuWidth / 2
            isMenuOpen = shouldOpen
            animateMenu()

        default:
            break
        }
    }

    // MARK: - SideMenuDelegate
    func didSelectMenu(_ action: SideMenuAction) {

        closeMenu()

        switch action {

        case .familyMembers:
            let vc = FamilyMembersViewController()
                mainTabsVC.pushScreen(vc, title: "Family Members")

        case .appointmentSummary:
            let vc = AppointmentsViewController()
            mainTabsVC.pushScreen(vc, title: "Appointments")

//        case .vitals:
//            mainTabsVC.openScreen(.home, title: "Vitals")

        case .profile:
            let vc = ProfileViewController()
            mainTabsVC.pushScreen(vc, title: "Profile")

        case .referFriend:
            let vc = ReferFriendViewController()
                mainTabsVC.pushScreen(vc, title: "Refer a Friend")

        case .logout:
            showLogoutConfirmation()
        }
    }
    
    private func showLogoutConfirmation() {

        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let logout = UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.performLogout()
        }

        alert.addAction(cancel)
        alert.addAction(logout)

        present(alert, animated: true)
    }


    private func performLogout() {

        closeMenu()

        // 🔥 BLE CLEANUP
        YCProduct.disconnectDevice { _, _ in }
        YCProduct.shared.isReconnectEnable = false

        DeviceSessionManager.shared.clearDevice()

        // Clear user session
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")

        let loginVC = LoginViewController()
        let nav = UINavigationController(rootViewController: loginVC)

        if let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate {

            sceneDelegate.setRootViewController(nav)
        }
    }


}

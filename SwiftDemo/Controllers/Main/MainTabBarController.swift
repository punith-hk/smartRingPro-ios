import UIKit

enum AppScreen {
    case home
    case appointments
    case familyMembers
    case profile
    case referFriend
}


class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {

        let home = createNav(
            vc: HealthDashboardViewController(),
            title: "Health",
            icon: "house"
        )

        let specialists = createNav(
            vc: SpecialistsViewController(),
            title: "Specialists",
            icon: "stethoscope"
        )

        let appointments = createNav(
            vc: AppointmentsViewController(),
            title: "Appointments",
            icon: "calendar"
        )

        let device = createNav(
            vc: DeviceViewController(),
            title: "Device",
            icon: "wave.3.right"
        )

        let profile = createNav(
            vc: CareViewController(),
            title: "Caring",
            icon: "person"
        )

        viewControllers = [home, specialists, appointments, device, profile]
    }

    private func createNav(
        vc: AppBaseViewController,
        title: String,
        icon: String
    ) -> UINavigationController {

        vc.setScreenTitle(title)
        vc.showHamburger()

        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: "\(icon).fill")
        )
        return nav
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .white
    }
    
    func openScreen(_ screen: AppScreen, title: String) {

        selectedIndex = {
            switch screen {
            case .home: return 0
            case .appointments: return 2
            case .familyMembers: return 4
            case .profile: return 4
            case .referFriend: return 4
            }
        }()

        if let nav = selectedViewController as? UINavigationController,
           let baseVC = nav.viewControllers.first as? AppBaseViewController {

            baseVC.setScreenTitle(title)
            baseVC.showHamburger()
        }
    }
    
    func pushScreen(_ vc: AppBaseViewController, title: String) {

        if let nav = selectedViewController as? UINavigationController {

            vc.setScreenTitle(title)
            // ❌ DO NOT call showHamburger()

            nav.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Pop to root when switching tabs
        if let nav = viewController as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
    }
}

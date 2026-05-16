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
            vc: HealthDashboardV2ViewController(),
            title: "Health",
            icon: "waveform.path.ecg",
            selectedIcon: "waveform.path.ecg"
        )

        let specialists = createNav(
            vc: SpecialistsViewController(),
            title: "Doctor",
            icon: "cross",
            selectedIcon: "cross.fill"
        )

        let appointments = createNav(
            vc: AppointmentsViewController(),
            title: "Appointment",
            icon: "calendar",
            selectedIcon: "calendar"
        )

        let device = createNav(
            vc: DeviceViewController(),
            title: "Device",
            icon: "record.circle",
            selectedIcon: "record.circle.fill"
        )

        let familyCare = createNav(
            vc: CareViewController(),
            title: "Family Care",
            icon: "person.3",
            selectedIcon: "person.3.fill"
        )

        viewControllers = [home, specialists, appointments, device, familyCare]
    }

    private func createNav(
        vc: AppBaseViewController,
        title: String,
        icon: String,
        selectedIcon: String
    ) -> UINavigationController {

        vc.setScreenTitle(title)
        vc.showHamburger()

        let nav = LogoNavigationController(rootViewController: vc)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: selectedIcon)
        )
        return nav
    }

    private func setupAppearance() {
        let navBlue = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)
        let selectedWhite = UIColor.white
        let unselectedWhite = UIColor.white.withAlphaComponent(0.55)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navBlue

        let itemAppearance = UITabBarItemAppearance()

        // Selected state
        itemAppearance.selected.iconColor = selectedWhite
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedWhite,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        // Normal (unselected) state
        itemAppearance.normal.iconColor = unselectedWhite
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedWhite,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
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

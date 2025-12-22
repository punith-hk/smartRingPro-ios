import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
            vc: ProfileViewController(),
            title: "Profile",
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
}

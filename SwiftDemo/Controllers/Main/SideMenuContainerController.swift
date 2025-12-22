import UIKit

class SideMenuContainerController: UIViewController {

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

        // 1️⃣ MAIN CONTENT (BOTTOM)
        addChild(mainTabsVC)
        mainTabsVC.view.frame = view.bounds
        view.addSubview(mainTabsVC.view)
        mainTabsVC.didMove(toParent: self)

        // 2️⃣ DIM BACKGROUND (MIDDLE)
        dimmingView.frame = view.bounds
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.alpha = 0
        view.addSubview(dimmingView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeMenu))
        dimmingView.addGestureRecognizer(tap)

        // 3️⃣ SIDE MENU (TOP)
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

    // MARK: - Actions
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
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            self.sideMenuVC.view.frame.origin.x =
                self.isMenuOpen ? 0 : -self.menuWidth

            self.dimmingView.alpha = self.isMenuOpen ? 1 : 0
        }
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
            if translationX > 0 { // swipe right
                let x = min(0, -menuWidth + translationX)
                sideMenuVC.view.frame.origin.x = x
                dimmingView.alpha = min(1, translationX / menuWidth)
            }

        case .ended:
            let shouldOpen = translationX > menuWidth / 2
            isMenuOpen = shouldOpen
            animateMenu()

        default:
            break
        }
    }
}

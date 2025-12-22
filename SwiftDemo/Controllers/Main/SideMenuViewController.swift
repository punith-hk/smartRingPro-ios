import UIKit

class SideMenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupMenu()
    }

    private func setupMenu() {

        let items = [
            "Family Members",
            "Appointment Summary",
            "Vitals",
            "Profile",
            "Refer a Friend",
            "Logout"
        ]

        var top: CGFloat = 140

        for item in items {
            let btn = UIButton(frame: CGRect(x: 20, y: top, width: 240, height: 44))
            btn.setTitle(item, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.contentHorizontalAlignment = .left
            view.addSubview(btn)
            top += 54
        }
    }
}

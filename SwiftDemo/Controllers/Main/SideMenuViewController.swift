import UIKit

protocol SideMenuDelegate: AnyObject {
    func didSelectMenu(_ action: SideMenuAction)
}

class SideMenuViewController: UIViewController {

    weak var delegate: SideMenuDelegate?

    let menuWidth: CGFloat = 280

    // Header references
    private var profileImageView: UIImageView!
    private var nameLabel: UILabel!
    private var numberLabel: UILabel!

    // Menu groups: (emoji+title, action)
    private let group1: [(String, SideMenuAction)] = [
        ("👨‍👩‍👧‍👦   Family Members",      .familyMembers),
        ("📅   Appointment Summary", .appointmentSummary),
    ]
    private let group2: [(String, SideMenuAction)] = [
        ("👤   Profile Settings",    .profile),
        ("🎁   Refer A Friend",      .referFriend),
    ]
    private let group3: [(String, SideMenuAction)] = [
        ("❓   Help & Support",      .helpSupport),
        ("🚪   Logout",              .logout),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupHeader()
        setupMenu()
        observeProfileUpdates()
        loadSavedProfileData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.frame.size.width = menuWidth
    }

    // MARK: - Header
    private func setupHeader() {
        // Account for status bar / safe area so content isn't cropped
        let topSafe: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 50
        let contentHeight: CGFloat = 120
        let headerHeight: CGFloat = topSafe + contentHeight

        let header = UIView(frame: CGRect(x: 0, y: 0, width: menuWidth, height: headerHeight))
        header.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1) // #D9EDFF
        view.addSubview(header)

        // Close (back arrow) button — top right, below status bar (44×44 min tap target)
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "chevron.left")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        ), for: .normal)
        closeBtn.tintColor = .black
        closeBtn.frame = CGRect(x: menuWidth - 54, y: topSafe + 4, width: 44, height: 44)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        header.addSubview(closeBtn)

        // Profile image (80×80, circle) — vertically centred in content area
        let imgSize: CGFloat = 80
        let imgY = topSafe + (contentHeight - imgSize) / 2
        let imgView = UIImageView(frame: CGRect(x: 16, y: imgY, width: imgSize, height: imgSize))
        imgView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        imgView.layer.cornerRadius = imgSize / 2
        imgView.layer.borderWidth = 2
        imgView.layer.borderColor = UIColor.white.cgColor
        imgView.clipsToBounds = true
        imgView.contentMode = .scaleAspectFill
        imgView.image = UIImage(systemName: "person.circle.fill")
        imgView.tintColor = UIColor(white: 0.7, alpha: 1)
        header.addSubview(imgView)
        profileImageView = imgView

        // Text section (name + number) to the right of image
        let textX = 16 + imgSize + 12
        let textWidth = menuWidth - textX - 16

        let nameLbl = UILabel(frame: CGRect(x: textX, y: imgView.frame.midY - 22, width: textWidth, height: 24))
        nameLbl.text = "Unknown User"
        nameLbl.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        nameLbl.textColor = UIColor(white: 0.08, alpha: 1)
        nameLbl.adjustsFontSizeToFitWidth = true
        nameLbl.minimumScaleFactor = 0.8
        header.addSubview(nameLbl)
        nameLabel = nameLbl

        let numLbl = UILabel(frame: CGRect(x: textX, y: imgView.frame.midY + 4, width: textWidth, height: 20))
        numLbl.text = "Not Available"
        numLbl.font = UIFont.systemFont(ofSize: 13)
        numLbl.textColor = UIColor(white: 0.45, alpha: 1)
        numLbl.adjustsFontSizeToFitWidth = true
        numLbl.minimumScaleFactor = 0.8
        header.addSubview(numLbl)
        numberLabel = numLbl

        // Tap the profile area (left side of header) → open profile
        // Deliberately excludes the right-side close button area
        let profileTapArea = UIView(frame: CGRect(x: 0, y: topSafe, width: menuWidth - 60, height: contentHeight))
        profileTapArea.backgroundColor = .clear
        header.addSubview(profileTapArea)
        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        profileTapArea.isUserInteractionEnabled = true
        profileTapArea.addGestureRecognizer(tap)
    }

    @objc private func closeTapped() {
        NotificationCenter.default.post(name: .init("SideMenuCloseRequested"), object: nil)
    }

    @objc private func headerTapped() {
        delegate?.didSelectMenu(.profile)
    }

    // MARK: - Menu
    private func setupMenu() {
        let topSafe: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 50
        var top: CGFloat = topSafe + 120 + 8 // just below header

        let allItems = group1 + group2 + group3
        for (index, item) in allItems.enumerated() {
            let btn = makeMenuButton(title: item.0, action: item.1, tag: tagFor(item.1))
            btn.frame = CGRect(x: 0, y: top, width: menuWidth, height: 52)
            view.addSubview(btn)
            top += 52
            // Divider after every item except the last
            if index < allItems.count - 1 {
                let sep = UIView(frame: CGRect(x: 16, y: top, width: menuWidth - 32, height: 1))
                sep.backgroundColor = UIColor(white: 0.88, alpha: 1)
                view.addSubview(sep)
                top += 1
            }
        }
    }

    private func makeMenuButton(title: String, action: SideMenuAction, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag = tag
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor(white: 0.12, alpha: 1), for: .normal)
        btn.contentHorizontalAlignment = .left
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        btn.backgroundColor = .clear

        // Highlight on touch
        btn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        btn.addTarget(self, action: #selector(menuTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        sender.backgroundColor = UIColor(white: 0.95, alpha: 1)
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        sender.backgroundColor = .clear
    }

    private let allActions: [SideMenuAction] = [
        .familyMembers, .appointmentSummary,
        .profile, .referFriend,
        .helpSupport, .logout
    ]

    private func tagFor(_ action: SideMenuAction) -> Int {
        return allActions.firstIndex(of: action) ?? 0
    }

    @objc private func menuTapped(_ sender: UIButton) {
        guard sender.tag < allActions.count else { return }
        delegate?.didSelectMenu(allActions[sender.tag])
    }

    // MARK: - Profile data
    private func observeProfileUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateProfileHeader(_:)),
            name: .profileDataLoaded,
            object: nil
        )
    }

    @objc private func updateProfileHeader(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let name = userInfo["name"] as? String, !name.isEmpty {
            nameLabel?.text = name
        }
        if let phone = userInfo["phone"] as? String, !phone.isEmpty {
            numberLabel?.text = phone
        } else if let email = userInfo["email"] as? String, !email.isEmpty {
            numberLabel?.text = email
        }
        if let imageUrlString = userInfo["imageUrl"] as? String,
           !imageUrlString.isEmpty,
           let url = URL(string: imageUrlString) {
            profileImageView?.loadImage(from: url)
        }
    }

    private func loadSavedProfileData() {
        // Name: prefer full profileName saved after profile load, fall back to username from login
        let name = UserDefaultsManager.shared.profileName ?? UserDefaultsManager.shared.userName
        if let name = name, !name.isEmpty {
            nameLabel?.text = name
        }
        if let phone = UserDefaultsManager.shared.mobileNumber, !phone.isEmpty {
            numberLabel?.text = phone
        }
        if let photoUrl = UserDefaultsManager.shared.profilePhotoUrl,
           !photoUrl.isEmpty,
           let url = URL(string: photoUrl) {
            profileImageView?.loadImage(from: url)
        }
    }
}

// MARK: - SideMenuAction equatable for indexOf
extension SideMenuAction: Equatable {}


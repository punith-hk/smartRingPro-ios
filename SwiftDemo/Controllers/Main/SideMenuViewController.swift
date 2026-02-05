import UIKit

protocol SideMenuDelegate: AnyObject {
    func didSelectMenu(_ action: SideMenuAction)
}

class SideMenuViewController: UIViewController {

    weak var delegate: SideMenuDelegate?

    private let menuWidth: CGFloat = 280
    
    // Header UI elements
    private var profileImageView: UIImageView?
    private var nameLabel: UILabel?

    private let items: [(String, String, SideMenuAction)] = [
        ("Family Members", "person.2", .familyMembers),
        ("Appointment Summary", "calendar", .appointmentSummary),
//        ("Vitals", "heart.text.square", .vitals),
        ("Profile", "person.circle", .profile),
        ("Refer a Friend", "person.crop.circle.badge.plus", .referFriend),
        ("Logout", "arrow.backward.square", .logout)
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

        let header = UIView(frame: CGRect(x: 0, y: 0, width: menuWidth, height: 140))
        header.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.97, alpha: 1)
        view.addSubview(header)

        let imageView = UIImageView(frame: CGRect(x: 20, y: 50, width: 60, height: 60))
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 30
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .lightGray
        header.addSubview(imageView)
        self.profileImageView = imageView

        let label = UILabel(frame: CGRect(x: 100, y: 65, width: 160, height: 30))
        label.text = "Welcome"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        header.addSubview(label)
        self.nameLabel = label
        
        // Add tap gesture to header
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        header.isUserInteractionEnabled = true
        header.addGestureRecognizer(tapGesture)
    }
    
    @objc private func headerTapped() {
        delegate?.didSelectMenu(.profile)
    }
    
    // MARK: - Profile Updates
    private func observeProfileUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateProfileHeader),
            name: .profileDataLoaded,
            object: nil
        )
    }
    
    @objc private func updateProfileHeader(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let name = userInfo["name"] as? String,
              let imageUrlString = userInfo["imageUrl"] as? String else { return }
        
        // Update name
        if !name.isEmpty {
            nameLabel?.text = name
        }
        
        // Update profile image
        if !imageUrlString.isEmpty, let url = URL(string: imageUrlString) {
            profileImageView?.loadImage(from: url)
        }
    }
    
    private func loadSavedProfileData() {
        // Load profile data from UserDefaults
        if let name = UserDefaultsManager.shared.profileName, !name.isEmpty {
            nameLabel?.text = name
        }
        
        if let photoUrl = UserDefaultsManager.shared.profilePhotoUrl, 
           !photoUrl.isEmpty,
           let url = URL(string: photoUrl) {
            profileImageView?.loadImage(from: url)
        }
    }

    // MARK: - Menu Items
    private func setupMenu() {

        var top: CGFloat = 160

        for (index, item) in items.enumerated() {

            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: top, width: menuWidth, height: 48)
            button.tag = index

            button.setImage(UIImage(systemName: item.1), for: .normal)
            button.setTitle("  \(item.0)", for: .normal)

            button.tintColor = .black
            button.setTitleColor(.black, for: .normal)
            button.contentHorizontalAlignment = .left
            button.titleLabel?.font = .systemFont(ofSize: 15)

            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)

            button.addTarget(self, action: #selector(menuTapped(_:)), for: .touchUpInside)

            view.addSubview(button)
            top += 54
        }
    }

    @objc private func menuTapped(_ sender: UIButton) {
        delegate?.didSelectMenu(items[sender.tag].2)
    }
}

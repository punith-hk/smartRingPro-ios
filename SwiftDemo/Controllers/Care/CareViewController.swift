import UIKit

enum AssociationStep {
    case enterPhone
    case verifyOtp
}

final class CareViewController: AppBaseViewController,
                               UITableViewDataSource,
                               UITableViewDelegate {


    private var linkedAccounts: [LinkedAccountInfo] = []
    private let userId: Int = UserDefaults.standard.integer(forKey: "id")

    private let addAssociationButton = UIButton(type: .system)
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Caring Mode"
        setupUI()
        fetchLinkedAccounts()
    }

    private func setupUI() {

        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

        addAssociationButton.setTitle("+ Add Association", for: .normal)
        addAssociationButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addAssociationButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        addAssociationButton.setTitleColor(.white, for: .normal)
        addAssociationButton.layer.cornerRadius = 8
        addAssociationButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        addAssociationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addAssociationButton)

        addAssociationButton.addTarget(
            self,
            action: #selector(addAssociationTapped),
            for: .touchUpInside
        )

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(LinkedAccountCell.self, forCellReuseIdentifier: LinkedAccountCell.reuseId)

        tableView.dataSource = self
        tableView.delegate = self   // ✅ THIS WAS MISSING

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            addAssociationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            addAssociationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addAssociationButton.heightAnchor.constraint(equalToConstant: 30),

            tableView.topAnchor.constraint(equalTo: addAssociationButton.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }


    private func fetchLinkedAccounts() {
        LinkedAccountService.shared.getLinkedAccountData(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let list) = result {
                    self?.linkedAccounts = list
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    @objc private func addAssociationTapped() {

        let vc = AddAssociationViewController()

        vc.onSuccess = { [weak self] in
            self?.fetchLinkedAccounts()   // 🔁 REFRESH API
        }

        navigationController?.pushViewController(vc, animated: true)
    }

}

extension CareViewController {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        linkedAccounts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: LinkedAccountCell.reuseId,
            for: indexPath
        ) as! LinkedAccountCell

        cell.configure(with: linkedAccounts[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let account = linkedAccounts[indexPath.row]

        let vc = LinkedAccountDetailsViewController()
        vc.linkedAccountId = account.id
        vc.linkedAccountName = account.name

        navigationController?.pushViewController(vc, animated: true)
    }

}

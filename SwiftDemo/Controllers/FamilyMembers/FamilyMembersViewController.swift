import UIKit

final class FamilyMembersViewController: AppBaseViewController {

    // MARK: - Data
    private var familyMembers: [FamilyMember] = []
    private let userId: Int = UserDefaults.standard.integer(forKey: "id")

    // MARK: - UI
    private let addButton = UIButton(type: .system)
    private let tableView = UITableView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchFamilyMembers()
    }

    // MARK: - UI Setup
    private func setupUI() {

        title = "Family members"
        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

        // Add Dependents Button
        addButton.setTitle("+ Add Dependents", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)

        addButton.addTarget(self, action: #selector(addDependentTapped), for: .touchUpInside)

        // TableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(FamilyMemberCell.self, forCellReuseIdentifier: FamilyMemberCell.reuseId)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                addButton.heightAnchor.constraint(equalToConstant: 30),

            tableView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - API
    private func fetchFamilyMembers() {

        ProfileService.shared.getDependents(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.familyMembers = response.data
                    self?.tableView.reloadData()

                case .failure:
                    Toast.show(message: "Failed to load family members", in: self?.view ?? UIView())
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func addDependentTapped() {

        let vc = FamilyMemberFormViewController()
        vc.mode = .add

        vc.onSuccess = { [weak self] in
            Toast.show(message: "Dependent added successfully", in: self?.view ?? UIView())
            self?.fetchFamilyMembers()   // 🔁 REFRESH LIST
        }

        navigationController?.pushViewController(vc, animated: true)
    }


    private func confirmDelete(member: FamilyMember) {

        let alert = UIAlertController(
            title: "Delete Family Member",
            message: "Are you sure you want to delete this family member?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteMember(member)
        })

        present(alert, animated: true)
    }

    private func deleteMember(_ member: FamilyMember) {

        ProfileService.shared.deleteFamilyMember(
            userId: userId,
            dependentId: member.id
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    Toast.show(message: response.message, in: self?.view ?? UIView())
                    self?.fetchFamilyMembers()

                case .failure:
                    Toast.show(message: "Delete failed", in: self?.view ?? UIView())
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension FamilyMembersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        familyMembers.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: FamilyMemberCell.reuseId,
            for: indexPath
        ) as! FamilyMemberCell

        let member = familyMembers[indexPath.row]
        cell.configure(with: member)

        cell.onEdit = {
            self.openEdit(member)
        }

        cell.onDelete = {
            self.confirmDelete(member: member)
        }

        return cell
    }
    
    private func openEdit(_ member: FamilyMember) {
        let vc = FamilyMemberFormViewController()
        vc.mode = .edit(member)
        vc.onSuccess = {
            Toast.show(message: "Dependent updated successfully", in: self.view)
                self.fetchFamilyMembers()   // 🔁 REFRESH LIST
            }
        navigationController?.pushViewController(vc, animated: true)
    }

}

import UIKit

final class SpecialistsViewController: AppBaseViewController {
    
    // MARK: - Properties
    private var departments: [DepartmentItem] = []
    private let tableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("Specialists")
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        
        setupTableView()
        fetchDepartments()
    }
    
    // MARK: - API
    private func fetchDepartments() {
        Loader.shared.show(on: view, message: "Loading Specialists...", timeout: 10)
        DoctorService.shared.getDepartments { [weak self] result in
            DispatchQueue.main.async {
                Loader.shared.hide()
                guard let self = self else { return }
                switch result {
                case .success(let items):
                    self.departments = items
                    self.tableView.reloadData()
                case .failure(let error):
                    print("❌ SpecialistsVC: failed to load departments — \(error)")
                    // Fallback: show empty state (no mock data)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Setup UI
    private func setupTableView() {
        tableView.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SpecialistCell.self, forCellReuseIdentifier: SpecialistCell.reuseId)
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension SpecialistsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return departments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SpecialistCell.reuseId,
            for: indexPath
        ) as? SpecialistCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: departments[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SpecialistsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let department = departments[indexPath.row]
        
        print("🏥 Selected department: \(department.description) (ID: \(department.department_id))")
        
        // Navigate to DoctorsViewController
        let doctorsVC = DoctorsViewController(
            departmentId: department.department_id,
            departmentName: department.description
        )
        navigationController?.pushViewController(doctorsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116 // 100 card + 16 padding
    }
}


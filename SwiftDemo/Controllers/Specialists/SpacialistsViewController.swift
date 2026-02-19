import UIKit

final class SpecialistsViewController: AppBaseViewController {
    
    // MARK: - Properties
    private let specialists = Specialization.mockSpecialists
    private let tableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("Specialists")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        setupTableView()
    }
    
    // MARK: - Setup UI
    private func setupTableView() {
        tableView.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
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
        return specialists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SpecialistCell.reuseId,
            for: indexPath
        ) as? SpecialistCell else {
            return UITableViewCell()
        }
        
        let specialist = specialists[indexPath.row]
        cell.configure(with: specialist)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SpecialistsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let specialist = specialists[indexPath.row]
        
        print("🏥 Selected specialist: \(specialist.name) (ID: \(specialist.id))")
        
        // Navigate to DoctorsViewController
        let doctorsVC = DoctorsViewController(
            departmentId: specialist.id,
            departmentName: specialist.name
        )
        navigationController?.pushViewController(doctorsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116 // 100 card + 16 padding
    }
}


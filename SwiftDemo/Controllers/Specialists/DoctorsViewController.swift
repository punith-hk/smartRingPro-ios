import UIKit

/// Doctors list for a specific department
final class DoctorsViewController: AppBaseViewController {
    
    // MARK: - Properties
    private let departmentId: Int
    private let departmentName: String
    private var doctors: [Doctor] = []
    
    private let tableView = UITableView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UILabel()
    
    private let TAG = "DoctorsViewController"
    
    // MARK: - Init
    init(departmentId: Int, departmentName: String) {
        self.departmentId = departmentId
        self.departmentName = departmentName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle(departmentName)
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        setupTableView()
        setupLoadingIndicator()
        setupEmptyLabel()
        
        fetchDoctors()
        
        print("[\(TAG)] 🏥 Loaded for department: \(departmentName) (ID: \(departmentId))")
    }
    
    // MARK: - Setup UI
    private func setupTableView() {
        tableView.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DoctorCell.self, forCellReuseIdentifier: DoctorCell.reuseId)
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
    
    private func setupLoadingIndicator() {
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupEmptyLabel() {
        emptyLabel.text = "No doctors available"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .white
        emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - API Call
    private func fetchDoctors() {
        loadingIndicator.startAnimating()
        tableView.isHidden = true
        emptyLabel.isHidden = true
        
        print("[\(TAG)] 📥 Fetching doctors for department \(departmentId)...")
        
        DoctorService.shared.getDoctors(departmentId: departmentId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let response):
                    print("[\(self.TAG)] ✅ Fetched \(response.data.doctors.count) doctors")
                    self.doctors = response.data.doctors
                    
                    if self.doctors.isEmpty {
                        self.emptyLabel.isHidden = false
                    } else {
                        self.tableView.isHidden = false
                        self.tableView.reloadData()
                    }
                    
                case .failure(let error):
                    print("[\(self.TAG)] ❌ Failed to fetch doctors: \(error)")
                    self.emptyLabel.text = "Failed to load doctors\n\nPlease check your connection and try again."
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension DoctorsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return doctors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DoctorCell.reuseId,
            for: indexPath
        ) as? DoctorCell else {
            return UITableViewCell()
        }
        
        let doctor = doctors[indexPath.row]
        cell.configure(with: doctor)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DoctorsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let doctor = doctors[indexPath.row]
        
        print("[\(TAG)] 🩺 Selected doctor: \(doctor.displayName) (ID: \(doctor.id))")
        
        // Navigate to Symptoms screen
        let symptomsVC = SymptomsViewController(doctor: doctor)
        navigationController?.pushViewController(symptomsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 106 // 90 card + 16 padding
    }
}

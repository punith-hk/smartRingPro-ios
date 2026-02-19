import UIKit

final class AppointmentsViewController: AppBaseViewController {
    
    // MARK: - Properties
    private var appointments: [PatientAppointment] = []
    private var currentTab: Tab
    
    enum Tab {
        case appointments
        case summary
    }
    
    // Computed property to get filtered appointments based on current tab
    private var displayedAppointments: [PatientAppointment] {
        switch currentTab {
        case .appointments:
            return appointments
        case .summary:
            return appointments.filter { $0.isCompleted }
        }
    }
    
    // MARK: - Initialization
    init(defaultTab: Tab = .appointments) {
        self.currentTab = defaultTab
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.currentTab = .appointments
        super.init(coder: coder)
    }
    
    // MARK: - UI Components
    private let tabContainer = UIView()
    private let appointmentsTabButton = UIButton(type: .system)
    private let summaryTabButton = UIButton(type: .system)
    
    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    
    private let TAG = "AppointmentsViewController"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("Appointments")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        setupTabBar()
        setupTableView()
        setupEmptyStateView()
        setupLoadingView()
        
        // Set initial tab UI state
        updateTabUI()
        
        fetchAppointments()
    }
    
    // MARK: - Setup UI
    private func setupTabBar() {
        tabContainer.backgroundColor = .clear
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabContainer)
        
        // Appointments Tab
        appointmentsTabButton.setTitle("Appointments", for: .normal)
        appointmentsTabButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        appointmentsTabButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        appointmentsTabButton.setTitleColor(.black, for: .normal)
        appointmentsTabButton.layer.cornerRadius = 12
        appointmentsTabButton.translatesAutoresizingMaskIntoConstraints = false
        appointmentsTabButton.addTarget(self, action: #selector(appointmentsTabTapped), for: .touchUpInside)
        tabContainer.addSubview(appointmentsTabButton)
        
        // Summary Tab
        summaryTabButton.setTitle("Summary", for: .normal)
        summaryTabButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        summaryTabButton.backgroundColor = .clear
        summaryTabButton.setTitleColor(.black, for: .normal)
        summaryTabButton.layer.cornerRadius = 12
        summaryTabButton.translatesAutoresizingMaskIntoConstraints = false
        summaryTabButton.addTarget(self, action: #selector(summaryTabTapped), for: .touchUpInside)
        tabContainer.addSubview(summaryTabButton)
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tabContainer.heightAnchor.constraint(equalToConstant: 60),
            
            appointmentsTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            appointmentsTabButton.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            appointmentsTabButton.trailingAnchor.constraint(equalTo: tabContainer.centerXAnchor, constant: -4),
            appointmentsTabButton.heightAnchor.constraint(equalToConstant: 50),
            
            summaryTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            summaryTabButton.leadingAnchor.constraint(equalTo: tabContainer.centerXAnchor, constant: 4),
            summaryTabButton.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            summaryTabButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AppointmentCell.self, forCellReuseIdentifier: "AppointmentCell")
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyStateView() {
        emptyStateView.backgroundColor = .clear
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        
        emptyStateLabel.text = "No Completed Appointments\n\nCompleted appointments will appear here"
        emptyStateLabel.textColor = .white
        emptyStateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 8),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupLoadingView() {
        loadingView.color = .white
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        loadingView.layer.cornerRadius = 16
        loadingView.hidesWhenStopped = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        loadingLabel.text = "Loading Appointments..."
        loadingLabel.textColor = .white
        loadingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 220),
            loadingView.heightAnchor.constraint(equalToConstant: 120),
            
            loadingLabel.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: -20),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 12),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchAppointments() {
        let patientId = UserDefaultsManager.shared.userId
        guard patientId > 0 else {
            print("[\(TAG)] ❌ No patient ID found")
            return
        }
        
        print("[\(TAG)] 🔄 Fetching appointments for patient: \(patientId)")
        loadingView.startAnimating()
        
        AppointmentService.shared.getMyAppointments(patientId: patientId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingView.stopAnimating()
                
                switch result {
                case .success(let response):
                    print("[\(self.TAG)] ✅ Loaded \(response.data.count) appointments")
                    self.appointments = response.data.sorted { $0.apptDate > $1.apptDate } // Sort by date descending
                    self.tableView.reloadData()
                    
                    // Update UI based on current tab
                    if self.currentTab == .summary {
                        let hasCompletedAppointments = !self.displayedAppointments.isEmpty
                        self.tableView.isHidden = !hasCompletedAppointments
                        self.emptyStateView.isHidden = hasCompletedAppointments
                    }
                    
                case .failure(let error):
                    print("[\(self.TAG)] ❌ Failed to fetch appointments: \(error)")
                    self.showErrorAlert(message: "Failed to load appointments. Please try again.")
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Tab Actions
    @objc private func appointmentsTabTapped() {
        print("[\(TAG)] 📋 Appointments tab tapped")
        currentTab = .appointments
        updateTabUI()
        tableView.reloadData()
        
        // Always show table view for appointments tab
        tableView.isHidden = false
        emptyStateView.isHidden = true
    }
    
    @objc private func summaryTabTapped() {
        print("[\(TAG)] 📊 Summary tab tapped")
        currentTab = .summary
        updateTabUI()
        tableView.reloadData()
        
        // Show table view if there are completed appointments, otherwise show empty state
        let hasCompletedAppointments = !displayedAppointments.isEmpty
        tableView.isHidden = !hasCompletedAppointments
        emptyStateView.isHidden = hasCompletedAppointments
        
        if hasCompletedAppointments {
            print("[\(TAG)] 📊 Showing \(displayedAppointments.count) completed appointments")
        }
    }
    
    private func updateTabUI() {
        if currentTab == .appointments {
            appointmentsTabButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
            appointmentsTabButton.setTitleColor(.black, for: .normal)
            appointmentsTabButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            
            summaryTabButton.backgroundColor = .clear
            summaryTabButton.setTitleColor(.black, for: .normal)
            summaryTabButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        } else {
            appointmentsTabButton.backgroundColor = .clear
            appointmentsTabButton.setTitleColor(.black, for: .normal)
            appointmentsTabButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            
            summaryTabButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
            summaryTabButton.setTitleColor(.black, for: .normal)
            summaryTabButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        }
    }
}

// MARK: - UITableViewDataSource
extension AppointmentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedAppointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentCell", for: indexPath) as! AppointmentCell
        let isSummaryTab = (currentTab == .summary)
        cell.configure(with: displayedAppointments[indexPath.row], isSummaryLayout: isSummaryTab)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AppointmentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let appointment = displayedAppointments[indexPath.row]
        print("[\(TAG)] 📋 Selected appointment: \(appointment.apptId)")
        
        // Only navigate if appointment is completed
        if appointment.isCompleted {
            let detailsVC = AppointmentDetailsViewController(appointment: appointment)
            navigationController?.pushViewController(detailsVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return currentTab == .summary ? 100 : 120
    }
}

// MARK: - AppointmentCell
private class AppointmentCell: UITableViewCell {
    
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let doctorNameLabel = UILabel()
    private let videoIconImageView = UIImageView()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()
    private let arrowImageView = UIImageView()
    private let patientNameLabel = UILabel()
    
    // Constraint storage for dynamic layouts
    private var appointmentConstraints: [NSLayoutConstraint] = []
    private var summaryConstraints: [NSLayoutConstraint] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 25
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .lightGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Doctor Name
        doctorNameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        doctorNameLabel.textColor = .black
        doctorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(doctorNameLabel)
        
        // Video Icon
        videoIconImageView.image = UIImage(systemName: "video.fill")
        videoIconImageView.tintColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        videoIconImageView.contentMode = .scaleAspectFit
        videoIconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(videoIconImageView)
        
        // Date Label
        dateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .darkGray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)
        
        // Time Label
        timeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = .darkGray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)
        
        // Status Label
        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        // Patient Name Label (for summary tab)
        patientNameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        patientNameLabel.textColor = .darkGray
        patientNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(patientNameLabel)
        
        // Arrow Icon
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .darkGray
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(arrowImageView)
        
        // Base constraints (always active)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            arrowImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),
            
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Appointments tab constraints
        appointmentConstraints = [
            doctorNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            doctorNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            
            videoIconImageView.leadingAnchor.constraint(equalTo: doctorNameLabel.trailingAnchor, constant: 6),
            videoIconImageView.centerYAnchor.constraint(equalTo: doctorNameLabel.centerYAnchor),
            videoIconImageView.widthAnchor.constraint(equalToConstant: 20),
            videoIconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            dateLabel.topAnchor.constraint(equalTo: doctorNameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),
            
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            
            statusLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12)
        ]
        
        // Summary tab constraints
        summaryConstraints = [
            patientNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            patientNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            patientNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),
            
            doctorNameLabel.topAnchor.constraint(equalTo: patientNameLabel.bottomAnchor, constant: 4),
            doctorNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            doctorNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: doctorNameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8)
        ]
    }
    
    func configure(with appointment: PatientAppointment, isSummaryLayout: Bool = false) {
        
        if isSummaryLayout {
            // Deactivate appointment constraints, activate summary constraints
            NSLayoutConstraint.deactivate(appointmentConstraints)
            NSLayoutConstraint.activate(summaryConstraints)
            
            // Summary tab layout: Patient name, Doctor name, Appointment Date (combined)
            profileImageView.isHidden = true
            videoIconImageView.isHidden = true
            timeLabel.isHidden = true
            statusLabel.isHidden = true
            patientNameLabel.isHidden = false
            arrowImageView.isHidden = false // Always show arrow in summary tab
            
            patientNameLabel.text = "Patient name       :  \(appointment.patientName)"
            doctorNameLabel.text = "Doctor name       :  \(appointment.doctorName)"
            doctorNameLabel.font = .systemFont(ofSize: 14, weight: .regular)
            doctorNameLabel.textColor = .darkGray
            
            // Format date-time combined
            let dateTime = formatDateTime(date: appointment.apptDate, time: appointment.apptTime)
            dateLabel.text = "Appointment Date  :  \(dateTime)"
            
        } else {
            // Deactivate summary constraints, activate appointment constraints
            NSLayoutConstraint.deactivate(summaryConstraints)
            NSLayoutConstraint.activate(appointmentConstraints)
            
            // Appointments tab layout: Doctor image, name, video icon, date, time, status
            profileImageView.isHidden = false
            videoIconImageView.isHidden = false
            timeLabel.isHidden = false
            statusLabel.isHidden = false
            patientNameLabel.isHidden = true
            
            doctorNameLabel.text = appointment.doctorName
            doctorNameLabel.font = .systemFont(ofSize: 16, weight: .bold)
            doctorNameLabel.textColor = .black
            
            // Date format
            dateLabel.text = "Appointment Date  :  \(appointment.apptDate)"
            
            // Time format
            timeLabel.text = "Appointment Time  :  \(appointment.apptTime)"
            
            // Status
            statusLabel.text = "Appointment status  :  \(appointment.statusText)"
            statusLabel.textColor = appointment.statusColor
            
            // Arrow visibility (only for completed appointments)
            arrowImageView.isHidden = !appointment.isCompleted
            
            // Load doctor image
            if let imageUrlString = appointment.doctorImageUrl, let imageURL = URL(string: imageUrlString) {
                profileImageView.loadImage(from: imageURL)
            } else {
                profileImageView.image = UIImage(systemName: "person.circle.fill")
                profileImageView.tintColor = .lightGray
            }
        }
    }
    
    private func formatDateTime(date: String, time: String) -> String {
        // Input: date="2025-10-03", time="09:00:00"
        // Output: "2025-10-03 09:00:00"
        return "\(date) \(time)"
    }
}

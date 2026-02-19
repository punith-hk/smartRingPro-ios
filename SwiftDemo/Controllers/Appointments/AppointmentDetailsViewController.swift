import UIKit

class AppointmentDetailsViewController: UIViewController {
    
    // MARK: - Properties
    private let TAG = "AppointmentDetailsViewController"
    private let appointment: PatientAppointment
    private var appointmentDetails: AppointmentDetailsResponse?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Initialization
    init(appointment: PatientAppointment) {
        self.appointment = appointment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[\(TAG)] 📋 Loading appointment details for ID: \(appointment.apptId)")
        setupUI()
        fetchAppointmentDetails()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Appointment Details"
        view.backgroundColor = UIColor(red:0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        // Configure navigation bar to match other screens
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.97, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Loading Indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - API Call
    private func fetchAppointmentDetails() {
        loadingIndicator.startAnimating()
        
        AppointmentService.shared.getAppointmentDetails(appointmentId: appointment.apptId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let response):
                    print("[\(self.TAG)] ✅ Loaded appointment details")
                    if let details = response.first {
                        self.appointmentDetails = details
                        self.buildDetailView(with: details)
                    }
                    
                case .failure(let error):
                    print("[\(self.TAG)] ❌ Failed to fetch details: \(error)")
                    self.showErrorAlert(message: "Failed to load appointment details")
                }
            }
        }
    }
    
    // MARK: - Build Detail View
    private func buildDetailView(with details: AppointmentDetailsResponse) {
        // Clear existing content
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        var lastView: UIView?
        
        // Header Section
        let headerView = createHeaderView(details: details)
        contentView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100)
        ])
        lastView = headerView
        
        // Patient Info Section
        let patientInfoView = createPatientInfoView(details: details)
        contentView.addSubview(patientInfoView)
        NSLayoutConstraint.activate([
            patientInfoView.topAnchor.constraint(equalTo: lastView!.bottomAnchor),
            patientInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            patientInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            patientInfoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        lastView = patientInfoView
        
        // Vitals Section
        if !details.uniqueVitals.isEmpty {
            let vitalsView = createVitalsView(vitals: details.uniqueVitals)
            contentView.addSubview(vitalsView)
            NSLayoutConstraint.activate([
                vitalsView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
                vitalsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                vitalsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
            lastView = vitalsView
        }
        
        // Symptoms Section
        if !details.uniqueSymptoms.isEmpty {
            let symptomsView = createSymptomsView(symptoms: details.uniqueSymptoms)
            contentView.addSubview(symptomsView)
            NSLayoutConstraint.activate([
                symptomsView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
                symptomsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                symptomsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
            lastView = symptomsView
        }
        
        // Diagnosis Section
        if let diagnosis = details.diseaseName, !diagnosis.isEmpty {
            let diagnosisView = createDiagnosisView(diagnosis: diagnosis)
            contentView.addSubview(diagnosisView)
            NSLayoutConstraint.activate([
                diagnosisView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
                diagnosisView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                diagnosisView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                diagnosisView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
            ])
            lastView = diagnosisView
        }
        
        // Prescriptions Section
        if !details.prescriptions.isEmpty {
            let prescriptionsView = createPrescriptionsView(prescriptions: details.prescriptions)
            contentView.addSubview(prescriptionsView)
            NSLayoutConstraint.activate([
                prescriptionsView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
                prescriptionsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                prescriptionsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
            lastView = prescriptionsView
        }
        
        // Remarks Section
        let remarksView = createRemarksView(remarks: details.remarks)
        contentView.addSubview(remarksView)
        NSLayoutConstraint.activate([
            remarksView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 8),
            remarksView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            remarksView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            remarksView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Create Header View
    private func createHeaderView(details: AppointmentDetailsResponse) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Doctor name and department (right side)
        let doctorNameLabel = UILabel()
        doctorNameLabel.text = details.doctorName
        doctorNameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        doctorNameLabel.textColor = .white
        doctorNameLabel.textAlignment = .right
        doctorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doctorNameLabel)
        
        let departmentLabel = UILabel()
        departmentLabel.text = details.doctorDepartment
        departmentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        departmentLabel.textColor = .white
        departmentLabel.textAlignment = .right
        departmentLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(departmentLabel)
        
        NSLayoutConstraint.activate([
            doctorNameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            doctorNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doctorNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            
            departmentLabel.topAnchor.constraint(equalTo: doctorNameLabel.bottomAnchor, constant: 4),
            departmentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            departmentLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16)
        ])
        
        return view
    }
    
    // MARK: - Create Patient Info View
    private func createPatientInfoView(details: AppointmentDetailsResponse) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let patientIdLabel = UILabel()
        patientIdLabel.text = "Patient ID : \(details.patientCode)"
        patientIdLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        patientIdLabel.textColor = .white
        patientIdLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(patientIdLabel)
        
        let patientNameLabel = UILabel()
        patientNameLabel.text = details.patientName
        patientNameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        patientNameLabel.textColor = .white
        patientNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(patientNameLabel)
        
        let dateLabel = UILabel()
        dateLabel.text = "\(details.formattedDate) \(details.formattedTime)"
        dateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .white
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            patientIdLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            patientIdLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            dateLabel.centerYAnchor.constraint(equalTo: patientIdLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: patientIdLabel.trailingAnchor, constant: 8),
            
            patientNameLabel.topAnchor.constraint(equalTo: patientIdLabel.bottomAnchor, constant: 4),
            patientNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            patientNameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
        
        return view
    }
    
    // MARK: - Create Vitals View
    private func createVitalsView(vitals: [Vittal]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Vitals"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        ])
        
        var lastLabel: UILabel = titleLabel
        
        for (index, vital) in vitals.enumerated() {
            let vitalLabel = UILabel()
            vitalLabel.text = "\(vital.vittalQuestion)                    \(vital.displayText)"
            vitalLabel.font = .systemFont(ofSize: 14, weight: .regular)
            vitalLabel.textColor = .white
            vitalLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(vitalLabel)
            
            NSLayoutConstraint.activate([
                vitalLabel.topAnchor.constraint(equalTo: lastLabel.bottomAnchor, constant: 8),
                vitalLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                vitalLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            ])
            
            lastLabel = vitalLabel
            
            if index == vitals.count - 1 {
                NSLayoutConstraint.activate([
                    lastLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
                ])
            }
        }
        
        return containerView
    }
    
    // MARK: - Create Symptoms View
    private func createSymptomsView(symptoms: [SymptomQuestion]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Symptoms"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        ])
        
        var lastView: UIView = titleLabel
        
        for (index, symptom) in symptoms.enumerated() {
            let symptomView = UIView()
            symptomView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(symptomView)
            
            let questionLabel = UILabel()
            questionLabel.text = symptom.diseaseQuestion
            questionLabel.font = .systemFont(ofSize: 14, weight: .regular)
            questionLabel.textColor = .white
            questionLabel.numberOfLines = 0
            questionLabel.translatesAutoresizingMaskIntoConstraints = false
            symptomView.addSubview(questionLabel)
            
            let answerLabel = UILabel()
            answerLabel.text = " Yes "
            answerLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            answerLabel.textColor = .white
            answerLabel.backgroundColor = UIColor.systemGreen
            answerLabel.layer.cornerRadius = 4
            answerLabel.clipsToBounds = true
            answerLabel.textAlignment = .center
            answerLabel.translatesAutoresizingMaskIntoConstraints = false
            symptomView.addSubview(answerLabel)
            
            NSLayoutConstraint.activate([
                symptomView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 8),
                symptomView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                symptomView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:-16),
                
                questionLabel.topAnchor.constraint(equalTo: symptomView.topAnchor),
                questionLabel.leadingAnchor.constraint(equalTo: symptomView.leadingAnchor),
                questionLabel.trailingAnchor.constraint(equalTo: answerLabel.leadingAnchor, constant: -8),
                questionLabel.bottomAnchor.constraint(equalTo: symptomView.bottomAnchor),
                
                answerLabel.centerYAnchor.constraint(equalTo: questionLabel.centerYAnchor),
                answerLabel.trailingAnchor.constraint(equalTo: symptomView.trailingAnchor),
                answerLabel.widthAnchor.constraint(equalToConstant: 40),
                answerLabel.heightAnchor.constraint(equalToConstant: 22)
            ])
            
            lastView = symptomView
            
            if index == symptoms.count - 1 {
                NSLayoutConstraint.activate([
                    lastView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
                ])
            }
        }
        
        return containerView
    }
    
    // MARK: - Create Diagnosis View
    private func createDiagnosisView(diagnosis: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Diagnosis"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let diagnosisLabel = UILabel()
        diagnosisLabel.text = diagnosis
        diagnosisLabel.font = .systemFont(ofSize: 14, weight: .regular)
        diagnosisLabel.textColor = .white
        diagnosisLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(diagnosisLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            diagnosisLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            diagnosisLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            diagnosisLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        return view
    }
    
    // MARK: - Create Prescriptions View
    private func createPrescriptionsView(prescriptions: [Prescription]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header row
        let headerRow = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerRow)
        
        let titleLabel = UILabel()
        titleLabel.text = "Medicine as per prescription"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(titleLabel)
        
        let toggleSwitch = UISwitch()
        toggleSwitch.isOn = true
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(toggleSwitch)
        
        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            headerRow.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            headerRow.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            
            toggleSwitch.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor),
            toggleSwitch.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor)
        ])
        
        // Table header
        let tableHeaderView = UIView()
        tableHeaderView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tableHeaderView)
        
        let medicineHeader = UILabel()
        medicineHeader.text = "Medicine Name"
        medicineHeader.font = .systemFont(ofSize: 13, weight: .semibold)
        medicineHeader.textColor = .white
        medicineHeader.translatesAutoresizingMaskIntoConstraints = false
        tableHeaderView.addSubview(medicineHeader)
        
        let dosageHeader = UILabel()
        dosageHeader.text = "Dosage"
        dosageHeader.font = .systemFont(ofSize: 13, weight: .semibold)
        dosageHeader.textColor = .white
        dosageHeader.textAlignment = .center
        dosageHeader.translatesAutoresizingMaskIntoConstraints = false
        tableHeaderView.addSubview(dosageHeader)
        
        let durationHeader = UILabel()
        durationHeader.text = "Duration"
        durationHeader.font = .systemFont(ofSize: 13, weight: .semibold)
        durationHeader.textColor = .white
        durationHeader.textAlignment = .center
        durationHeader.translatesAutoresizingMaskIntoConstraints = false
        tableHeaderView.addSubview(durationHeader)
        
        NSLayoutConstraint.activate([
            tableHeaderView.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 8),
            tableHeaderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tableHeaderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tableHeaderView.heightAnchor.constraint(equalToConstant: 35),
            
            medicineHeader.leadingAnchor.constraint(equalTo: tableHeaderView.leadingAnchor, constant: 8),
            medicineHeader.centerYAnchor.constraint(equalTo: tableHeaderView.centerYAnchor),
            medicineHeader.widthAnchor.constraint(equalTo: tableHeaderView.widthAnchor, multiplier: 0.4),
            
            dosageHeader.leadingAnchor.constraint(equalTo: medicineHeader.trailingAnchor),
            dosageHeader.centerYAnchor.constraint(equalTo: tableHeaderView.centerYAnchor),
            dosageHeader.widthAnchor.constraint(equalTo: tableHeaderView.widthAnchor, multiplier: 0.3),
            
            durationHeader.leadingAnchor.constraint(equalTo: dosageHeader.trailingAnchor),
            durationHeader.centerYAnchor.constraint(equalTo: tableHeaderView.centerYAnchor),
            durationHeader.trailingAnchor.constraint(equalTo: tableHeaderView.trailingAnchor, constant: -8)
        ])
        
        var lastView: UIView = tableHeaderView
        
        // Prescription rows
        for (index, prescription) in prescriptions.enumerated() {
            let rowView = UIView()
           rowView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(rowView)
            
            let medicineLabel = UILabel()
            medicineLabel.text = prescription.medicine
            medicineLabel.font = .systemFont(ofSize: 13, weight: .regular)
            medicineLabel.textColor = .white
            medicineLabel.numberOfLines = 0
            medicineLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(medicineLabel)
            
            let dosageLabel = UILabel()
            dosageLabel.text = prescription.notes ?? "-"
            dosageLabel.font = .systemFont(ofSize: 13, weight: .regular)
            dosageLabel.textColor = .white
            dosageLabel.textAlignment = .center
            dosageLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(dosageLabel)
            
            let durationLabel = UILabel()
            durationLabel.text = prescription.duration ?? "-"
            durationLabel.font = .systemFont(ofSize: 13, weight: .regular)
            durationLabel.textColor = .white
            durationLabel.textAlignment = .center
            durationLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(durationLabel)
            
            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 1),
                rowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                rowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                rowView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
                
                medicineLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 8),
                medicineLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                medicineLabel.widthAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: 0.4),
                
                dosageLabel.leadingAnchor.constraint(equalTo: medicineLabel.trailingAnchor),
                dosageLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                dosageLabel.widthAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: 0.3),
                
                durationLabel.leadingAnchor.constraint(equalTo: dosageLabel.trailingAnchor),
                durationLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                durationLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -8)
            ])
            
            lastView = rowView
            
            if index == prescriptions.count - 1 {
                NSLayoutConstraint.activate([
                    lastView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
                ])
            }
        }
        
        return containerView
    }
    
    // MARK: - Create Remarks View
    private func createRemarksView(remarks: String?) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Remarks"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let remarksLabel = UILabel()
        remarksLabel.text = remarks ?? "-"
        remarksLabel.font = .systemFont(ofSize: 14, weight: .regular)
        remarksLabel.textColor = .white
        remarksLabel.numberOfLines = 0
        remarksLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(remarksLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            remarksLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            remarksLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            remarksLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            remarksLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        return view
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

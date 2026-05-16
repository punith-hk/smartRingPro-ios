import UIKit

class AppointmentDetailsViewController: AppBaseViewController {
    
    // MARK: - Properties
    private let TAG = "AppointmentDetailsViewController"
    private let appointment: PatientAppointment
    private var appointmentDetails: AppointmentDetailsResponse?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
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
        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // MARK: - API Call
    private func fetchAppointmentDetails() {
        Loader.shared.show(on: view, message: "Fetching Details...", timeout: 5)
        
        AppointmentService.shared.getAppointmentDetails(appointmentId: appointment.apptId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                Loader.shared.hide()
                
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
        contentView.subviews.forEach { $0.removeFromSuperview() }

        var lastView: UIView?

        func addCard(_ card: UIView, topInset: CGFloat = 12) {
            contentView.addSubview(card)
            let topAnchor = lastView.map { card.topAnchor.constraint(equalTo: $0.bottomAnchor, constant: topInset) }
                ?? card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topInset)
            NSLayoutConstraint.activate([
                topAnchor,
                card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            lastView = card
        }

        // 1. Header Card (logo + doctor + divider + patient + date)
        addCard(createHeaderCard(details: details), topInset: 16)

        // 2. Vitals Card
        if !details.uniqueVitals.isEmpty {
            addCard(createVitalsCard(vitals: details.uniqueVitals))
        }

        // 3. Symptoms Card — uses purpose field (comma-separated)
        let purposeText = details.purpose
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        if !purposeText.isEmpty {
            addCard(createTextCard(title: "Symptoms", text: purposeText))
        }

        // 4. Diagnosis Card — uses disease_name field (comma-separated)
        if let rawDiagnosis = details.diseaseName, !rawDiagnosis.isEmpty {
            let diagText = rawDiagnosis
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            addCard(createTextCard(title: "Diagnosis", text: diagText))
        }

        // 5. Medicine Card
        if !details.prescriptions.isEmpty {
            addCard(createPrescriptionsCard(prescriptions: details.prescriptions))
        }

        // 6. Remarks Card
        if let remarks = details.remarks, !remarks.trimmingCharacters(in: .whitespaces).isEmpty {
            addCard(createTextCard(title: "Remarks", text: remarks))
        }

        // 7. Download & Share buttons
        let buttonsView = createDownloadShareButtons()
        contentView.addSubview(buttonsView)
        NSLayoutConstraint.activate([
            buttonsView.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: 20),
            buttonsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Card Factory

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 6
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    // MARK: - Header Card (logo + doctor + divider + patient + date)

    private func createHeaderCard(details: AppointmentDetailsResponse) -> UIView {
        let card = makeCard()
        let navBlue = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)

        // Logo background (navBlue rounded square)
        let logoBg = UIView()
        logoBg.backgroundColor = navBlue
        logoBg.layer.cornerRadius = 10
        logoBg.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(logoBg)

        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "launch_logo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoBg.addSubview(logoImageView)

        // Doctor name + department
        let doctorNameLabel = UILabel()
        doctorNameLabel.text = details.doctorName
        doctorNameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        doctorNameLabel.textColor = .black
        doctorNameLabel.numberOfLines = 2
        doctorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(doctorNameLabel)

        let departmentLabel = UILabel()
        departmentLabel.text = details.doctorDepartment
        departmentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        departmentLabel.textColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
        departmentLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(departmentLabel)

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.88, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(divider)

        // Patient name + ID (left)
        let patientNameLabel = UILabel()
        patientNameLabel.text = details.patientName
        patientNameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        patientNameLabel.textColor = .black
        patientNameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(patientNameLabel)

        let patientIdLabel = UILabel()
        patientIdLabel.text = "Patient ID : \(details.patientCode)"
        patientIdLabel.font = .systemFont(ofSize: 13, weight: .regular)
        patientIdLabel.textColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
        patientIdLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(patientIdLabel)

        // Date (right top) + time (right bottom)
        let dateLabel = UILabel()
        dateLabel.text = details.formattedDate
        dateLabel.font = .systemFont(ofSize: 13, weight: .bold)
        dateLabel.textColor = .black
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(dateLabel)

        let timeLabel = UILabel()
        timeLabel.text = details.formattedTime
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
        timeLabel.textAlignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            // Logo bg: 64×64, top-left
            logoBg.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            logoBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            logoBg.widthAnchor.constraint(equalToConstant: 64),
            logoBg.heightAnchor.constraint(equalToConstant: 64),

            // Logo image: 8pt inset inside logoBg
            logoImageView.topAnchor.constraint(equalTo: logoBg.topAnchor, constant: 8),
            logoImageView.leadingAnchor.constraint(equalTo: logoBg.leadingAnchor, constant: 8),
            logoImageView.trailingAnchor.constraint(equalTo: logoBg.trailingAnchor, constant: -8),
            logoImageView.bottomAnchor.constraint(equalTo: logoBg.bottomAnchor, constant: -8),

            // Doctor name: right of logoBg
            doctorNameLabel.topAnchor.constraint(equalTo: logoBg.topAnchor),
            doctorNameLabel.leadingAnchor.constraint(equalTo: logoBg.trailingAnchor, constant: 12),
            doctorNameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            departmentLabel.topAnchor.constraint(equalTo: doctorNameLabel.bottomAnchor, constant: 4),
            departmentLabel.leadingAnchor.constraint(equalTo: logoBg.trailingAnchor, constant: 12),
            departmentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            // Divider: below logoBg with 12pt gap
            divider.topAnchor.constraint(equalTo: logoBg.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 1),

            // Patient name + ID (left side below divider)
            patientNameLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            patientNameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            patientNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: dateLabel.leadingAnchor, constant: -8),

            patientIdLabel.topAnchor.constraint(equalTo: patientNameLabel.bottomAnchor, constant: 4),
            patientIdLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            patientIdLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            patientIdLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            // Date + time (right side below divider)
            dateLabel.topAnchor.constraint(equalTo: patientNameLabel.topAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])

        return card
    }

    // MARK: - Vitals Card

    private func createVitalsCard(vitals: [Vittal]) -> UIView {
        let card = makeCard()

        let titleLabel = UILabel()
        titleLabel.text = "Vitals"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])

        var lastView: UIView = titleLabel

        for (index, vital) in vitals.enumerated() {
            let rowView = UIView()
            rowView.backgroundColor = index % 2 == 0 ? UIColor(white: 0.97, alpha: 1) : .white
            rowView.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(rowView)

            let questionLabel = UILabel()
            questionLabel.text = vital.vittalQuestion
            questionLabel.font = .systemFont(ofSize: 13, weight: .regular)
            questionLabel.textColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1)
            questionLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(questionLabel)

            let valueLabel = UILabel()
            valueLabel.text = vital.displayText
            valueLabel.font = .systemFont(ofSize: 13, weight: .bold)
            valueLabel.textColor = .black
            valueLabel.textAlignment = .right
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(valueLabel)

            let topGap: CGFloat = (index == 0) ? 8 : 0
            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: topGap),
                rowView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: card.trailingAnchor),

                questionLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 10),
                questionLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                questionLabel.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -10),
                questionLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -8),

                valueLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
                valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            ])

            lastView = rowView
        }

        NSLayoutConstraint.activate([
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])

        return card
    }

    // MARK: - Generic Text Card (Symptoms / Diagnosis / Remarks)

    private func createTextCard(title: String, text: String) -> UIView {
        let card = makeCard()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let bodyLabel = UILabel()
        bodyLabel.text = text
        bodyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        return card
    }

    // MARK: - Prescriptions Card

    private func createPrescriptionsCard(prescriptions: [Prescription]) -> UIView {
        let card = makeCard()

        let titleLabel = UILabel()
        titleLabel.text = "Medicine"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // Table header row
        let headerRow = UIView()
        headerRow.backgroundColor = UIColor(white: 0.94, alpha: 1)
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(headerRow)

        let makeHeaderLabel: (String) -> UILabel = { text in
            let l = UILabel()
            l.text = text
            l.font = .systemFont(ofSize: 13, weight: .semibold)
            l.textColor = .black
            l.translatesAutoresizingMaskIntoConstraints = false
            return l
        }

        let medicineHeader = makeHeaderLabel("Medicine")
        let dosageHeader   = makeHeaderLabel("Dosage")
        let durationHeader = makeHeaderLabel("Duration")
        dosageHeader.textAlignment  = .center
        durationHeader.textAlignment = .right

        [medicineHeader, dosageHeader, durationHeader].forEach { headerRow.addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            headerRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            headerRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            headerRow.heightAnchor.constraint(equalToConstant: 36),

            medicineHeader.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor, constant: 16),
            medicineHeader.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            medicineHeader.widthAnchor.constraint(equalTo: headerRow.widthAnchor, multiplier: 0.42),

            dosageHeader.leadingAnchor.constraint(equalTo: medicineHeader.trailingAnchor),
            dosageHeader.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            dosageHeader.widthAnchor.constraint(equalTo: headerRow.widthAnchor, multiplier: 0.30),

            durationHeader.leadingAnchor.constraint(equalTo: dosageHeader.trailingAnchor),
            durationHeader.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            durationHeader.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor, constant: -16),
        ])

        var lastView: UIView = headerRow

        for (index, prescription) in prescriptions.enumerated() {
            let rowView = UIView()
            rowView.backgroundColor = index % 2 == 0 ? .white : UIColor(white: 0.97, alpha: 1)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(rowView)

            let makeRowLabel: (String?, NSTextAlignment) -> UILabel = { text, alignment in
                let l = UILabel()
                l.text = text ?? "-"
                l.font = .systemFont(ofSize: 13, weight: .regular)
                l.textColor = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
                l.textAlignment = alignment
                l.numberOfLines = 0
                l.translatesAutoresizingMaskIntoConstraints = false
                return l
            }

            let medicineLabel  = makeRowLabel(prescription.medicine, .left)
            let dosageLabel    = makeRowLabel(prescription.notes, .center)
            let durationLabel  = makeRowLabel(prescription.duration, .right)

            [medicineLabel, dosageLabel, durationLabel].forEach { rowView.addSubview($0) }

            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                rowView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: card.trailingAnchor),

                medicineLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 8),
                medicineLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                medicineLabel.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -8),
                medicineLabel.widthAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: 0.42),

                dosageLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 8),
                dosageLabel.leadingAnchor.constraint(equalTo: medicineLabel.trailingAnchor),
                dosageLabel.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -8),
                dosageLabel.widthAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: 0.30),

                durationLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 8),
                durationLabel.leadingAnchor.constraint(equalTo: dosageLabel.trailingAnchor),
                durationLabel.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -8),
                durationLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
            ])

            lastView = rowView
        }

        NSLayoutConstraint.activate([
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])

        return card
    }

    // MARK: - Download & Share Buttons

    private func createDownloadShareButtons() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let navBlue = UIColor(red: 21/255, green: 85/255, blue: 141/255, alpha: 1)

        let downloadButton = UIButton(type: .system)
        downloadButton.setTitle("Download", for: .normal)
        downloadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.backgroundColor = navBlue
        downloadButton.layer.cornerRadius = 12
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        container.addSubview(downloadButton)

        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        shareButton.setTitleColor(navBlue, for: .normal)
        shareButton.backgroundColor = .white
        shareButton.layer.cornerRadius = 12
        shareButton.layer.borderWidth = 1.5
        shareButton.layer.borderColor = navBlue.cgColor
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        container.addSubview(shareButton)

        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: container.topAnchor),
            downloadButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: container.centerXAnchor, constant: -6),
            downloadButton.heightAnchor.constraint(equalToConstant: 50),
            downloadButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            shareButton.topAnchor.constraint(equalTo: container.topAnchor),
            shareButton.leadingAnchor.constraint(equalTo: container.centerXAnchor, constant: 6),
            shareButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            shareButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    @objc private func downloadTapped() {
        showInfoToast("Download — coming soon")
    }

    @objc private func shareTapped() {
        showInfoToast("Share — coming soon")
    }

    private func showInfoToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { alert.dismiss(animated: true) }
    }

    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

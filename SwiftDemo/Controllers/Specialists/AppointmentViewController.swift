import UIKit

/// Appointment booking screen with date/time selection
final class AppointmentViewController: AppBaseViewController {
    
    // MARK: - Properties
    private let doctor: Doctor
    private let selectedSymptoms: [String: [String]] // bodyPart: [symptoms]
    
    // Data
    private var allDateSchedules: [DateSchedule] = []
    private var currentPageIndex = 0
    private var timeSlotMapping: [Int: (time12: String, time24: String)] = [:]
    private var selectedSlot: (date: String, slotId: Int, time24Hour: String)?
    private var hasScrolledToButton = false
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Doctor Info Card
    private let doctorCardView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let qualificationLabel = UILabel()
    private let specializationLabel = UILabel()
    
    // Symptoms Card
    private let symptomsCardView = UIView()
    private let symptomsHeaderLabel = UILabel()
    private let symptomsContentLabel = UILabel()
    private let editButton = UIButton(type: .system)
    
    // Date & Time Section
    private let dateTimeLabel = UILabel()
    private let dateTimeContainer = UIView()
    private let monthYearLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let datesStackView = UIStackView()
    
    // Make Appointment Button
    private let makeAppointmentButton = UIButton(type: .system)
    
    // Loading
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    
    private let TAG = "AppointmentViewController"
    
    // MARK: - Init
    init(doctor: Doctor, selectedSymptoms: [String: [String]]) {
        self.doctor = doctor
        self.selectedSymptoms = selectedSymptoms
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("Book an Appointment")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        // Generate time slot mapping
        timeSlotMapping = AppointmentHelper.getTimeSlotMapping()
        
        setupScrollView()
        setupDoctorCard()
        setupSymptomsCard()
        setupDateTimeSection()
        setupMakeAppointmentButton()
        setupLoadingView()
        
        configureDoctorInfo()
        configureSymptomsInfo()
        
        // Initially disable button
        makeAppointmentButton.isEnabled = false
        makeAppointmentButton.alpha = 0.5
        
        // Fetch appointment data
        fetchAppointmentData()
        
        print("[\(TAG)] 📅 Loaded appointment screen for doctor: \(doctor.displayName)")
        print("[\(TAG)] 📋 Symptoms: \(selectedSymptoms)")
    }
    
    // MARK: - Setup UI
    private func setupScrollView() {
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
    
    private func setupDoctorCard() {
        // Card View
        doctorCardView.backgroundColor = .white
        doctorCardView.layer.cornerRadius = 16
        doctorCardView.layer.shadowColor = UIColor.black.cgColor
        doctorCardView.layer.shadowOpacity = 0.1
        doctorCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        doctorCardView.layer.shadowRadius = 8
        doctorCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(doctorCardView)
        
        // Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        doctorCardView.addSubview(profileImageView)
        
        // Name Label
        nameLabel.font = .boldSystemFont(ofSize: 18)
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        doctorCardView.addSubview(nameLabel)
        
        // Qualification Label
        qualificationLabel.font = .systemFont(ofSize: 14)
        qualificationLabel.textColor = .darkGray
        qualificationLabel.numberOfLines = 1
        qualificationLabel.translatesAutoresizingMaskIntoConstraints = false
        doctorCardView.addSubview(qualificationLabel)
        
        // Specialization Label
        specializationLabel.font = .systemFont(ofSize: 13, weight: .medium)
        specializationLabel.textColor = .gray
        specializationLabel.numberOfLines = 1
        specializationLabel.translatesAutoresizingMaskIntoConstraints = false
        doctorCardView.addSubview(specializationLabel)
        
        NSLayoutConstraint.activate([
            // Card
            doctorCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            doctorCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            doctorCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            doctorCardView.heightAnchor.constraint(equalToConstant: 90),
            
            // Profile Image
            profileImageView.leadingAnchor.constraint(equalTo: doctorCardView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: doctorCardView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: doctorCardView.topAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: doctorCardView.trailingAnchor, constant: -12),
            
            // Qualification
            qualificationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            qualificationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            qualificationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Specialization
            specializationLabel.topAnchor.constraint(equalTo: qualificationLabel.bottomAnchor, constant: 3),
            specializationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            specializationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ])
    }
    
    private func setupSymptomsCard() {
        // Card View
        symptomsCardView.backgroundColor = .white
        symptomsCardView.layer.cornerRadius = 16
        symptomsCardView.layer.shadowColor = UIColor.black.cgColor
        symptomsCardView.layer.shadowOpacity = 0.1
        symptomsCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        symptomsCardView.layer.shadowRadius = 8
        symptomsCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(symptomsCardView)
        
        // Header Label
        symptomsHeaderLabel.text = "Symptoms"
        symptomsHeaderLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        symptomsHeaderLabel.textColor = .black
        symptomsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        symptomsCardView.addSubview(symptomsHeaderLabel)
        
        // Edit Button (pencil icon)
        editButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        editButton.tintColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1) // Blue color
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editSymptomsTapped), for: .touchUpInside)
        symptomsCardView.addSubview(editButton)
        
        // Content Label
        symptomsContentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        symptomsContentLabel.textColor = .darkGray
        symptomsContentLabel.numberOfLines = 0
        symptomsContentLabel.translatesAutoresizingMaskIntoConstraints = false
        symptomsCardView.addSubview(symptomsContentLabel)
        
        NSLayoutConstraint.activate([
            symptomsCardView.topAnchor.constraint(equalTo: doctorCardView.bottomAnchor, constant: 16),
            symptomsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            symptomsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            symptomsHeaderLabel.topAnchor.constraint(equalTo: symptomsCardView.topAnchor, constant: 16),
            symptomsHeaderLabel.leadingAnchor.constraint(equalTo: symptomsCardView.leadingAnchor, constant: 16),
            
            editButton.centerYAnchor.constraint(equalTo: symptomsHeaderLabel.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: symptomsCardView.trailingAnchor, constant: -16),
            editButton.widthAnchor.constraint(equalToConstant: 30),
            editButton.heightAnchor.constraint(equalToConstant: 30),
            
            symptomsContentLabel.topAnchor.constraint(equalTo: symptomsHeaderLabel.bottomAnchor, constant: 12),
            symptomsContentLabel.leadingAnchor.constraint(equalTo: symptomsCardView.leadingAnchor, constant: 16),
            symptomsContentLabel.trailingAnchor.constraint(equalTo: symptomsCardView.trailingAnchor, constant: -16),
            symptomsContentLabel.bottomAnchor.constraint(equalTo: symptomsCardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupDateTimeSection() {
        // Header label
        dateTimeLabel.text = "Choose your preferred Date & Time"
        dateTimeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        dateTimeLabel.textColor = .white
        dateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateTimeLabel)
        
        // Container for date/time UI
        dateTimeContainer.backgroundColor = .white
        dateTimeContainer.layer.cornerRadius = 16
        dateTimeContainer.layer.shadowColor = UIColor.black.cgColor
        dateTimeContainer.layer.shadowOpacity = 0.1
        dateTimeContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        dateTimeContainer.layer.shadowRadius = 8
        dateTimeContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateTimeContainer)
        
        // Month/Year label
        monthYearLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        monthYearLabel.textColor = .black
        monthYearLabel.textAlignment = .center
        monthYearLabel.translatesAutoresizingMaskIntoConstraints = false
        dateTimeContainer.addSubview(monthYearLabel)
        
        // Prev button
        prevButton.setTitle("Prev", for: .normal)
        prevButton.setTitleColor(.white, for: .normal)
        prevButton.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        prevButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        prevButton.layer.cornerRadius = 8
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.addTarget(self, action: #selector(prevButtonTapped), for: .touchUpInside)
        dateTimeContainer.addSubview(prevButton)
        
        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        nextButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        nextButton.layer.cornerRadius = 8
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        dateTimeContainer.addSubview(nextButton)
        
        // Dates stack view (will hold 3 date columns)
        datesStackView.axis = .horizontal
        datesStackView.distribution = .fillEqually
        datesStackView.spacing = 8
        datesStackView.translatesAutoresizingMaskIntoConstraints = false
        dateTimeContainer.addSubview(datesStackView)
        
        NSLayoutConstraint.activate([
            dateTimeLabel.topAnchor.constraint(equalTo: symptomsCardView.bottomAnchor, constant: 20),
            dateTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateTimeContainer.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 12),
            dateTimeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateTimeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateTimeContainer.heightAnchor.constraint(equalToConstant: 450),
            
            prevButton.topAnchor.constraint(equalTo: dateTimeContainer.topAnchor, constant: 16),
            prevButton.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            prevButton.widthAnchor.constraint(equalToConstant: 60),
            prevButton.heightAnchor.constraint(equalToConstant: 36),
            
            monthYearLabel.centerYAnchor.constraint(equalTo: prevButton.centerYAnchor),
            monthYearLabel.centerXAnchor.constraint(equalTo: dateTimeContainer.centerXAnchor),
            
            nextButton.topAnchor.constraint(equalTo: dateTimeContainer.topAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -16),
            nextButton.widthAnchor.constraint(equalToConstant: 60),
            nextButton.heightAnchor.constraint(equalToConstant: 36),
            
            datesStackView.topAnchor.constraint(equalTo: monthYearLabel.bottomAnchor, constant: 20),
            datesStackView.leadingAnchor.constraint(equalTo: dateTimeContainer.leadingAnchor, constant: 16),
            datesStackView.trailingAnchor.constraint(equalTo: dateTimeContainer.trailingAnchor, constant: -16),
            datesStackView.bottomAnchor.constraint(equalTo: dateTimeContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupLoadingView() {
        // Loading spinner
        loadingView.color = .white
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        loadingView.layer.cornerRadius = 16
        loadingView.hidesWhenStopped = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        // Loading label
        loadingLabel.text = "Loading Availability..."
        loadingLabel.textColor = .white
        loadingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 200),
            loadingView.heightAnchor.constraint(equalToConstant: 120),
            
            loadingLabel.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: -20),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 12),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -12)
        ])
    }
    
    private func setupMakeAppointmentButton() {
        makeAppointmentButton.setTitle("Make an Appointment", for: .normal)
        makeAppointmentButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        makeAppointmentButton.setTitleColor(.white, for: .normal)
        makeAppointmentButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        makeAppointmentButton.layer.cornerRadius = 12
        makeAppointmentButton.translatesAutoresizingMaskIntoConstraints = false
        makeAppointmentButton.addTarget(self, action: #selector(makeAppointmentTapped), for: .touchUpInside)
        
        // Initially disabled until user selects a time slot
        makeAppointmentButton.isEnabled = false
        makeAppointmentButton.alpha = 0.5
        
        contentView.addSubview(makeAppointmentButton)
        
        NSLayoutConstraint.activate([
            makeAppointmentButton.topAnchor.constraint(equalTo: dateTimeContainer.bottomAnchor, constant: 20),
            makeAppointmentButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            makeAppointmentButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            makeAppointmentButton.heightAnchor.constraint(equalToConstant: 50),
            
            contentView.bottomAnchor.constraint(equalTo: makeAppointmentButton.bottomAnchor, constant: 30)
        ])
    }
    
    // MARK: - Configure
    private func configureDoctorInfo() {
        nameLabel.text = doctor.displayName
        qualificationLabel.text = doctor.qualificationsText
        specializationLabel.text = doctor.specializationText
        
        // Load profile image
        if let imageURL = doctor.profileImageURL {
            profileImageView.loadImage(from: imageURL)
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .lightGray
        }
    }
    
    private func configureSymptomsInfo() {
        // Build symptoms text with bold body parts
        let attributedText = NSMutableAttributedString()
        let sortedSymptoms = selectedSymptoms.sorted(by: { $0.key < $1.key })
        
        for (index, item) in sortedSymptoms.enumerated() {
            let (bodyPart, symptoms) = item
            
            // Body part name in bold
            let bodyPartText = NSAttributedString(
                string: "\(bodyPart): ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor.darkGray
                ]
            )
            
            // Symptoms in regular font
            let symptomsText = NSAttributedString(
                string: symptoms.joined(separator: ", "),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]
            )
            
            attributedText.append(bodyPartText)
            attributedText.append(symptomsText)
            
            // Add newline if not the last item
            if index < sortedSymptoms.count - 1 {
                attributedText.append(NSAttributedString(string: "\n"))
            }
        }
        
        symptomsContentLabel.attributedText = attributedText
    }
    
    // MARK: - Actions
    @objc private func editSymptomsTapped() {
        print("[\(TAG)] ✏️ Edit symptoms tapped - going back")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func makeAppointmentTapped() {
        print("[\(TAG)] 📅 Make appointment tapped")
        
        guard let selectedSlot = selectedSlot else {
            showErrorAlert(message: "Please select a date and time slot.")
            return
        }
        
        let patientId = UserDefaultsManager.shared.userId
        guard patientId > 0 else {
            showErrorAlert(message: "User information not found. Please login again.")
            return
        }
        
        // Prepare purpose (comma-separated symptoms)
        var allSymptoms: [String] = []
        for (_, symptoms) in selectedSymptoms {
            allSymptoms.append(contentsOf: symptoms)
        }
        let purposeString = allSymptoms.joined(separator: ", ")
        
        // Prepare symptom JSON for symptoms API
        guard let symptomJsonData = try? JSONSerialization.data(withJSONObject: selectedSymptoms, options: []),
              let symptomJsonString = String(data: symptomJsonData, encoding: .utf8) else {
            showErrorAlert(message: "Failed to prepare symptoms data.")
            return
        }
        
        // Prepare appt_time (date + time combined)
        let apptTime = "\(selectedSlot.date) \(selectedSlot.time24Hour)"
        
        print("[\(TAG)] 📤 Booking appointment:")
        print("  Date: \(selectedSlot.date)")
        print("  Time: \(selectedSlot.time24Hour)")
        print("  Doctor: \(doctor.id)")
        print("  Patient: \(patientId)")
        print("  Purpose: \(purposeString)")
        
        // Show loading
        loadingLabel.text = "Booking Appointment..."
        loadingView.startAnimating()
        
        // Step 1: Book appointment
        AppointmentService.shared.bookAppointment(
            appointmentDate: selectedSlot.date,
            appointmentTime: selectedSlot.time24Hour,
            doctorId: doctor.id,
            patientId: patientId,
            purpose: purposeString,
            status: 1,
            dependentId: 0,
            type: 2
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("[\(self.TAG)] ✅ Appointment booked: \(response.message)")
                
                // Step 2: Submit symptoms
                AppointmentService.shared.submitSymptoms(
                    patientId: patientId,
                    dependentId: 0,
                    apptTime: apptTime,
                    symptomJson: symptomJsonString
                ) { [weak self] symptomResult in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.loadingView.stopAnimating()
                        
                        switch symptomResult {
                        case .success(let symptomResponse):
                            print("[\(self.TAG)] ✅ Symptoms submitted: \(symptomResponse.message)")
                            self.showSuccessModal(appointmentDate: selectedSlot.date, appointmentTime: selectedSlot.time24Hour)
                            
                        case .failure(let error):
                            print("[\(self.TAG)] ⚠️ Symptoms submission failed: \(error)")
                            // Still show success since appointment was booked
                            self.showSuccessModal(appointmentDate: selectedSlot.date, appointmentTime: selectedSlot.time24Hour)
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loadingView.stopAnimating()
                    print("[\(self.TAG)] ❌ Booking failed: \(error)")
                    self.showErrorAlert(message: "Failed to book appointment. Please try again.")
                }
            }
        }
    }
    
    private func showSuccessModal(appointmentDate: String, appointmentTime: String) {
        // Convert date format for display (yyyy-MM-dd to readable format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let appointmentDateTime = "\(appointmentDate) \(appointmentTime)"
        
        // Create custom modal
        let modalView = UIView()
        modalView.backgroundColor = .white
        modalView.layer.cornerRadius = 20
        modalView.translatesAutoresizingMaskIntoConstraints = false
        
        // Background overlay
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        view.addSubview(modalView)
        
        // Checkmark icon (using system image)
        let checkmarkView = UIView()
        checkmarkView.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        checkmarkView.layer.cornerRadius = 50
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        modalView.addSubview(checkmarkView)
        
        let checkmark = UIImageView()
        checkmark.image = UIImage(systemName: "checkmark")
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.addSubview(checkmark)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Appointment Booked Successfully !"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .darkGray
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        modalView.addSubview(titleLabel)
        
        // Message
        let messageLabel = UILabel()
        messageLabel.text = "Appointment Booked with Dr \(doctor.displayName) on \(appointmentDateTime)"
        messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .gray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        modalView.addSubview(messageLabel)
        
        // Book another appointment button
        let bookAnotherButton = UIButton(type: .system)
        bookAnotherButton.setTitle("Book another appointment", for: .normal)
        bookAnotherButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        bookAnotherButton.setTitleColor(.white, for: .normal)
        bookAnotherButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        bookAnotherButton.layer.cornerRadius = 10
        bookAnotherButton.translatesAutoresizingMaskIntoConstraints = false
        bookAnotherButton.addTarget(self, action: #selector(bookAnotherTapped), for: .touchUpInside)
        modalView.addSubview(bookAnotherButton)
        
        // Patient dashboard button
        let dashboardButton = UIButton(type: .system)
        dashboardButton.setTitle("Patient dashboard", for: .normal)
        dashboardButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        dashboardButton.setTitleColor(.white, for: .normal)
        dashboardButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        dashboardButton.layer.cornerRadius = 10
        dashboardButton.translatesAutoresizingMaskIntoConstraints = false
        dashboardButton.addTarget(self, action: #selector(goToDashboardTapped), for: .touchUpInside)
        modalView.addSubview(dashboardButton)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            modalView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modalView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            checkmarkView.topAnchor.constraint(equalTo: modalView.topAnchor, constant: 30),
            checkmarkView.centerXAnchor.constraint(equalTo: modalView.centerXAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 100),
            checkmarkView.heightAnchor.constraint(equalToConstant: 100),
            
            checkmark.centerXAnchor.constraint(equalTo: checkmarkView.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: checkmarkView.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 60),
            checkmark.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: checkmarkView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -20),
            
            bookAnotherButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            bookAnotherButton.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 20),
            bookAnotherButton.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -20),
            bookAnotherButton.heightAnchor.constraint(equalToConstant: 44),
            
            dashboardButton.topAnchor.constraint(equalTo: bookAnotherButton.bottomAnchor, constant: 12),
            dashboardButton.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 20),
            dashboardButton.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -20),
            dashboardButton.heightAnchor.constraint(equalToConstant: 44),
            dashboardButton.bottomAnchor.constraint(equalTo: modalView.bottomAnchor, constant: -24)
        ])
    }
    
    @objc private func bookAnotherTapped() {
        print("[\(TAG)] 🔄 Book another appointment tapped")
        // Pop to specialists list
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func goToDashboardTapped() {
        print("[\(TAG)] 🏠 Go to dashboard tapped")
        // Dismiss to root (home)
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - Data Fetching
    private func fetchAppointmentData() {
        print("[\(TAG)] 🔄 Fetching appointment data for doctor: \(doctor.id)")
        
        // Show loading
        loadingView.startAnimating()
        
        let dispatchGroup = DispatchGroup()
        var scheduleData: ScheduleResponse?
        var appointmentsData: DoctorAppointmentsResponse?
        var fetchError: String?
        
        // Fetch doctor schedules
        dispatchGroup.enter()
        AppointmentService.shared.getDoctorSchedules(doctorId: doctor.id) { result in
            switch result {
            case .success(let response):
                scheduleData = response
                print("[\(self.TAG)] ✅ Schedules fetched: \(response.data.count) days")
            case .failure(let error):
                fetchError = error.localizedDescription
                print("[\(self.TAG)] ❌ Failed to fetch schedules: \(error)")
            }
            dispatchGroup.leave()
        }
        
        // Fetch doctor appointments
        dispatchGroup.enter()
        AppointmentService.shared.getDoctorAppointments(doctorId: doctor.id) { result in
            switch result {
            case .success(let response):
                appointmentsData = response
                print("[\(self.TAG)] ✅ Appointments fetched: \(response.data.count) bookings")
            case .failure(let error):
                fetchError = error.localizedDescription
                print("[\(self.TAG)] ❌ Failed to fetch appointments: \(error)")
            }
            dispatchGroup.leave()
        }
        
        // Process data once both APIs complete
        dispatchGroup.notify(queue: .main) {
            self.loadingView.stopAnimating()
            
            if let error = fetchError {
                print("[\(self.TAG)] ❌ Error loading appointment data: \(error)")
                self.showErrorAlert(message: "Failed to load availability. Please try again.")
                return
            }
            
            guard let schedules = scheduleData, let appointments = appointmentsData else {
                print("[\(self.TAG)] ❌ Missing data after fetch")
                self.showErrorAlert(message: "Unable to load appointment data.")
                return
            }
            
            // Generate 15 days of schedule data
            self.allDateSchedules = AppointmentHelper.generateNext15Days(
                weeklySchedules: schedules.data,
                leaves: schedules.leaves,
                appointments: appointments.data
            )
            
            print("[\(self.TAG)] 📅 Generated \(self.allDateSchedules.count) available days")
            
            if self.allDateSchedules.isEmpty {
                self.showErrorAlert(message: "No available slots for this doctor.")
                return
            }
            
            // Display first page
            self.currentPageIndex = 0
            self.displayCurrentPage()
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Display Methods
    private func displayCurrentPage() {
        // Clear existing date columns
        datesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Calculate page range (3 dates per page)
        let startIndex = currentPageIndex * 3
        let endIndex = min(startIndex + 3, allDateSchedules.count)
        let currentPageDates = Array(allDateSchedules[startIndex..<endIndex])
        
        print("[\(TAG)] 📄 Displaying page \(currentPageIndex + 1), dates: \(startIndex)..\(endIndex-1)")
        
        // Create date columns
        for dateSchedule in currentPageDates {
            let dateColumn = createDateColumn(for: dateSchedule)
            datesStackView.addArrangedSubview(dateColumn)
        }
        
        // Update month/year label (use first date of page)
        if let firstDate = currentPageDates.first {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            monthYearLabel.text = formatter.string(from: firstDate.date)
        }
        
        // Update navigation buttons
        prevButton.isHidden = (currentPageIndex == 0)
        let totalPages = (allDateSchedules.count + 2) / 3 // Ceiling division
        nextButton.isHidden = (currentPageIndex >= totalPages - 1)
    }
    
    private func createDateColumn(for dateSchedule: DateSchedule) -> UIView {
        let columnView = UIView()
        columnView.translatesAutoresizingMaskIntoConstraints = false
        
        // Date label (e.g., "15 Feb")
        let dateLabel = UILabel()
        dateLabel.text = dateSchedule.dateFormatted
        dateLabel.font = .systemFont(ofSize: 16, weight: .bold)
        dateLabel.textColor = .black
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        columnView.addSubview(dateLabel)
        
        // Day label (e.g., "Mon")
        let dayLabel = UILabel()
        dayLabel.text = dateSchedule.dayShort
        dayLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dayLabel.textColor = .gray
        dayLabel.textAlignment = .center
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        columnView.addSubview(dayLabel)
        
        // Scroll view for time slots
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        columnView.addSubview(scrollView)
        
        // Stack view for time slot buttons
        let slotsStackView = UIStackView()
        slotsStackView.axis = .vertical
        slotsStackView.spacing = 8
        slotsStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(slotsStackView)
        
        // Add time slot buttons
        for slot in dateSchedule.timeSlots {
            let slotButton = UIButton(type: .system)
            slotButton.setTitle(slot.time, for: .normal)
            slotButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            slotButton.layer.cornerRadius = 6
            slotButton.translatesAutoresizingMaskIntoConstraints = false
            
            // Set colors based on state
            switch slot.state {
            case .available:
                slotButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
                slotButton.setTitleColor(.black, for: .normal)
                slotButton.isEnabled = true
            case .booked:
                slotButton.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1)
                slotButton.setTitleColor(.white, for: .normal)
                slotButton.isEnabled = false
            case .selected:
                slotButton.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
                slotButton.setTitleColor(.white, for: .normal)
                slotButton.isEnabled = true
            }
            
            // Store date and slot info as tag
            slotButton.tag = slot.slotId
            slotButton.addTarget(self, action: #selector(slotButtonTapped(_:)), for: .touchUpInside)
            
            // Store date info in button (hacky but works for now)
            slotButton.accessibilityIdentifier = dateSchedule.dateString
            
            slotsStackView.addArrangedSubview(slotButton)
            
            NSLayoutConstraint.activate([
                slotButton.heightAnchor.constraint(equalToConstant: 36),
                slotButton.widthAnchor.constraint(equalTo: slotsStackView.widthAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: columnView.topAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: columnView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: columnView.trailingAnchor),
            
            dayLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            dayLabel.leadingAnchor.constraint(equalTo: columnView.leadingAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: columnView.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: columnView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: columnView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: columnView.bottomAnchor),
            
            slotsStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            slotsStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            slotsStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            slotsStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            slotsStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        return columnView
    }
    
    // MARK: - Navigation Actions
    @objc private func prevButtonTapped() {
        print("[\(TAG)] ⬅️ Previous page tapped")
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            displayCurrentPage()
        }
    }
    
    @objc private func nextButtonTapped() {
        print("[\(TAG)] ➡️ Next page tapped")
        let totalPages = (allDateSchedules.count + 2) / 3
        if currentPageIndex < totalPages - 1 {
            currentPageIndex += 1
            displayCurrentPage()
        }
    }
    
    @objc private func slotButtonTapped(_ sender: UIButton) {
        let slotId = sender.tag
        let dateString = sender.accessibilityIdentifier ?? ""
        
        print("[\(TAG)] 🎯 Slot tapped - Date: \(dateString), Slot ID: \(slotId)")
        
        // Find the time24Hour format for this slot
        guard let (time12, time24) = timeSlotMapping[slotId] else {
            print("[\(TAG)] ❌ Invalid slot ID: \(slotId)")
            return
        }
        
        // Reset all previously selected slots to available
        for i in 0..<allDateSchedules.count {
            for j in 0..<allDateSchedules[i].timeSlots.count {
                if allDateSchedules[i].timeSlots[j].state == .selected {
                    allDateSchedules[i].timeSlots[j].state = .available
                }
            }
        }
        
        // Mark the newly selected slot
        if let dateIndex = allDateSchedules.firstIndex(where: { $0.dateString == dateString }),
           let slotIndex = allDateSchedules[dateIndex].timeSlots.firstIndex(where: { $0.slotId == slotId }) {
            allDateSchedules[dateIndex].timeSlots[slotIndex].state = .selected
        }
        
        // Update selection
        selectedSlot = (date: dateString, slotId: slotId, time24Hour: time24)
        
        // Refresh display to update button states
        displayCurrentPage()
        
        // Enable make appointment button
        makeAppointmentButton.isEnabled = true
        makeAppointmentButton.alpha = 1.0
        
        // Auto-scroll to bottom on first selection only
        if !hasScrolledToButton {
            hasScrolledToButton = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                // Calculate the bottom offset with safe area
                let contentHeight = self.scrollView.contentSize.height
                let scrollViewHeight = self.scrollView.bounds.height
                let bottomInset = self.scrollView.contentInset.bottom + self.scrollView.safeAreaInsets.bottom
                
                let bottomOffset = CGPoint(
                    x: 0,
                    y: max(0, contentHeight - scrollViewHeight + bottomInset + 20)
                )
                self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
        
        print("[\(TAG)] ✅ Selected: \(dateString) at \(time12) (\(time24))")
    }
}

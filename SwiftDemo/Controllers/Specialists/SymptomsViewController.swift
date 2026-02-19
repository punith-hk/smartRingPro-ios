import UIKit

/// Symptoms selection screen for booking appointment
final class SymptomsViewController: AppBaseViewController {
    
    // MARK: - Properties
    private let doctor: Doctor
    private var selectedGender: Gender = .male
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Doctor Info Card
    private let doctorCardView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let qualificationLabel = UILabel()
    private let specializationLabel = UILabel()
    
    // Question Label
    private let questionLabel = UILabel()
    
    // Symptoms Summary Card
    private let symptomsCardView = UIView()
    private let symptomsHeaderLabel = UILabel()
    private let symptomsContentLabel = UILabel()
    private let proceedButton = UIButton(type: .system)
    
    // Human body diagram
    private let humanBodyView = HumanBodyView()
    
    // Other Symptoms Button
    private let otherSymptomsButton = UIButton(type: .system)
    
    // Selected symptoms storage
    private var selectedSymptoms: [String: [String]] = [:] // bodyPart: [symptoms]
    
    // Constraint for question label layout
    private var questionLabelTopConstraint: NSLayoutConstraint?
    
    // Symptoms data from API
    private var symptomsData: [String: [String]] = [:]
    private var isLoadingSymptoms = false
    
    // Loading
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    
    private let TAG = "SymptomsViewController"
    
    // MARK: - Init
    init(doctor: Doctor) {
        self.doctor = doctor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreenTitle("Symptoms")
        view.backgroundColor = UIColor(red: 0.30, green: 0.60, blue: 0.95, alpha: 1)
        
        // Load saved gender preference
        loadGenderPreference()
        
        setupScrollView()
        setupDoctorCard()
        setupSymptomsCard()
        setupQuestionLabel()
        setupHumanBodyView()
        setupOtherSymptomsButton()
        setupLoadingView()
        
        configureDoctorInfo()
        fetchSymptoms()
        
        print("[\(TAG)] 🩺 Loaded for doctor: \(doctor.displayName) (ID: \(doctor.id))")
    }
    
    // MARK: - Setup UI
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
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
        symptomsCardView.isHidden = true // Initially hidden
        contentView.addSubview(symptomsCardView)
        
        // Header Label
        symptomsHeaderLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        symptomsHeaderLabel.textColor = .black
        symptomsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        symptomsCardView.addSubview(symptomsHeaderLabel)
        
        // Content Label
        symptomsContentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        symptomsContentLabel.textColor = .darkGray
        symptomsContentLabel.numberOfLines = 0
        symptomsContentLabel.translatesAutoresizingMaskIntoConstraints = false
        symptomsCardView.addSubview(symptomsContentLabel)
        
        // Proceed Button
        proceedButton.setTitle("Proceed", for: .normal)
        proceedButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        proceedButton.setTitleColor(.white, for: .normal)
        proceedButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        proceedButton.layer.cornerRadius = 12
        proceedButton.translatesAutoresizingMaskIntoConstraints = false
        proceedButton.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        proceedButton.isEnabled = false // Initially disabled
        proceedButton.alpha = 0.5 // Visual feedback
        symptomsCardView.addSubview(proceedButton)
        
        NSLayoutConstraint.activate([
            symptomsCardView.topAnchor.constraint(equalTo: doctorCardView.bottomAnchor, constant: 16),
            symptomsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            symptomsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            symptomsHeaderLabel.topAnchor.constraint(equalTo: symptomsCardView.topAnchor, constant: 16),
            symptomsHeaderLabel.leadingAnchor.constraint(equalTo: symptomsCardView.leadingAnchor, constant: 16),
            symptomsHeaderLabel.trailingAnchor.constraint(equalTo: symptomsCardView.trailingAnchor, constant: -16),
            
            symptomsContentLabel.topAnchor.constraint(equalTo: symptomsHeaderLabel.bottomAnchor, constant: 12),
            symptomsContentLabel.leadingAnchor.constraint(equalTo: symptomsCardView.leadingAnchor, constant: 16),
            symptomsContentLabel.trailingAnchor.constraint(equalTo: symptomsCardView.trailingAnchor, constant: -16),
            
            proceedButton.topAnchor.constraint(equalTo: symptomsContentLabel.bottomAnchor, constant: 16),
            proceedButton.centerXAnchor.constraint(equalTo: symptomsCardView.centerXAnchor),
            proceedButton.widthAnchor.constraint(equalToConstant: 120),
            proceedButton.heightAnchor.constraint(equalToConstant: 44),
            proceedButton.bottomAnchor.constraint(equalTo: symptomsCardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupQuestionLabel() {
        questionLabel.text = "Select 4 to 8 symptoms you are facing"
        questionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(questionLabel)
        
        // Initially anchor to doctor card since no symptoms selected
        questionLabelTopConstraint = questionLabel.topAnchor.constraint(equalTo: doctorCardView.bottomAnchor, constant: 20)
        
        NSLayoutConstraint.activate([
            questionLabelTopConstraint!,
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupHumanBodyView() {
        humanBodyView.gender = selectedGender
        humanBodyView.delegate = self
        humanBodyView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(humanBodyView)
        
        NSLayoutConstraint.activate([
            humanBodyView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            humanBodyView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            humanBodyView.widthAnchor.constraint(equalToConstant: 280),
            humanBodyView.heightAnchor.constraint(equalToConstant: 480) // Increased from 450
        ])
    }
    
    private func setupOtherSymptomsButton() {
        // Create label for "Other" (top)
        let otherLabel = UILabel()
        otherLabel.text = "Other"
        otherLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        otherLabel.textColor = .black
        otherLabel.textAlignment = .center
        otherLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create label for "Symptoms" (bottom)
        let symptomsLabel = UILabel()
        symptomsLabel.text = "Symptoms"
        symptomsLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        symptomsLabel.textColor = .black
        symptomsLabel.textAlignment = .center
        symptomsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Style button as square box
        otherSymptomsButton.setTitle("", for: .normal) // Clear default title
        otherSymptomsButton.backgroundColor = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1) // Orange
        otherSymptomsButton.layer.cornerRadius = 12
        otherSymptomsButton.translatesAutoresizingMaskIntoConstraints = false
        otherSymptomsButton.addTarget(self, action: #selector(otherSymptomsButtonTapped), for: .touchUpInside)
        contentView.addSubview(otherSymptomsButton)
        
        // Add labels to button
        otherSymptomsButton.addSubview(otherLabel)
        otherSymptomsButton.addSubview(symptomsLabel)
        
        NSLayoutConstraint.activate([
            // Button - square shape on the right, aligned with leg bottom
            otherSymptomsButton.bottomAnchor.constraint(equalTo: humanBodyView.bottomAnchor, constant: -20),
            otherSymptomsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            otherSymptomsButton.widthAnchor.constraint(equalToConstant: 90),
            otherSymptomsButton.heightAnchor.constraint(equalToConstant: 90),
            
            // Content view bottom constraint
            contentView.bottomAnchor.constraint(equalTo: humanBodyView.bottomAnchor, constant: 40),
            
            // "Other" label - top half
            otherLabel.topAnchor.constraint(equalTo: otherSymptomsButton.topAnchor, constant: 20),
            otherLabel.centerXAnchor.constraint(equalTo: otherSymptomsButton.centerXAnchor),
            
            // "Symptoms" label - bottom half
            symptomsLabel.topAnchor.constraint(equalTo: otherLabel.bottomAnchor, constant: 4),
            symptomsLabel.centerXAnchor.constraint(equalTo: otherSymptomsButton.centerXAnchor)
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
        loadingLabel.text = "Loading Symptoms..."
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
    
    // MARK: - Gender Handling
    private func loadGenderPreference() {
        // Try to get gender from UserDefaults (saved from profile)
        if let savedGender = UserDefaultsManager.shared.profileGender {
            selectedGender = (savedGender == "F") ? .female : .male
            humanBodyView.gender = selectedGender
        } else {
            // Default to male
            selectedGender = .male
            humanBodyView.gender = .male
        }
    }
    
    // MARK: - API Calls
    private func fetchSymptoms() {
        guard !isLoadingSymptoms else { return }
        isLoadingSymptoms = true
        
        print("[\(TAG)] 📡 Fetching symptoms from API...")
        loadingView.startAnimating()
        view.bringSubviewToFront(loadingView)
        
        SymptomService.shared.getAllSymptoms { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingSymptoms = false
                
                switch result {
                case .success(let response):
                    print("[\(self.TAG)] ✅ Symptoms fetched successfully")
                    self.processSymptomsData(response.data)
                    self.loadingView.stopAnimating()
                    
                case .failure(let error):
                    self.loadingView.stopAnimating()
                    print("[\(self.TAG)] ❌ Failed to fetch symptoms: \(error.localizedDescription)")
                    self.showErrorAlert(
                        title: "Error Loading Symptoms",
                        message: "Could not load symptoms. Please try again.",
                        retryAction: { [weak self] in
                            self?.fetchSymptoms()
                        }
                    )
                }
            }
        }
    }
    
    private func processSymptomsData(_ data: SymptomData) {
        // Get the correct gender data
        let genderData = selectedGender == .male ? data.male : data.female
        
        // Convert API data to our format: [BodyPart: [Symptom Titles]]
        var processedData: [String: [String]] = [:]
        
        for (bodyPart, symptoms) in genderData {
            processedData[bodyPart] = symptoms.map { $0.title }
        }
        
        symptomsData = processedData
        
        print("[\(TAG)] 📊 Processed \(symptomsData.keys.count) body parts with symptoms")
        print("[\(TAG)] 📋 Body parts: \(symptomsData.keys.sorted().joined(separator: ", "))")
    }
    
    private func showErrorAlert(title: String, message: String, retryAction: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let retryAction = retryAction {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                retryAction()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Configure
    private func configureDoctorInfo() {
        nameLabel.text = doctor.displayName
        qualificationLabel.text = doctor.qualificationsText
        specializationLabel.text = doctor.specializationText.uppercased()
        
        // Load profile image
        if let imageURL = doctor.profileImageURL {
            profileImageView.loadImage(from: imageURL)
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .lightGray
        }
    }
    
    // MARK: - Actions
    @objc private func otherSymptomsButtonTapped() {
        print("[\(TAG)] 📝 Other Symptoms tapped")
        showSymptomsPopup(for: "Other Symptoms")
    }
    
    private func showSymptomsPopup(for bodyPart: String) {
        // Get symptoms for this body part
        guard let symptoms = symptomsData[bodyPart] else {
            print("[\(TAG)] ⚠️ No symptoms data for \(bodyPart)")
            return
        }
        
        // Check total symptoms already selected (excluding current body part)
        let currentTotal = selectedSymptoms.filter { $0.key != bodyPart }
            .reduce(0) { $0 + $1.value.count }
        
        // Calculate how many symptoms can still be selected
        let totalLimit = 8
        let currentBodyPartCount = selectedSymptoms[bodyPart]?.count ?? 0
        let availableSlots = totalLimit - currentTotal
        
        // If no slots available and nothing previously selected for this part, show warning
        if availableSlots <= 0 && currentBodyPartCount == 0 {
            let alert = UIAlertController(
                title: "Selection Limit Reached",
                message: "You have already selected 8 symptoms in total. Please deselect some symptoms from other body parts first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Get previously selected symptoms for this body part
        let preselected = selectedSymptoms[bodyPart] ?? []
        
        // Pass available slots as maxSelection to disable options when limit reached
        let popup = MultiSelectPopupViewController(
            title: bodyPart,
            options: symptoms,
            preselected: preselected,
            maxSelection: availableSlots
        )
        
        popup.onConfirm = { [weak self] selectedItems in
            guard let self = self else { return }
            
            // Validate total limit before saving
            let otherTotal = self.selectedSymptoms.filter { $0.key != bodyPart }
                .reduce(0) { $0 + $1.value.count }
            
            if otherTotal + selectedItems.count > totalLimit {
                let alert = UIAlertController(
                    title: "Total Limit Exceeded",
                    message: "Maximum 8 symptoms can be selected in total. You currently have \(otherTotal) symptoms selected in other body parts.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Store selected symptoms for this body part
            if selectedItems.isEmpty {
                self.selectedSymptoms.removeValue(forKey: bodyPart)
            } else {
                self.selectedSymptoms[bodyPart] = selectedItems
            }
            
            let symptomsList = selectedItems.joined(separator: ", ")
            let totalCount = self.selectedSymptoms.values.reduce(0) { $0 + $1.count }
            print("[\(self.TAG)] ✅ Selected symptoms for \(bodyPart): \(symptomsList)")
            print("[\(self.TAG)] 📊 Total symptoms selected: \(totalCount)/8")
            
            // Update UI to show selected symptoms
            self.updateSymptomsDisplay()
            self.updateBodyPartColors()
        }
        
        popup.onCancel = {
            print("[\(self.TAG)] ❌ Cancelled symptom selection for \(bodyPart)")
        }
        
        present(popup, animated: true)
    }
    
    private func updateSymptomsDisplay() {
        let totalCount = selectedSymptoms.values.reduce(0) { $0 + $1.count }
        
        if selectedSymptoms.isEmpty {
            symptomsCardView.isHidden = true
            
            // Disable proceed button when no symptoms
            proceedButton.isEnabled = false
            proceedButton.alpha = 0.5
            
            // Update question label to anchor to doctor card (no gap)
            questionLabelTopConstraint?.isActive = false
            questionLabelTopConstraint = questionLabel.topAnchor.constraint(equalTo: doctorCardView.bottomAnchor, constant: 20)
            questionLabelTopConstraint?.isActive = true
            
            return
        }
        
        symptomsCardView.isHidden = false
        symptomsHeaderLabel.text = "Symptoms (\(totalCount)/8) - Select 4-8"
        
        // Enable proceed button only when 4-8 symptoms are selected
        if totalCount >= 4 && totalCount <= 8 {
            proceedButton.isEnabled = true
            proceedButton.alpha = 1.0
        } else {
            proceedButton.isEnabled = false
            proceedButton.alpha = 0.5
        }
        
        // Update question label to anchor to symptoms card
        questionLabelTopConstraint?.isActive = false
        questionLabelTopConstraint = questionLabel.topAnchor.constraint(equalTo: symptomsCardView.bottomAnchor, constant: 20)
        questionLabelTopConstraint?.isActive = true
        
        // Build symptoms text grouped by body part with bold body part names
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
        
        // Animate layout changes
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateBodyPartColors() {
        // Filter out non-body-part entries like "Other Symptoms"
        // Only pass actual body parts that are displayed on the human body view
        let displayedBodyParts = ["Head", "Throat", "Left Hand", "Right Hand", "Chest", "Stomach", "Pelvis", "Left Leg", "Right Leg"]
        let selectedBodyParts = selectedSymptoms.keys.filter { displayedBodyParts.contains($0) }
        
        // Update body part colors based on selection
        humanBodyView.updateSelectedParts(Array(selectedBodyParts))
        print("[\(TAG)] 🎨 Updated body colors for: \(selectedBodyParts.joined(separator: ", "))")
    }
    
    @objc private func proceedButtonTapped() {
        // Count total symptoms
        let totalCount = selectedSymptoms.values.reduce(0) { $0 + $1.count }
        
        // Validate minimum 4 symptoms
        guard totalCount >= 4 else {
            let alert = UIAlertController(
                title: "Insufficient Symptoms",
                message: "Please select at least 4 symptoms to proceed. You have selected \(totalCount).",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Validate maximum 8 symptoms
        guard totalCount <= 8 else {
            let alert = UIAlertController(
                title: "Too Many Symptoms",
                message: "You can select a maximum of 8 symptoms. You have selected \(totalCount).",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        print("[\(TAG)] ➡️ Proceed tapped with symptoms: \(selectedSymptoms)")
        
        // Navigate to appointment scheduling screen
        let appointmentVC = AppointmentViewController(
            doctor: doctor,
            selectedSymptoms: selectedSymptoms
        )
        navigationController?.pushViewController(appointmentVC, animated: true)
    }
}

// MARK: - HumanBodyViewDelegate
extension SymptomsViewController: HumanBodyViewDelegate {
    func humanBodyView(_ view: HumanBodyView, didTapBodyPart part: BodyPart) {
        print("[\(TAG)] 🫱 Body part tapped: \(part.displayName)")
        showSymptomsPopup(for: part.displayName)
    }
}

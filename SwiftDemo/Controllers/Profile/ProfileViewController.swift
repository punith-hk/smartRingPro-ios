import UIKit

extension Notification.Name {
    static let profileDataLoaded = Notification.Name("profileDataLoaded")
}

class ProfileViewController: AppBaseViewController {
    
    private var userResId: Int = 0      // patient_id
    private var loggedInUserId: Int = 0 // user_id


    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Profile Image
    private let profileImageView = UIImageView()
    private let uploadButton = UIButton(type: .system)
    private let uploadHintLabel = UILabel()

    // MARK: - Fields
//    private let nameField = UITextField()
    private let firstNameField = UITextField()
    private let lastNameField = UITextField()
    private let emailField = UITextField()
    private let mobileField = UITextField()
    private let dobField = UITextField()
    private let genderField = UITextField()
    private let bloodGroupField = UITextField()
    private let heightField = UITextField()
    private let weightField = UITextField()
    private let addressField = UITextField()
    private let countryField = UITextField()
    private let stateField = UITextField()
    private let cityField = UITextField()
    private let zipField = UITextField()
    private let diseasesField = UITextField()
    private let medicationField = UITextField()

    // MARK: - Save Button
    private let saveButton = UIButton(type: .system)
    
    private let diseases = [
        "Cardiovascular diseases",
        "Diabetes",
        "Respiratory diseases",
        "Tuberculosis",
        "Cancer",
        "Malaria",
        "Stroke",
        "Hepatitis",
        "AIDS",
        "COVID-19",
        "Dengue",
        "Kidney diseases",
        "Hypertension",
        "Influenza",
        "Mental disorder",
        "Obesity",
        "Typhoid",
        "Chronic Obstructive Pulmonary Disease",
        "Diarrhoea",
        "Liver disease",
        "Malignant tumours",
        "Asthma",
        "Gastrointestinal disease",
        "Infectious diseases"
    ]
    
    private let genderOptions = ["Male", "Female"]

    private let bloodGroups = [
        "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"
    ]
    
    private var compressedImageData: Data?
    
    private let dobPicker = UIDatePicker()
    private let dobFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd-MM-yyyy"
        return df
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

        setupScroll()
        setupProfileHeader()
        setUpImageTab()
        setupForm()
        configureTapAndKeyboards()

        setupDropdowns()
        setupDOBPicker()
        setupSaveButton()
        
        fetchUserProfile()

    }
    
    // MARK: - Scroll Setup
    private func setupScroll() {

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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Header
    private func setupProfileHeader() {

        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerContainer)

        // Profile Image (LEFT)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .white
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 40
        profileImageView.clipsToBounds = true

        // Upload Button
        uploadButton.setTitle("Upload Photo", for: .normal)
        uploadButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 6
        uploadButton.translatesAutoresizingMaskIntoConstraints = false

        // Hint Text
        uploadHintLabel.text = "Allowed JPG, PNG or GIF\nmax size of 2MB"
        uploadHintLabel.font = .systemFont(ofSize: 12)
        uploadHintLabel.textColor = .white
        uploadHintLabel.numberOfLines = 2
        uploadHintLabel.translatesAutoresizingMaskIntoConstraints = false

        // Right Stack (Button + Text)
        let rightStack = UIStackView(arrangedSubviews: [uploadButton, uploadHintLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 6
        rightStack.alignment = .leading
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        headerContainer.addSubview(profileImageView)
        headerContainer.addSubview(rightStack)

        NSLayoutConstraint.activate([
            // Header container
            headerContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Profile image (LEFT)
            profileImageView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            profileImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),

            // Right stack (BUTTON + TEXT)
            rightStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            rightStack.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            rightStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),

            uploadButton.widthAnchor.constraint(equalToConstant: 140),
            uploadButton.heightAnchor.constraint(equalToConstant: 36),

            // Bottom anchor for layout flow
            headerContainer.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor),
        ])
    }
    
    private func setUpImageTab() {
        let imageTap = UITapGestureRecognizer(
            target: self,
            action: #selector(showImageSourcePicker)
        )
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imageTap)

        uploadButton.addTarget(
            self,
            action: #selector(showImageSourcePicker),
            for: .touchUpInside
        )
    }

    // MARK: - Form
    private func setupForm() {

        let fields: [UIView] = [

            createLabeledField(
                labelText: "First Name",
                textField: firstNameField,
                placeholder: "Enter first name"
            ),
            createLabeledField(
                labelText: "Last Name",
                textField: lastNameField,
                placeholder: "Enter last name"
            ),

            createLabeledField(
                labelText: "Email ID",
                textField: emailField,
                placeholder: "example@email.com"
            ),

            createLabeledField(
                labelText: "Mobile Number",
                textField: mobileField,
                placeholder: "10 digit number"
            ),

            createLabeledField(
                labelText: "Date of Birth (yyyy-mm-dd)",
                textField: dobField,
                placeholder: "dd-mm-yyyy",
                rightIcon: "calendar"
            ),

            createLabeledField(
                labelText: "Gender",
                textField: genderField,
                placeholder: "Select gender",
                rightIcon: "chevron.down"
            ),

            createLabeledField(
                labelText: "Blood Group",
                textField: bloodGroupField,
                placeholder: "Select blood group",
                rightIcon: "chevron.down"
            ),

            createLabeledField(
                labelText: "Height in CM",
                textField: heightField,
                placeholder: "in cm"
            ),

            createLabeledField(
                labelText: "Weight in KG",
                textField: weightField,
                placeholder: "in kg"
            ),

            createLabeledField(
                labelText: "Address",
                textField: addressField,
                placeholder: "House no, street, area"
            ),

            createLabeledField(
                labelText: "Country",
                textField: countryField,
                placeholder: "Country"
            ),

            createLabeledField(
                labelText: "State",
                textField: stateField,
                placeholder: "State"
            ),

            createLabeledField(
                labelText: "City",
                textField: cityField,
                placeholder: "City"
            ),

            createLabeledField(
                labelText: "Zip Code",
                textField: zipField,
                placeholder: "Pincode"
            ),

            createLabeledField(
                labelText: "Existing Diseases",
                textField: diseasesField,
                placeholder: "Select diseases",
                rightIcon: "chevron.down"
            ),

            createLabeledField(
                labelText: "Existing Medication",
                textField: medicationField,
                placeholder: "Enter medication"
            )
        ]

        var topAnchor = uploadHintLabel.bottomAnchor

        for field in fields {
            contentView.addSubview(field)

            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: topAnchor, constant: 16),
                field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])

            topAnchor = field.bottomAnchor
        }
    }

    private func createLabeledField(
        labelText: String,
        textField: UITextField,
        placeholder: String,
        rightIcon: String? = nil
    ) -> UIView {

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Label
        let label = UILabel()
        label.text = labelText
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        // Field container (your existing style)
        let fieldContainer = UIView()
        fieldContainer.backgroundColor = .white
        fieldContainer.layer.cornerRadius = 10
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false

        fieldContainer.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            textField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor)
        ])

        if let icon = rightIcon {
            let imageView = UIImageView(image: UIImage(systemName: icon))
            imageView.tintColor = .lightGray
            imageView.translatesAutoresizingMaskIntoConstraints = false
            fieldContainer.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -16),
                imageView.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),

                textField.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -8)
            ])
        } else {
            textField.trailingAnchor
                .constraint(equalTo: fieldContainer.trailingAnchor, constant: -16)
                .isActive = true
        }

        container.addSubview(label)
        container.addSubview(fieldContainer)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            fieldContainer.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            fieldContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            fieldContainer.heightAnchor.constraint(equalToConstant: 48),

            fieldContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
    
    private func configureTapAndKeyboards() {
        emailField.keyboardType = .emailAddress
        mobileField.keyboardType = .numberPad
        heightField.keyboardType = .numberPad
        weightField.keyboardType = .numberPad
        zipField.keyboardType = .numberPad
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false // VERY IMPORTANT
        view.addGestureRecognizer(tapGesture)
        
        [
            firstNameField,
            lastNameField,
            emailField,
            mobileField,
            heightField,
            weightField,
            addressField,
            countryField,
            stateField,
            cityField,
            zipField,
            medicationField,
        ].forEach {
            addDoneToolbar(to: $0)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func addDoneToolbar(to textField: UITextField) {

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let spacer = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )

        toolbar.items = [spacer, doneButton]
        textField.inputAccessoryView = toolbar
    }
    
    
    private func setupDOBPicker() {

        dobPicker.datePickerMode = .date
        dobPicker.maximumDate = Date() // no future DOB

        if #available(iOS 13.4, *) {
            dobPicker.preferredDatePickerStyle = .wheels
        }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let spacer = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(didSelectDOB)
        )

        toolbar.setItems([spacer, doneButton], animated: false)

        dobField.inputView = dobPicker
        dobField.inputAccessoryView = toolbar

        // UX polish
        dobField.tintColor = .clear // hide cursor
    }

    @objc private func didSelectDOB() {

        let selectedDate = dobPicker.date
        let formatted = dobFormatter.string(from: selectedDate)

        // Normal date text
        let dateAttr = NSAttributedString(
            string: formatted,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
        )

        // Italic format hint
        let hintAttr = NSAttributedString(
            string: " (dd-MM-yyyy)",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor.lightGray
            ]
        )

        let finalText = NSMutableAttributedString()
        finalText.append(dateAttr)
        finalText.append(hintAttr)

        dobField.attributedText = dateAttr
        dobField.resignFirstResponder()
    }
    
    
    private func setupDropdowns() {

        configureDropdown(
            field: diseasesField,
            action: #selector(openDiseaseSelector)
        )

        configureDropdown(
            field: genderField,
            action: #selector(openGenderSelector)
        )

        configureDropdown(
            field: bloodGroupField,
            action: #selector(openBloodGroupSelector)
        )
    }
    
    private func configureDropdown(
        field: UITextField,
        action: Selector
    ) {
        field.inputView = UIView() // disable keyboard
        field.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: action)
        field.addGestureRecognizer(tap)
    }

    
    private func fetchUserProfile() {
        
        Loader.shared.show(on: view)

        loggedInUserId = UserDefaults.standard.integer(forKey: "id") // USER ID
        guard loggedInUserId > 0 else { return }

        ProfileService.shared.getUserProfile(
            userId: loggedInUserId
        ) { [weak self] result in

            DispatchQueue.main.async {
                guard let self = self else { return }
                
                Loader.shared.hide()

                switch result {

                case .success(let response):
                    self.bindProfileData(response.data)

                case .failure:
                    Toast.show(message: "Failed to fetch profile data", in: self.view)
                }
            }
        }
    }
    
    private func bindProfileData(_ data: ProfileDataResponse.ProfileData) {

        userResId = data.user_id
        
        firstNameField.text = data.first_name ?? ""
        lastNameField.text = data.last_name ?? ""
        
        // Post notification to update side menu with profile data
        let fullName = "\(data.first_name ?? "") \(data.last_name ?? "")".trimmingCharacters(in: .whitespaces)
        NotificationCenter.default.post(
            name: .profileDataLoaded,
            object: nil,
            userInfo: ["name": fullName, "imageUrl": data.patient_image_url ?? ""]
        )
        
        // Save to UserDefaults for persistence
        UserDefaultsManager.shared.saveProfileData(name: fullName, photoUrl: data.patient_image_url ?? "")

        emailField.text = data.email ?? ""
        mobileField.text = data.phone_number
        dobField.text = data.dob ?? ""

        if data.gender == "M" {
            genderField.text = "Male"
        } else if data.gender == "F" {
            genderField.text = "Female"
        }

        bloodGroupField.text = data.blood_group ?? ""
        heightField.text = data.height
        weightField.text = data.weight

        addressField.text = data.address ?? ""
        countryField.text = data.country ?? ""
        stateField.text = data.state ?? ""
        cityField.text = data.city ?? ""
        zipField.text = data.pincode ?? ""

        diseasesField.text = data.existing_diseases ?? ""
        medicationField.text = data.existing_medications ?? ""

        if let imageUrl = data.patient_image_url,
           let url = URL(string: imageUrl) {

            profileImageView.loadImage(from: url)
        }
    }
    


    
    @objc private func showImageSourcePicker() {

        let sheet = UIAlertController(
            title: "Upload Profile Photo",
            message: nil,
            preferredStyle: .actionSheet
        )

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(
                UIAlertAction(title: "Camera", style: .default) { _ in
                    self.openImagePicker(source: .camera)
                }
            )
        }

        sheet.addAction(
            UIAlertAction(title: "Photo Library", style: .default) { _ in
                self.openImagePicker(source: .photoLibrary)
            }
        )

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // ✅ iPad safety
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = uploadButton
            popover.sourceRect = uploadButton.bounds
        }

        present(sheet, animated: true)
    }

    
    private func openImagePicker(source: UIImagePickerController.SourceType) {

        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = false // default crop OFF (Android parity)

        present(picker, animated: true)
    }
    
    // MARK: - Save Button
    private func setupSaveButton() {

        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.layer.cornerRadius = 12
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: medicationField.superview!.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
        
        saveButton.addTarget(
            self,
            action: #selector(saveProfileTapped),
            for: .touchUpInside
        )

    }

    private func buildProfileParams() -> [String: String] {

        var params: [String: String] = [:]
        
        params["user_id"] = String(userResId)
        params["id"] = String(loggedInUserId)

        params["first_name"] = firstNameField.text
        params["last_name"] = lastNameField.text
        params["email"] = emailField.text
        params["phone_number"] = mobileField.text
        params["emergency_phone"] = ""
        params["dob"] = apiDOB(from: dobField.text)

        // Gender mapping
        if genderField.text == "Male" {
            params["gender"] = "M"
        } else if genderField.text == "Female" {
            params["gender"] = "F"
        }

        params["blood_group"] = bloodGroupField.text
        params["address"] = addressField.text
        params["city"] = cityField.text
        params["state"] = stateField.text
        params["country"] = countryField.text
        params["pincode"] = zipField.text

        params["height"] = cleanNumericValue(heightField.text)
        params["weight"] = cleanNumericValue(weightField.text)
        
        params["existing_diseases"] =
            diseasesField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        params["existing_medications"] =
            medicationField.text?.trimmingCharacters(in: .whitespaces) ?? ""


        params["status"] = "1"
        params["allergy"] = "0"

        return params.compactMapValues { value in
            value.isEmpty ? nil : value
        }

    }
    
    private func cleanNumericValue(_ text: String?) -> String? {

        guard let text = text, !text.isEmpty else { return nil }

        // Remove anything that is NOT a number or dot
        let cleaned = text
            .replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)

        return cleaned.isEmpty ? nil : cleaned
    }

    
    @objc private func saveProfileTapped() {
        
        Loader.shared.show(on: view)

        view.endEditing(true)

        guard validateMandatoryFields() else { return }

        let params = buildProfileParams()
        
//        print("URL patient id:", userResId)
//        print("Body user_id:", loggedInUserId)
//        
//        print("➡️ POST /patients/\(loggedInUserId)")
//        params.forEach { print("\($0.key): \($0.value)") }


        ProfileService.shared.saveUserProfile(
            userId: loggedInUserId,
            params: params,
            profileImage: compressedImageData
        ) { [weak self] result in

            DispatchQueue.main.async {
                guard let self = self else { return }
                
                Loader.shared.hide()

                switch result {

                case .success(let response):
                    Toast.show(message: response.message, in: self.view)
                    self.scrollView.setContentOffset(.zero, animated: true)

                case .failure:
                    Toast.show(message: "Failed to save profile", in: self.view)
                }
            }
        }
    }

    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func isValidMobile(_ mobile: String) -> Bool {
        return mobile.count == 10 && mobile.allSatisfy { $0.isNumber }
    }
    
    private func apiDOB(from displayDOB: String?) -> String? {
        guard let displayDOB = displayDOB, !displayDOB.isEmpty else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd-MM-yyyy"

        let apiFormatter = DateFormatter()
        apiFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = displayFormatter.date(from: displayDOB) else {
            return nil
        }

        return apiFormatter.string(from: date)
    }

    
    private func validateMandatoryFields() -> Bool {

        let firstName = firstNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let mobile = mobileField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        if firstName.isEmpty {
            Toast.show(message: "Please enter your first name", in: self.view)
            return false
        }

        if email.isEmpty {
            Toast.show(message: "Please enter your email", in: self.view)
            return false
        }

        if !isValidEmail(email) {
            Toast.show(message: "Please enter a valid email address", in: self.view)
            return false
        }

        if mobile.isEmpty {
            Toast.show(message: "Please enter your mobile number", in: self.view)
            return false
        }

        if !isValidMobile(mobile) {
            Toast.show(message: "Please enter a valid 10 digit mobile number", in: self.view)
            return false
        }

        return true
    }

    
    @objc private func openDiseaseSelector() {

        // Get previously selected diseases (if any)
        let preselected = diseasesField.text?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Select Diseases",
            options: diseases,
            preselected: preselected,
            maxSelection: 4   // ✅ LIMIT TO 4
        )

        popup.onConfirm = { [weak self] selectedItems in
            guard let self = self else { return }

            let joined = selectedItems.joined(separator: ", ")
            self.diseasesField.text = joined
        }

        popup.onCancel = {
            // nothing needed
        }

        present(popup, animated: true)
    }
    
    @objc private func openGenderSelector() {

        let preselected = genderField.text.map { [$0] } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Select Gender",
            options: genderOptions,
            preselected: preselected,
            maxSelection: 1   // ✅ SINGLE SELECT
        )

        popup.onConfirm = { [weak self] selected in
            self?.genderField.text = selected.first
        }

        present(popup, animated: true)
    }
    
    @objc private func openBloodGroupSelector() {

        let preselected = bloodGroupField.text.map { [$0] } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Select Blood Group",
            options: bloodGroups,
            preselected: preselected,
            maxSelection: 1   // ✅ SINGLE SELECT
        )

        popup.onConfirm = { [weak self] selected in
            self?.bloodGroupField.text = selected.first
        }

        present(popup, animated: true)
    }

}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {

        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        if let compressedData = compressImage(image) {

            // store for API
            compressedImageData = compressedData

            // preview
            profileImageView.image = UIImage(data: compressedData)
            profileImageView.image = UIImage(data: compressedData)
            profileImageView.layoutIfNeeded()
            profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
            profileImageView.clipsToBounds = true

        }
    }
    
    private func compressImage(_ image: UIImage) -> Data? {

        let maxDimension: CGFloat = 1080
        var resizedImage = image

        let width = image.size.width
        let height = image.size.height
        let ratio = width / height

        if width > maxDimension || height > maxDimension {

            let newSize: CGSize
            if ratio > 1 {
                newSize = CGSize(
                    width: maxDimension,
                    height: maxDimension / ratio
                )
            } else {
                newSize = CGSize(
                    width: maxDimension * ratio,
                    height: maxDimension
                )
            }

            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }

        // 🔁 Progressive JPEG compression (≤ 1 MB)
        var quality: CGFloat = 1.0
        var imageData = resizedImage.jpegData(compressionQuality: quality)

        while let data = imageData,
              data.count > 1_000_000, // 1 MB
              quality > 0.1 {

            quality -= 0.05
            imageData = resizedImage.jpegData(compressionQuality: quality)
        }

        if let data = imageData {
            let sizeMB = Double(data.count) / 1024.0 / 1024.0
            print("✅ Final image size: \(String(format: "%.2f", sizeMB)) MB")
        }

        return imageData
    }

}

extension UIImageView {

    func loadImage(from url: URL) {

        let activity = UIActivityIndicatorView(style: .medium)
        activity.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activity)

        NSLayoutConstraint.activate([
            activity.centerXAnchor.constraint(equalTo: centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        activity.startAnimating()

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                activity.removeFromSuperview()

                guard
                    let self = self,
                    let data = data,
                    let image = UIImage(data: data)
                else { return }

                self.image = image
                self.contentMode = .scaleAspectFill
                self.clipsToBounds = true

                // ✅ Force layout before rounding
                self.layoutIfNeeded()

                // ✅ Correct circular mask
                self.layer.cornerRadius = self.bounds.width / 2
            }
        }.resume()
    }
}

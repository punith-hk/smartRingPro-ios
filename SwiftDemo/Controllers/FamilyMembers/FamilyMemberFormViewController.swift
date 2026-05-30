import UIKit

enum FamilyMemberFormMode {
    case add
    case edit(FamilyMember)
}

final class FamilyMemberFormViewController: AppBaseViewController {
    
    var onSuccess: (() -> Void)?

    // MARK: - Mode
    var mode: FamilyMemberFormMode = .add

    // MARK: - IDs
    private let loggedInUserId: Int = UserDefaults.standard.integer(forKey: "id")

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let profileImageView = UIImageView()
    private let uploadButton = UIButton(type: .system)
    private let uploadHintLabel = UILabel()

    private let nameField = UITextField()
    private let relationField = UITextField()
    private let dobField = UITextField()
    private let genderField = UITextField()
    private let bloodGroupField = UITextField()
    private let diseasesField = UITextField()
    private let medicationField = UITextField()
    private let heightField = UITextField()
    private let weightField = UITextField()
    private let emergencyPhoneField = UITextField()
    private let addressField = UITextField()
    private let countryField = UITextField()
    private let stateField = UITextField()
    private let cityField = UITextField()
    private let zipField = UITextField()

    private let saveButton = UIButton(type: .system)

    // MARK: - Data
    private var compressedImageData: Data?
    private var selectedMedications: [MedicationEntry] = []
    private var selectedCountryCode: String = ""

    private let relationOptions = ["Father", "Mother", "Spouse", "Son", "Daughter", "Sibling", "Other"]
    private let genderOptions = ["Male", "Female", "Other"]
    private let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]

    private let diseases = [
        "Diabetes", "Hypertension", "Asthma", "Heart Disease",
        "Kidney Disease", "Thyroid", "Cancer", "COVID-19"
    ]

    // MARK: - DOB Picker
    private let dobPicker = UIDatePicker()
    private let dobFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        configureImageUpload()
        setupDOBPicker()
        setupDropdowns()
        configureTapAndKeyboards()
        setupActions()
        configureForMode()
    }
    
    private func configureImageUpload() {

        profileImageView.isUserInteractionEnabled = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(openImagePicker)
        )

        profileImageView.addGestureRecognizer(tapGesture)

        uploadButton.addTarget(
            self,
            action: #selector(openImagePicker),
            for: .touchUpInside
        )
    }
    
    @objc private func openImagePicker() {

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self

        present(picker, animated: true)
    }


    // MARK: - UI Setup
    private func setupUI() {

        view.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)

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

        setupHeader()
        setupForm()
        setupSaveButton()
    }

    private func setupHeader() {

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)
        profileImageView.layer.cornerRadius = 40
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        uploadButton.setTitle("Upload Photo", for: .normal)
        uploadButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 6
        uploadButton.translatesAutoresizingMaskIntoConstraints = false

        uploadHintLabel.text = "JPG / PNG • Max 2MB"
        uploadHintLabel.font = .systemFont(ofSize: 12)
        uploadHintLabel.textColor = .darkGray
        uploadHintLabel.translatesAutoresizingMaskIntoConstraints = false

        let rightStack = UIStackView(arrangedSubviews: [uploadButton, uploadHintLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 6
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(profileImageView)
        header.addSubview(rightStack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            profileImageView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            profileImageView.topAnchor.constraint(equalTo: header.topAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),

            rightStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            rightStack.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

            header.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor)
        ])
    }

    private func setupForm() {

        let fields: [(String, UITextField, String, String?)] = [
            ("Name", nameField, "Enter name", nil),
            ("Relation", relationField, "Select relation", "chevron.down"),
            ("Emergency Contact Number", emergencyPhoneField, "Emergency phone number", nil),
            ("Date of Birth", dobField, "dd-mm-yyyy", "calendar"),
            ("Gender", genderField, "Select gender", "chevron.down"),
            ("Blood Group", bloodGroupField, "Select blood group", "chevron.down"),
            ("Height", heightField, "Select Height", "chevron.down"),
            ("Weight", weightField, "Select Weight", "chevron.down"),
            ("Existing Diseases", diseasesField, "Select diseases", "chevron.down"),
            ("Existing Medications", medicationField, "Tap to add medications", "chevron.down"),
            ("Address", addressField, "House no, street, area", nil),
            ("Country", countryField, "Select country", "chevron.down"),
            ("State", stateField, "Select state", "chevron.down"),
            ("City", cityField, "Select city", "chevron.down"),
            ("Zip Code", zipField, "Pincode", nil)
        ]

        var topAnchor = contentView.subviews.last!.bottomAnchor

        for item in fields {
            let field = createLabeledField(
                labelText: item.0,
                textField: item.1,
                placeholder: item.2,
                rightIcon: item.3
            )

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
        label.textColor = UIColor(white: 0.15, alpha: 1)
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

    private func setupSaveButton() {

        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: zipField.superview!.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Keyboard & Tap Handling (FROM PROFILE)
    private func configureTapAndKeyboards() {

        emergencyPhoneField.keyboardType = .numberPad

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        [nameField, emergencyPhoneField].forEach {
            addDoneToolbar(to: $0)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func addDoneToolbar(to textField: UITextField) {

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        ]

        textField.inputAccessoryView = toolbar
    }

    // MARK: - DOB Picker
    private func setupDOBPicker() {

        dobPicker.datePickerMode = .date
        dobPicker.maximumDate = Date()

        if #available(iOS 13.4, *) {
            dobPicker.preferredDatePickerStyle = .wheels
        }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dobDone))
        ]

        dobField.inputView = dobPicker
        dobField.inputAccessoryView = toolbar
        dobField.tintColor = .clear
    }

    @objc private func dobDone() {
        dobField.text = dobFormatter.string(from: dobPicker.date)
        dismissKeyboard()
    }

    // MARK: - Dropdowns (REUSED FROM PROFILE)
    private func setupDropdowns() {

        configureDropdown(field: relationField, action: #selector(openRelationSelector))
        configureDropdown(field: genderField, action: #selector(openGenderSelector))
        configureDropdown(field: bloodGroupField, action: #selector(openBloodGroupSelector))
        configureDropdown(field: diseasesField, action: #selector(openDiseaseSelector))
        configureDropdown(field: heightField, action: #selector(openHeightSelector))
        configureDropdown(field: weightField, action: #selector(openWeightSelector))
        configureDropdown(field: medicationField, action: #selector(openMedicationPicker))
        configureDropdown(field: countryField, action: #selector(openCountrySelector))
        configureDropdown(field: stateField, action: #selector(openStateSelector))
        configureDropdown(field: cityField, action: #selector(openCitySelector))
    }

    private func configureDropdown(field: UITextField, action: Selector) {
        field.inputView = UIView()
        field.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
    }

    // MARK: - Dropdown Actions
    @objc private func openRelationSelector() {

        let preselected = relationField.text.map { [$0] } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Select Relation",
            options: relationOptions,
            preselected: preselected,
            maxSelection: 1
        )

        popup.onConfirm = { [weak self] selected in
            self?.relationField.text = selected.first
        }

        present(popup, animated: true)
    }

    @objc private func openGenderSelector() {

        let preselected = genderField.text.map { [$0] } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Select Gender",
            options: genderOptions,
            preselected: preselected,
            maxSelection: 1
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
            maxSelection: 1
        )

        popup.onConfirm = { [weak self] selected in
            self?.bloodGroupField.text = selected.first
        }

        present(popup, animated: true)
    }

    @objc private func openDiseaseSelector() {
        let current = diseasesField.text?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Existing Diseases",
            options: diseases,
            preselected: current,
            maxSelection: 5
        )
        popup.onConfirm = { [weak self] selected in
            self?.diseasesField.text = selected.joined(separator: ", ")
        }
        present(popup, animated: true)
    }

    @objc private func openHeightSelector() {
        let options = (100...250).map { "\($0) CM" }
        let current = heightField.text ?? ""
        let preselected = current.isEmpty ? [] : [current]

        let popup = MultiSelectPopupViewController(
            title: "Select Height",
            options: options,
            preselected: preselected,
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            self?.heightField.text = selected.first
        }
        present(popup, animated: true)
    }

    @objc private func openWeightSelector() {
        let options = (20...200).map { "\($0) KG" }
        let current = weightField.text ?? ""
        let preselected = current.isEmpty ? [] : [current]

        let popup = MultiSelectPopupViewController(
            title: "Select Weight",
            options: options,
            preselected: preselected,
            maxSelection: 1
        )
        popup.onConfirm = { [weak self] selected in
            self?.weightField.text = selected.first
        }
        present(popup, animated: true)
    }

    @objc private func openMedicationPicker() {
        let picker = MedicationPickerViewController(current: selectedMedications)
        picker.onConfirm = { [weak self] entries in
            guard let self = self else { return }
            self.selectedMedications = entries
            self.medicationField.text = MedicationEntry.toString(entries)
        }
        present(picker, animated: true)
    }

    @objc private func openCountrySelector() {
        let options = CountryLocationData.countries.map { $0.name }
        let preselected = (countryField.text ?? "").isEmpty ? [] : [countryField.text!]
        let popup = MultiSelectPopupViewController(title: "Select Country", options: options, preselected: preselected, maxSelection: 1)
        popup.onConfirm = { [weak self] selected in
            guard let self = self, let country = selected.first else { return }
            self.countryField.text = country
            self.stateField.text = ""
            self.cityField.text = ""
            self.selectedCountryCode = CountryLocationData.countryCode(for: country)
        }
        present(popup, animated: true)
    }

    @objc private func openStateSelector() {
        let states = CountryLocationData.states(for: selectedCountryCode)
        guard !states.isEmpty else {
            Toast.show(message: "Please select a country first", in: self.view)
            return
        }
        let preselected = (stateField.text ?? "").isEmpty ? [] : [stateField.text!]
        let popup = MultiSelectPopupViewController(title: "Select State", options: states, preselected: preselected, maxSelection: 1)
        popup.onConfirm = { [weak self] selected in
            guard let self = self, let state = selected.first else { return }
            self.stateField.text = state
            self.cityField.text = ""
        }
        present(popup, animated: true)
    }

    @objc private func openCitySelector() {
        let selectedState = stateField.text ?? ""
        let cities = CountryLocationData.cities(for: selectedCountryCode, state: selectedState)
        guard !cities.isEmpty else {
            Toast.show(message: "Please select a state first", in: self.view)
            return
        }
        let preselected = (cityField.text ?? "").isEmpty ? [] : [cityField.text!]
        let popup = MultiSelectPopupViewController(title: "Select City", options: cities, preselected: preselected, maxSelection: 1)
        popup.onConfirm = { [weak self] selected in
            self?.cityField.text = selected.first
        }
        present(popup, animated: true)
    }

    // MARK: - Actions
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    // MARK: - Mode
    private func configureForMode() {

        switch mode {
        case .add:
            title = "Add Dependent"
            saveButton.setTitle("Add Dependent", for: .normal)

        case .edit(let member):
            title = "Edit Dependent"
            saveButton.setTitle("Update Dependent", for: .normal)
            bindForEdit(member)
        }
    }

    private func bindForEdit(_ member: FamilyMember) {

        nameField.text = member.name
        relationField.text = member.relation
        emergencyPhoneField.text = member.emergency_phone ?? ""

        // DOB — server sends yyyy-MM-dd, display as dd-MM-yyyy
        if let dob = member.dob, !dob.isEmpty {
            let serverFmt = DateFormatter()
            serverFmt.dateFormat = "yyyy-MM-dd"
            let displayFmt = DateFormatter()
            displayFmt.dateFormat = "dd-MM-yyyy"
            if let date = serverFmt.date(from: dob) {
                dobField.text = displayFmt.string(from: date)
                dobPicker.date = date
            } else {
                dobField.text = dob
            }
        }

        if member.gender == "M" {
            genderField.text = "Male"
        } else if member.gender == "F" {
            genderField.text = "Female"
        } else if member.gender == "O" {
            genderField.text = "Other"
        }

        bloodGroupField.text = member.blood_group ?? ""

        if let h = member.height, let val = Double(h) {
            heightField.text = "\(Int(val)) CM"
        } else {
            heightField.text = member.height ?? ""
        }

        if let w = member.weight, let val = Double(w) {
            weightField.text = "\(Int(val)) KG"
        } else {
            weightField.text = member.weight ?? ""
        }

        diseasesField.text = member.existing_diseases ?? ""

        selectedMedications = MedicationEntry.parse(from: member.existing_medications ?? "")
        medicationField.text = MedicationEntry.toString(selectedMedications)

        addressField.text = member.address ?? ""
        countryField.text = member.country ?? ""
        selectedCountryCode = CountryLocationData.countryCode(for: member.country ?? "")
        stateField.text = member.state ?? ""
        cityField.text = member.city ?? ""
        zipField.text = member.pincode ?? ""

        if let urlString = member.dependent_image_url,
           let url = URL(string: urlString) {
            profileImageView.loadImage(from: url)
        }
    }

    // MARK: - Save
    @objc private func saveTapped() {

        guard let name = nameField.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            Toast.show(message: "Please enter a name", in: self.view)
            return
        }

        guard let relation = relationField.text, !relation.trimmingCharacters(in: .whitespaces).isEmpty else {
            Toast.show(message: "Please select a relation", in: self.view)
            return
        }

        guard let gender = genderField.text, !gender.trimmingCharacters(in: .whitespaces).isEmpty else {
            Toast.show(message: "Please select a gender", in: self.view)
            return
        }

        // Map gender to API code
        let genderCode: String
        switch gender {
        case "Male":   genderCode = "M"
        case "Female": genderCode = "F"
        case "Other":  genderCode = "O"
        default:       genderCode = ""
        }

        // DOB — convert dd-MM-yyyy back to yyyy-MM-dd for API
        let apiDob: String
        if let displayDob = dobField.text, !displayDob.isEmpty {
            let displayFmt = DateFormatter()
            displayFmt.dateFormat = "dd-MM-yyyy"
            let apiFmt = DateFormatter()
            apiFmt.dateFormat = "yyyy-MM-dd"
            apiDob = displayFmt.date(from: displayDob).map { apiFmt.string(from: $0) } ?? displayDob
        } else {
            apiDob = ""
        }

        let params: [String: String] = [
            "name": name,
            "relation": relationField.text ?? "",
            "gender": genderCode,
            "dob": apiDob,
            "blood_group": bloodGroupField.text ?? "",
            "emergency_phone": emergencyPhoneField.text ?? "",
            "height": (heightField.text ?? "").replacingOccurrences(of: " CM", with: "").trimmingCharacters(in: .whitespaces),
            "weight": (weightField.text ?? "").replacingOccurrences(of: " KG", with: "").trimmingCharacters(in: .whitespaces),
            "existing_diseases": diseasesField.text ?? "",
            "existing_medications": MedicationEntry.toString(selectedMedications),
            "address": addressField.text ?? "",
            "country": countryField.text ?? "",
            "state": stateField.text ?? "",
            "city": cityField.text ?? "",
            "pincode": zipField.text ?? ""
        ]

        switch mode {
        case .add:
            Loader.shared.show(on: view, message: "Adding Member...", timeout: 5)
            ProfileService.shared.saveFamilyMember(
                userId: loggedInUserId,
                params: params,
                profileImage: compressedImageData,
                completion: handleResponse
            )

        case .edit(let member):
            Loader.shared.show(on: view, message: "Updating Member...", timeout: 5)
            ProfileService.shared.updateFamilyMember(
                userId: loggedInUserId,
                dependentId: member.id,
                params: params,
                profileImage: compressedImageData,
                completion: handleResponse
            )
        }
    }

    private func handleResponse(_ result: Result<AddProfileDataResponse, NetworkError>) {
        DispatchQueue.main.async {
            Loader.shared.hide()

            switch result {
            case .success:
                let message: String

                switch self.mode {
                case .add:
                    message = "Dependent added successfully"
                case .edit:
                    message = "Dependent updated successfully"
                }

                Toast.show(message: message, in: self.view)

                // 🔥 Tell previous screen to refresh
                self.onSuccess?()

                // ⬅️ Go back
                self.navigationController?.popViewController(animated: true)

            case .failure:
                Toast.show(message: "Operation failed. Please try again.", in: self.view)
            }
        }
    }

}

extension FamilyMemberFormViewController:
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {

        picker.dismiss(animated: true)

        let image =
            (info[.editedImage] ?? info[.originalImage]) as? UIImage

        guard let selectedImage = image else { return }

        profileImageView.image = selectedImage

        compressedImageData = selectedImage
            .jpegData(compressionQuality: 0.6)
    }
}


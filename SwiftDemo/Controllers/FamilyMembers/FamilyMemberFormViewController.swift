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

    private let saveButton = UIButton(type: .system)

    // MARK: - Data
    private var compressedImageData: Data?

    private let relationOptions = ["Father", "Mother", "Spouse", "Son", "Daughter", "Sibling", "Other"]
    private let genderOptions = ["Male", "Female"]
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

        view.backgroundColor = UIColor(red: 0.27, green: 0.60, blue: 0.96, alpha: 1)

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

        setupHeader()
        setupForm()
        setupSaveButton()
    }

    private func setupHeader() {

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .white
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
        uploadHintLabel.textColor = .white
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
            ("Date of Birth", dobField, "yyyy-mm-dd", "calendar"),
            ("Gender", genderField, "Select gender", "chevron.down"),
            ("Blood Group", bloodGroupField, "Select blood group", "chevron.down"),
            ("Existing Diseases", diseasesField, "Select diseases", "chevron.down"),
            ("Existing Medications", medicationField, "Enter medication", nil)
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

    private func setupSaveButton() {

        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.56, green: 0.93, blue: 0.80, alpha: 1)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: medicationField.superview!.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Keyboard & Tap Handling (FROM PROFILE)
    private func configureTapAndKeyboards() {

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        [nameField, medicationField].forEach {
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

        let preselected = diseasesField.text?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []

        let popup = MultiSelectPopupViewController(
            title: "Select Diseases",
            options: diseases,
            preselected: preselected,
            maxSelection: 4
        )

        popup.onConfirm = { [weak self] selected in
            self?.diseasesField.text = selected.joined(separator: ", ")
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
        dobField.text = member.dob
        genderField.text = member.gender == "M" ? "Male" : "Female"
        bloodGroupField.text = member.blood_group
        diseasesField.text = member.existing_diseases
        medicationField.text = member.existing_medications

        if let urlString = member.dependent_image_url,
           let url = URL(string: urlString) {
            profileImageView.loadImage(from: url)
        }
    }

    // MARK: - Save
    @objc private func saveTapped() {

        let params: [String: String] = [
            "name": nameField.text ?? "",
            "relation": relationField.text ?? "",
            "gender": genderField.text == "Male" ? "M" : "F",
            "dob": dobField.text ?? "",
            "blood_group": bloodGroupField.text ?? "",
            "existing_diseases": diseasesField.text ?? "",
            "existing_medications": medicationField.text ?? "",
            "emergency_phone": ""
        ]

        switch mode {
        case .add:
            ProfileService.shared.saveFamilyMember(
                userId: loggedInUserId,
                params: params,
                profileImage: compressedImageData,
                completion: handleResponse
            )

        case .edit(let member):
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


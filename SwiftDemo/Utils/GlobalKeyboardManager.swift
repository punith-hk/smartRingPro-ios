import UIKit

/// Automatically adds a "Done" toolbar button to any UITextField
/// whose keyboard type is a number/phone/decimal pad — app-wide.
final class GlobalKeyboardManager {

    static let shared = GlobalKeyboardManager()
    private init() {}

    private let numberPadTypes: [UIKeyboardType] = [
        .numberPad,
        .phonePad,
        .decimalPad,
        .asciiCapableNumberPad
    ]

    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidBeginEditing(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )
    }

    @objc private func textFieldDidBeginEditing(_ notification: Notification) {
        guard
            let textField = notification.object as? UITextField,
            numberPadTypes.contains(textField.keyboardType),
            textField.inputAccessoryView == nil
        else { return }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: textField,
            action: #selector(UIResponder.resignFirstResponder)
        )
        toolbar.items = [spacer, done]
        textField.inputAccessoryView = toolbar
        textField.reloadInputViews()
    }
}

import UIKit

class HelpSupportViewController: AppBaseViewController {

    private let placeholderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Help & Support"
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

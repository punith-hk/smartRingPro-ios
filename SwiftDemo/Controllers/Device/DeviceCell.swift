import UIKit

class DeviceCell: UITableViewCell {

    static let identifier = "DeviceCell"

    // MARK: - UI
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let macLabel = UILabel()
    private let statusLabel = UILabel()
    private let signalLabel = UILabel()
    private let connectButton = UIButton(type: .system)
    private let rawLabel = UILabel()
    private let dividerView = UIView()

    // MARK: - Callbacks
    var onConnectTapped: (() -> Void)?
    var onRawTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {

        selectionStyle = .none
        backgroundColor = .clear

        // Icon
        iconView.image = UIImage(systemName: "antenna.radiowaves.left.and.right")
        iconView.tintColor = .black
        iconView.contentMode = .scaleAspectFit

        // Labels
        nameLabel.font = .boldSystemFont(ofSize: 16)
        macLabel.font = .systemFont(ofSize: 13)
        macLabel.textColor = .darkGray

        statusLabel.font = .systemFont(ofSize: 12)
        signalLabel.font = .systemFont(ofSize: 12)

        // Connect Button (NOW CLICKABLE)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.setTitleColor(.black, for: .normal)
        connectButton.backgroundColor = UIColor(
            red: 0.6, green: 0.95, blue: 0.8, alpha: 1
        )
        connectButton.layer.cornerRadius = 8
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)

        // RAW label
        rawLabel.font = .systemFont(ofSize: 10, weight: .light)
        rawLabel.textColor = .white
        rawLabel.textAlignment = .center
        rawLabel.isUserInteractionEnabled = true

        let attr = NSAttributedString(
            string: "RAW",
            attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]
        )
        rawLabel.attributedText = attr

        let rawTap = UITapGestureRecognizer(target: self, action: #selector(rawTapped))
        rawLabel.addGestureRecognizer(rawTap)

        // Divider
        dividerView.backgroundColor = UIColor.black.withAlphaComponent(0.15)

        // Add subviews
        [
            iconView,
            nameLabel,
            macLabel,
            statusLabel,
            signalLabel,
            connectButton,
            rawLabel,
            dividerView
        ].forEach { contentView.addSubview($0) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        iconView.frame = CGRect(x: 16, y: 22, width: 28, height: 28)

        nameLabel.frame = CGRect(x: 56, y: 10, width: 180, height: 22)
        macLabel.frame = CGRect(x: 56, y: 32, width: 200, height: 18)

        statusLabel.frame = CGRect(x: 56, y: 52, width: 120, height: 16)
        signalLabel.frame = CGRect(x: 180, y: 52, width: 80, height: 16)

        connectButton.frame = CGRect(
            x: contentView.bounds.width - 92,
            y: 18,
            width: 76,
            height: 32
        )

        rawLabel.frame = CGRect(
            x: contentView.bounds.width - 92,
            y: connectButton.frame.maxY + 2,
            width: 76,
            height: 16
        )

        dividerView.frame = CGRect(
            x: 16,
            y: contentView.bounds.height - 1,
            width: contentView.bounds.width - 32,
            height: 1
        )
    }

    func configure(with device: ScannedDevice) {
        nameLabel.text = device.name
        macLabel.text = device.mac
        statusLabel.text = "NOT BONDED"
        signalLabel.text = "▲ -71"
    }

    // MARK: - Actions

    @objc private func connectTapped() {
        onConnectTapped?()
    }

    @objc private func rawTapped() {
        onRawTapped?()
    }
}

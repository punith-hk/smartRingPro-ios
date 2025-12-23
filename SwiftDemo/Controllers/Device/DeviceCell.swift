import UIKit

class DeviceCell: UITableViewCell {

    static let identifier = "DeviceCell"

    private let nameLabel = UILabel()
    private let macLabel = UILabel()
    private let connectButton = UIButton(type: .system)

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

        nameLabel.font = .boldSystemFont(ofSize: 18)
        macLabel.font = .systemFont(ofSize: 14)
        macLabel.textColor = .darkGray

        connectButton.setTitle("Connect", for: .normal)
        connectButton.setTitleColor(.black, for: .normal)
        connectButton.backgroundColor = UIColor(red: 0.6, green: 0.95, blue: 0.8, alpha: 1)
        connectButton.layer.cornerRadius = 16
        connectButton.isUserInteractionEnabled = false // tap whole cell

        contentView.addSubview(nameLabel)
        contentView.addSubview(macLabel)
        contentView.addSubview(connectButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.frame = CGRect(x: 20, y: 12, width: 180, height: 24)
        macLabel.frame = CGRect(x: 20, y: 40, width: 220, height: 20)
        connectButton.frame = CGRect(
            x: contentView.bounds.width - 100,
            y: 22,
            width: 80,
            height: 32
        )
    }

    func configure(with device: ScannedDevice) {
        nameLabel.text = device.name
        macLabel.text = device.mac
    }
}

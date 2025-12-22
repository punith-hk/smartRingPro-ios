import UIKit

class HealthDashboardViewController: AppBaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let gridStack = UIStackView()

    override func viewDidLoad() {
            super.viewDidLoad()
        setupUI()
        setupVitals()

        }

    private func setupUI() {

        navigationItem.title = "Health"

        view.backgroundColor = UIColor(
            red: 0.27, green: 0.60, blue: 0.96, alpha: 1.0
        )

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

        gridStack.axis = .vertical
        gridStack.spacing = 16
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            gridStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            gridStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gridStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            gridStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupVitals() {

        let rows = [
            createRow(
                left: VitalCardView(
                    icon: UIImage(systemName: "flame"),
                    title: "Calories",
                    value: "0 kcal"
                ),
                right: VitalCardView(
                    icon: UIImage(systemName: "bed.double"),
                    title: "Sleep",
                    value: "0h 0m"
                )
            ),
            createRow(
                left: VitalCardView(
                    icon: UIImage(systemName: "heart"),
                    title: "Heart Rate",
                    value: "0 bpm"
                ),
                right: VitalCardView(
                    icon: UIImage(systemName: "drop"),
                    title: "Blood Oxygen",
                    value: "0%"
                )
            ),
            createRow(
                left: VitalCardView(
                    icon: UIImage(systemName: "waveform.path.ecg"),
                    title: "Blood Pressure",
                    value: "--/-- mmHg"
                ),
                right: VitalCardView(
                    icon: UIImage(systemName: "thermometer"),
                    title: "Temperature",
                    value: "0°C"
                )
            )
        ]

        rows.forEach { gridStack.addArrangedSubview($0) }
    }

    private func createRow(left: UIView, right: UIView) -> UIStackView {

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal
        row.spacing = 16
        row.distribution = .fillEqually

        return row
    }
}

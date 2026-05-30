import UIKit

/// Single source of truth for colors, fonts, and common UI styles.
/// Use these instead of defining raw values in each view controller.
enum AppTheme {

    // MARK: - Colors

    /// Standard screen background — light blue (#D9EDFF)
    static let background    = UIColor(red: 217/255, green: 237/255, blue: 255/255, alpha: 1)
    /// Navigation bar / header — deep navy (#15558D)
    static let navBlue       = UIColor(red: 21/255,  green: 85/255,  blue: 141/255, alpha: 1)
    /// Primary action color — bright blue (#0D99FF)
    static let primaryBlue   = UIColor(red: 13/255,  green: 153/255, blue: 255/255, alpha: 1)
    /// Card / surface background
    static let cardBackground = UIColor.white
    /// Primary text
    static let textPrimary   = UIColor.black
    /// Secondary / muted text
    static let textSecondary = UIColor.darkGray
    /// Subtle divider line
    static let divider       = UIColor.black.withAlphaComponent(0.15)

    // MARK: - Fonts

    static func titleFont(size: CGFloat = 16) -> UIFont {
        .systemFont(ofSize: size, weight: .bold)
    }

    static func bodyFont(size: CGFloat = 14) -> UIFont {
        .systemFont(ofSize: size)
    }

    static func captionFont(size: CGFloat = 12) -> UIFont {
        .systemFont(ofSize: size)
    }

    // MARK: - Reusable Styling Helpers

    /// Apply standard card appearance (white bg, rounded corners, subtle shadow).
    static func styleCard(_ view: UIView, cornerRadius: CGFloat = 16) {
        view.backgroundColor = cardBackground
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor  = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.10
        view.layer.shadowOffset  = CGSize(width: 0, height: 4)
        view.layer.shadowRadius  = 8
        view.layer.masksToBounds = false
    }

    /// Apply standard primary-action button appearance (blue bg, white text, pill shape).
    static func stylePrimaryButton(_ button: UIButton, title: String, cornerRadius: CGFloat = 22) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = primaryBlue
        button.titleLabel?.font = titleFont(size: 16)
        button.layer.cornerRadius = cornerRadius
    }
}

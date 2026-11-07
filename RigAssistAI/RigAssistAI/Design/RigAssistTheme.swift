import SwiftUI

/// Central visual design system for RigAssist AI.
///
/// Colors, spacing, corner radii, and other shared styling values
/// are defined here so the Calculator, Reference, and Ask AI
/// interfaces maintain a consistent appearance.
enum RigAssistTheme {

    // MARK: - Colors

    /// Primary dark navy used for headers and major interface elements.
    static let navy = Color(
        red: 20 / 255,
        green: 35 / 255,
        blue: 52 / 255
    )

    /// Safety-inspired orange used for primary actions and highlights.
    static let safetyOrange = Color(
        red: 238 / 255,
        green: 126 / 255,
        blue: 34 / 255
    )

    /// Light application background.
    static let background = Color(
        red: 244 / 255,
        green: 246 / 255,
        blue: 248 / 255
    )

    /// Background used for cards containing user controls.
    static let cardBackground = Color.white

    /// Primary text used throughout the application.
    static let primaryText = Color(
        red: 25 / 255,
        green: 31 / 255,
        blue: 38 / 255
    )

    /// Secondary explanatory text.
    static let secondaryText = Color.secondary

    /// Safety and validation warning color.
    static let warning = Color.red

    // MARK: - Layout

    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let cardCornerRadius: CGFloat = 18
    static let controlCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 18
}

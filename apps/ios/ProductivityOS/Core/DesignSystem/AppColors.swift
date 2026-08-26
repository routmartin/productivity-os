import SwiftUI

/// Approved design system colors matching `today.png` and `focsu-flow.png`
public enum AppColors {
    // MARK: - Light Mode Canvas & Surfaces
    /// Soft lavender-tinted canvas background
    public static let canvas = Color(hex: "F8F7FC")
    /// Secondary slightly deeper canvas background for cards and contrast
    public static let canvasSecondary = Color(hex: "F0EEF8")
    /// Pure white surface for primary elevated cards
    public static let surface = Color.white
    /// Subtle card border stroke
    public static let surfaceBorder = Color(hex: "ECEAF4")
    
    // MARK: - Brand & Accents
    /// Primary vibrant purple accent
    public static let primary = Color(hex: "6C47FF")
    /// Deeper purple for pressed/active states
    public static let primaryDark = Color(hex: "5832E6")
    /// Soft purple tint for badges, subtle backgrounds, and pill indicators
    public static let primaryTint = Color(hex: "F2EFFF")
    /// Vibrant purple gradient for hero buttons
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "7C5CFC"), Color(hex: "5E37F5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Text & Content
    /// Primary high-contrast text color
    public static let textPrimary = Color(hex: "111026")
    /// Secondary medium-contrast text color
    public static let textSecondary = Color(hex: "63627A")
    /// Tertiary / muted placeholder text color
    public static let textTertiary = Color(hex: "9A99AA")
    
    // MARK: - Priority Pills (Approved Design Reference)
    /// High priority badge background (soft coral/red tint)
    public static let priorityHighBackground = Color(hex: "FEE4E2")
    /// High priority badge foreground text
    public static let priorityHighText = Color(hex: "D92D20")
    
    /// Medium priority badge background (soft amber/orange tint)
    public static let priorityMediumBackground = Color(hex: "FEF0C7")
    /// Medium priority badge foreground text
    public static let priorityMediumText = Color(hex: "B54708")
    
    /// Low priority badge background (soft blue tint)
    public static let priorityLowBackground = Color(hex: "E0F2FE")
    /// Low priority badge foreground text
    public static let priorityLowText = Color(hex: "026AA2")
    
    // MARK: - Focus Mode Environment (Deep Navy & Glowing Accents)
    /// Deep dark navy background for active focus
    public static let focusCanvas = Color(hex: "08071A")
    /// Secondary dark background for focus controls and cards
    public static let focusSurface = Color(hex: "12102B")
    /// Focus card border
    public static let focusSurfaceBorder = Color(hex: "231F4F")
    /// Focus control button circular background
    public static let focusControlBackground = Color(hex: "1A173B")
    /// Focus control button active primary
    public static let focusControlPrimary = Color(hex: "6C47FF")
    
    /// Glowing Focus ring gradient
    public static let focusRingGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(hex: "6C47FF"),
            Color(hex: "9B7BF7"),
            Color(hex: "C4B5FD"),
            Color(hex: "7C5CFC"),
            Color(hex: "6C47FF")
        ]),
        center: .center
    )
    
    /// Unfilled focus ring track color
    public static let focusRingTrack = Color(hex: "1C193F")
}

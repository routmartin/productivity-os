import SwiftUI

/// Approved design system typography scales matching `today.png` and `focsu-flow.png`
public enum AppTypography {
    /// Large display title for screen headers (e.g. "Good afternoon, Rout.", "Ready to focus?")
    public static let largeTitle = Font.system(size: 26, weight: .bold, design: .rounded)
    
    /// Screen & Section titles (e.g. "FOCUS", "Today's Intention")
    public static let title = Font.system(size: 20, weight: .bold, design: .rounded)
    
    /// Card headlines (e.g. "Protect your attention. Focus on what matters now.")
    public static let headline = Font.system(size: 16, weight: .bold, design: .default)
    
    /// Subhead typography (e.g. "What deserves your attention?", "Productivity OS")
    public static let subheadline = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Regular body text
    public static let body = Font.system(size: 14, weight: .regular, design: .default)
    
    /// Section headers with tracking (e.g. "YOUR TOP 3", "FOCUS DURATION", "SELECTED TASK")
    public static let sectionHeader = Font.system(size: 12, weight: .bold, design: .rounded)
    
    /// Small label / pill text (e.g. "High", "Pomodoro", "Sessions")
    public static let caption = Font.system(size: 12, weight: .medium, design: .default)
    public static let captionSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    /// Big Hero Timer digits (e.g. "42:18", "2h 18m")
    public static let heroTimer = Font.system(size: 52, weight: .bold, design: .rounded)
    public static let miniTimer = Font.system(size: 24, weight: .bold, design: .rounded)
    
    /// Number badge (e.g. "01", "02", "03")
    public static let numberBadge = Font.system(size: 15, weight: .bold, design: .rounded)
}

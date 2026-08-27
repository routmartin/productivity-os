import SwiftUI

/// Shared motion tokens (docs/specs/ui/motion-and-animation.md).
/// Micro interactions ~150ms, standard transitions ~300ms,
/// large transitions 300-500ms. Focus mode targets 300-450ms.
public enum AppMotion {
    /// Micro interaction feedback (button press, chip selection).
    public static let micro = Animation.easeOut(duration: 0.15)

    /// Standard state transition (pause/resume, ring color changes).
    public static let standard = Animation.easeInOut(duration: 0.3)

    /// Large connected transition (Preparation -> Active -> Completion).
    public static let large = Animation.easeInOut(duration: 0.45)

    /// Linear cadence for the progress ring between timestamp-derived values.
    public static let ringTick = Animation.linear(duration: 0.5)
}

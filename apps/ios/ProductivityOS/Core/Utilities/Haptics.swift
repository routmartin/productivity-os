#if canImport(UIKit)
import UIKit
#endif

/// Subtle, intentional haptics for the Focus experience
/// (docs/specs/ios/focus-experience.md §16).
/// Never called during periodic timer updates.
public enum Haptics {
    /// Light feedback for Start / Pause / Resume.
    public static func light() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    /// Success-style feedback for session completion.
    public static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

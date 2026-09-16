import Foundation

/// Focus session duration. Matches the web/app preset list used when creating
/// a task: 15 / 30 / 45 / 60 / 90 / 120 minutes, plus "No estimate" (unlimited).
///
/// `totalSeconds` is `nil` for unlimited sessions and `seconds * 60` otherwise.
/// The default selected duration on the focus preparation screen is derived
/// from the selected task's `estimatedDurationMinutes` so iOS, web and the
/// API stay in sync.
public struct FocusDuration: Hashable, Codable, Identifiable, Sendable {
    public let totalSeconds: Int?

    public init(totalSeconds: Int?) {
        self.totalSeconds = totalSeconds
    }

    /// No preset timer / open-ended session (maps to `configuredDurationSeconds = nil`).
    public static let unlimited = FocusDuration(totalSeconds: nil)

    /// Canonical presets shared with the web/API task estimate menu.
    public static let presets: [FocusDuration] = [
        .init(totalSeconds: 15 * 60),
        .init(totalSeconds: 30 * 60),
        .init(totalSeconds: 45 * 60),
        .init(totalSeconds: 60 * 60),
        .init(totalSeconds: 90 * 60),
        .init(totalSeconds: 120 * 60)
    ]

    /// True when this duration was constructed from a known preset value
    /// (i.e. the user can round-trip back to one of the chips).
    public var isPreset: Bool {
        guard let totalSeconds else { return true }
        return Self.presets.contains { $0.totalSeconds == totalSeconds }
    }

    public var isUnlimited: Bool {
        totalSeconds == nil
    }

    public var id: String {
        totalSeconds.map(String.init) ?? "unlimited"
    }

    /// Short label rendered on the focus preparation chips
    /// (e.g. "15m", "1h 30m", "No estimate").
    public var title: String {
        guard let totalSeconds else { return "" }
        return Self.format(minutes: totalSeconds / 60)
    }

    /// Optional secondary label rendered under the chip title.
    public var subtitle: String {
        guard let totalSeconds else { return "Unlimited" }
        let minutes = totalSeconds / 60
        switch minutes {
        case 15: return "Quick focus"
        case 30: return "Short sprint"
        case 45: return "Deep work"
        case 60: return "Focused"
        case 90: return "Long block"
        case 120: return "Marathon"
        default: return Self.format(minutes: minutes)
        }
    }

    /// Returns the preset matching the supplied estimate in minutes, or
    /// `unlimited` when the estimate is `nil`/non-positive. Used to keep the
    /// focus preparation screen in sync with the task's API value.
    public static func fromEstimatedMinutes(_ minutes: Int?) -> FocusDuration {
        guard let minutes, minutes > 0 else { return .unlimited }
        if let match = presets.first(where: { $0.totalSeconds == minutes * 60 }) {
            return match
        }
        return .unlimited
    }

    /// Inverse of `fromEstimatedMinutes`: rounds seconds back to one of the
    /// preset values when possible (used when restoring an active session).
    public static func fromSeconds(_ seconds: Int?) -> FocusDuration {
        guard let seconds, seconds > 0 else { return .unlimited }
        if let match = presets.first(where: { $0.totalSeconds == seconds }) {
            return match
        }
        return FocusDuration(totalSeconds: seconds)
    }

    /// Shared minute-to-string formatter (e.g. 45 → "45m", 90 → "1h 30m").
    public static func format(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

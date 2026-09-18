#if os(iOS)
import ActivityKit
import Foundation

/// Shared ActivityKit contract for the Focus session Live Activity.
///
/// This file is compiled into both the app target and the
/// `FocusLiveActivity` widget extension so both sides agree on the payload.
/// It is guarded by `os(iOS)` so the macOS companion and the SwiftPM test
/// target, which compile the same sources, stay unaffected.
public struct FocusActivityAttributes: ActivityAttributes {
    /// Dynamic, per-update content. The widget derives its countdown and
    /// progress from these absolute timestamps — no per-second updates and no
    /// push tokens are required.
    public struct ContentState: Codable, Hashable {
        /// True while the session is paused. The widget freezes the clock and
        /// shows the paused affordance instead of a live timer.
        public var isPaused: Bool

        /// Anchor used to render the running timer.
        /// - Fixed sessions: `timerEndDate - total`, so progress is correct
        ///   after pauses.
        /// - Unlimited sessions: `now - elapsed`.
        public var timerStartDate: Date

        /// Absolute end of a fixed-duration session. `nil` for unlimited.
        public var timerEndDate: Date?

        /// Configured duration in seconds for fixed sessions; `nil` unlimited.
        public var totalDurationSeconds: Int?

        /// Frozen remaining seconds while paused (fixed sessions only).
        public var pausedRemainingSeconds: Int?

        /// Frozen elapsed seconds while paused (unlimited sessions only).
        public var pausedElapsedSeconds: Int?

        public init(
            isPaused: Bool,
            timerStartDate: Date,
            timerEndDate: Date? = nil,
            totalDurationSeconds: Int? = nil,
            pausedRemainingSeconds: Int? = nil,
            pausedElapsedSeconds: Int? = nil
        ) {
            self.isPaused = isPaused
            self.timerStartDate = timerStartDate
            self.timerEndDate = timerEndDate
            self.totalDurationSeconds = totalDurationSeconds
            self.pausedRemainingSeconds = pausedRemainingSeconds
            self.pausedElapsedSeconds = pausedElapsedSeconds
        }
    }

    /// Immutable identity of the session being tracked.
    public var taskTitle: String
    public var projectName: String?

    public init(taskTitle: String, projectName: String? = nil) {
        self.taskTitle = taskTitle
        self.projectName = projectName
    }
}

/// `mm:ss` / `hh:mm:ss` formatting shared by the widget's paused state.
public enum FocusActivityClock {
    public static func text(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
#endif

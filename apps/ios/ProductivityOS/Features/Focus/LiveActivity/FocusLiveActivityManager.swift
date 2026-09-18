#if os(iOS)
import ActivityKit
import Foundation

/// Owns the Focus session Live Activity lifecycle.
///
/// Local-only by design: the app starts, updates and ends the activity, while
/// the widget derives its countdown/progress from absolute timestamps embedded
/// in `FocusActivityAttributes.ContentState`. No push tokens, no backend
/// contract, and no per-second updates.
///
/// Guarded by `os(iOS)` so the macOS companion and SwiftPM test target compile
/// the same sources without ActivityKit.
final class FocusLiveActivityManager {
    static let shared = FocusLiveActivityManager()

    private var activity: Activity<FocusActivityAttributes>?

    private init() {}

    /// Starts (or restarts) the Live Activity for a running/paused session.
    /// Any activity left over from a previous run is ended first so stale
    /// timers never linger on the Lock Screen.
    func start(taskTitle: String, projectName: String?, state: FocusSessionState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAllActivities()

        let attributes = FocusActivityAttributes(
            taskTitle: taskTitle,
            projectName: projectName
        )
        let content = ActivityContent(
            state: contentState(from: state),
            staleDate: nil
        )

        do {
            activity = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("[FocusLiveActivity] start failed: \(error)")
        }
    }

    /// Pushes a new state (e.g. pause / resume) to the running activity.
    func update(state: FocusSessionState) {
        guard let activity else { return }
        let content = ActivityContent(
            state: contentState(from: state),
            staleDate: nil
        )
        Task { await activity.update(content) }
    }

    /// Ends every Focus activity immediately (completion, cancel, reset and
    /// stale-cleanup paths). Ends all, not just the tracked one, so a session
    /// orphaned by a previous app run cannot linger.
    func end() {
        activity = nil
        endAllActivities()
    }

    // MARK: - Content state

    private func contentState(from state: FocusSessionState) -> FocusActivityAttributes.ContentState {
        let now = Date()
        let isPaused = state.state == .paused
        let elapsed = state.elapsedSeconds(at: now)

        if state.configuredDuration.isUnlimited {
            return FocusActivityAttributes.ContentState(
                isPaused: isPaused,
                timerStartDate: now.addingTimeInterval(-elapsed),
                timerEndDate: nil,
                totalDurationSeconds: nil,
                pausedRemainingSeconds: nil,
                pausedElapsedSeconds: isPaused ? Int(elapsed) : nil
            )
        }

        let total = state.configuredDuration.totalSeconds ?? 0
        let remaining = state.remainingSeconds(at: now) ?? 0
        let endDate = now.addingTimeInterval(remaining)
        return FocusActivityAttributes.ContentState(
            isPaused: isPaused,
            timerStartDate: endDate.addingTimeInterval(-TimeInterval(total)),
            timerEndDate: endDate,
            totalDurationSeconds: total,
            pausedRemainingSeconds: isPaused ? Int(remaining) : nil,
            pausedElapsedSeconds: nil
        )
    }

    // MARK: - Cleanup

    private func endAllActivities() {
        let current = Activity<FocusActivityAttributes>.activities
        guard !current.isEmpty else { return }
        Task {
            for activity in current {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
#endif

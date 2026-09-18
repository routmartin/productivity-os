import ActivityKit
import SwiftUI
import WidgetKit

/// Local color mirror of `AppColors` focus tokens. Kept literal so the widget
/// extension does not need to compile the app's design system.
enum FocusWidgetColors {
    static let canvas = Color(red: 8 / 255, green: 7 / 255, blue: 26 / 255)
    static let surface = Color(red: 18 / 255, green: 16 / 255, blue: 43 / 255)
    static let accent = Color(red: 108 / 255, green: 71 / 255, blue: 255 / 255)
    static let secondaryText = Color.white.opacity(0.62)
}

struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLockScreenView(context: context)
                .activityBackgroundTint(FocusWidgetColors.canvas)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.projectName ?? "Focus")
                            .font(.caption2)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    FocusTimerText(state: context.state, size: 20)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.taskTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        FocusProgressView(state: context.state)
                        if context.state.isPaused {
                            Text("PAUSED")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(FocusWidgetColors.secondaryText)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(FocusWidgetColors.accent)
            } compactTrailing: {
                FocusTimerText(state: context.state, size: 15)
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(FocusWidgetColors.accent)
            }
            .widgetURL(URL(string: "productivityos://focus"))
            .keylineTint(FocusWidgetColors.accent)
        }
    }
}

// MARK: - Lock Screen

private struct FocusLockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var state: FocusActivityAttributes.ContentState { context.state }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.title2)
                    .foregroundStyle(FocusWidgetColors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.taskTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(FocusWidgetColors.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                FocusTimerText(state: state, size: 34)
            }

            FocusProgressView(state: state)
        }
        .padding(16)
    }

    private var statusLabel: String {
        if state.isPaused { return "Paused" }
        if let project = context.attributes.projectName { return project }
        return "Focus session"
    }
}

// MARK: - Shared pieces

private struct FocusTimerText: View {
    let state: FocusActivityAttributes.ContentState
    let size: CGFloat

    var body: some View {
        Group {
            if state.isPaused {
                Text(FocusActivityClock.text(seconds: frozenSeconds))
            } else if let end = state.timerEndDate {
                Text(timerInterval: state.timerStartDate...end, countsDown: true)
            } else {
                Text(
                    timerInterval: state.timerStartDate...state.timerStartDate.addingTimeInterval(24 * 3600),
                    countsDown: false
                )
            }
        }
        .font(.system(size: size, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    private var frozenSeconds: Int {
        state.pausedRemainingSeconds ?? state.pausedElapsedSeconds ?? 0
    }
}

private struct FocusProgressView: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isPaused {
                ProgressView(value: pausedProgress)
            } else if let end = state.timerEndDate {
                ProgressView(timerInterval: state.timerStartDate...end, countsDown: true)
            } else {
                ProgressView(
                    timerInterval: state.timerStartDate...state.timerStartDate.addingTimeInterval(3600),
                    countsDown: false
                )
            }
        }
        .tint(FocusWidgetColors.accent)
    }

    private var pausedProgress: Double {
        guard let total = state.totalDurationSeconds, total > 0 else {
            let elapsed = state.pausedElapsedSeconds ?? 0
            return Double(elapsed % 3600) / 3600.0
        }
        let remaining = state.pausedRemainingSeconds ?? total
        return Double(total - remaining) / Double(total)
    }
}

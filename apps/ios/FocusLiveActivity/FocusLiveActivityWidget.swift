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

    static let divider = Color.white.opacity(0.08)

    static let priorityHighBackground = Color(red: 254 / 255, green: 228 / 255, blue: 226 / 255)
    static let priorityHighText = Color(red: 217 / 255, green: 45 / 255, blue: 32 / 255)
    static let priorityMediumBackground = Color(red: 254 / 255, green: 240 / 255, blue: 199 / 255)
    static let priorityMediumText = Color(red: 181 / 255, green: 71 / 255, blue: 8 / 255)
    static let priorityLowBackground = Color(red: 224 / 255, green: 242 / 255, blue: 254 / 255)
    static let priorityLowText = Color(red: 2 / 255, green: 106 / 255, blue: 162 / 255)
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

// MARK: - Home Screen widget

/// Home Screen widget showing the user's latest tasks.
///
/// It renders a snapshot the app writes to the shared App Group container
/// (`FocusWidgetShared`) — the extension never fetches or authenticates on its
/// own. The app reloads the timeline whenever the task list changes.
struct FocusHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FocusHomeWidget.kind, provider: FocusHomeWidgetProvider()) { entry in
            FocusHomeWidgetView(tasks: entry.tasks, updatedAt: entry.updatedAt)
                .containerBackground(FocusWidgetColors.canvas, for: .widget)
        }
        .configurationDisplayName("Tasks")
        .description("Your latest tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    static let kind = FocusWidgetShared.kind
}

struct FocusHomeWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [FocusWidgetTask]
    let updatedAt: Date?

    var hasSynced: Bool { updatedAt != nil }
}

struct FocusHomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusHomeWidgetEntry {
        FocusHomeWidgetEntry(date: Date(), tasks: FocusWidgetTask.placeholders, updatedAt: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusHomeWidgetEntry) -> Void) {
        let snapshot = FocusWidgetSnapshot.load()
        completion(FocusHomeWidgetEntry(
            date: Date(),
            tasks: context.isPreview ? FocusWidgetTask.placeholders : (snapshot?.tasks ?? []),
            updatedAt: context.isPreview ? Date() : snapshot?.updatedAt
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusHomeWidgetEntry>) -> Void) {
        let snapshot = FocusWidgetSnapshot.load()
        let entry = FocusHomeWidgetEntry(
            date: Date(),
            tasks: snapshot?.tasks ?? [],
            updatedAt: snapshot?.updatedAt
        )
        // The app reloads timelines explicitly after each sync; no polling.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct FocusHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let tasks: [FocusWidgetTask]
    let updatedAt: Date?

    private var visibleTasks: [FocusWidgetTask] {
        Array(tasks.prefix(family == .systemSmall ? 1 : FocusWidgetSnapshot.maxTasks))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if visibleTasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleTasks.enumerated()), id: \.element.id) { index, task in
                        FocusWidgetTaskRow(task: task)
                        if index < visibleTasks.count - 1 {
                            Divider().overlay(FocusWidgetColors.divider)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "productivityos://today"))
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "checklist")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FocusWidgetColors.accent)
            Text("LATEST")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(FocusWidgetColors.secondaryText)
            Spacer(minLength: 0)
            if let updatedAt {
                Text(updatedAt, style: .relative)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(FocusWidgetColors.secondaryText)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 3) {
            Spacer(minLength: 0)
            Text(updatedAt == nil ? "Open the app to sync" : "No active tasks")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Text(updatedAt == nil ? "Your tasks will show up here." : "Clear runway for now.")
                .font(.system(size: 10))
                .foregroundStyle(FocusWidgetColors.secondaryText)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Task row

/// Clean, single-line task row for the widget. Uses the local color mirror so
/// the extension stays independent from the app's design system.
private struct FocusWidgetTaskRow: View {
    let task: FocusWidgetTask

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(style.background)
                    .frame(width: 26, height: 26)
                Image(systemName: task.isCompleted ? "checkmark" : "flag.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(style.foreground)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? FocusWidgetColors.secondaryText : .white)
                    .strikethrough(task.isCompleted, color: FocusWidgetColors.secondaryText)
                    .lineLimit(1)
                if let project = task.projectName, !project.isEmpty {
                    Text(project)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(FocusWidgetColors.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let title = style.title {
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(style.background))
                    .foregroundStyle(style.foreground)
            }
        }
        .padding(.vertical, 6)
    }

    private var style: (background: Color, foreground: Color, title: String?) {
        switch task.priority?.uppercased() {
        case "HIGH":
            return (FocusWidgetColors.priorityHighBackground, FocusWidgetColors.priorityHighText, "HIGH")
        case "MEDIUM":
            return (FocusWidgetColors.priorityMediumBackground, FocusWidgetColors.priorityMediumText, "MED")
        case "LOW":
            return (FocusWidgetColors.priorityLowBackground, FocusWidgetColors.priorityLowText, "LOW")
        default:
            return (FocusWidgetColors.accent.opacity(0.18), FocusWidgetColors.accent, nil)
        }
    }
}

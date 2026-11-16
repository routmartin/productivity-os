import SwiftUI

/// Time-Sticky Anchor Card answering "What should I do right now?" and "What time is it?".
/// Positioned at the top of the Today tasks view.
public struct TimeAnchorCardView: View {
    public let upNextTask: TaskItem?
    public let isSessionActive: Bool
    public let isSessionPaused: Bool
    public let activeTaskTitle: String?
    public let remainingTimeText: String?
    public let isPlateClear: Bool
    public let onStartFocus: (TaskItem) -> Void
    public let onResumeFocus: () -> Void
    public let onBrowseBacklog: () -> Void

    public init(
        upNextTask: TaskItem? = nil,
        isSessionActive: Bool = false,
        isSessionPaused: Bool = false,
        activeTaskTitle: String? = nil,
        remainingTimeText: String? = nil,
        isPlateClear: Bool = false,
        onStartFocus: @escaping (TaskItem) -> Void = { _ in },
        onResumeFocus: @escaping () -> Void = {},
        onBrowseBacklog: @escaping () -> Void = {}
    ) {
        self.upNextTask = upNextTask
        self.isSessionActive = isSessionActive
        self.isSessionPaused = isSessionPaused
        self.activeTaskTitle = activeTaskTitle
        self.remainingTimeText = remainingTimeText
        self.isPlateClear = isPlateClear
        self.onStartFocus = onStartFocus
        self.onResumeFocus = onResumeFocus
        self.onBrowseBacklog = onBrowseBacklog
    }

    public init(
        focusViewModel: FocusSessionViewModel?,
        upNextTask: TaskItem?,
        isPlateClear: Bool,
        onStartFocus: @escaping (TaskItem) -> Void = { _ in },
        onResumeFocus: @escaping () -> Void = {},
        onBrowseBacklog: @escaping () -> Void = {}
    ) {
        let isRunning = focusViewModel?.sessionState.state == .running
        let isPaused = focusViewModel?.sessionState.state == .paused
        self.isSessionActive = isRunning
        self.isSessionPaused = isPaused
        self.activeTaskTitle = focusViewModel?.selectedTask?.title ?? "Focus Session"
        self.remainingTimeText = focusViewModel?.timerDisplayText
        self.upNextTask = upNextTask
        self.isPlateClear = isPlateClear
        self.onStartFocus = onStartFocus
        self.onResumeFocus = onResumeFocus
        self.onBrowseBacklog = onBrowseBacklog
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let date = context.date
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Live Clock & Circadian Header
                HStack(alignment: .firstTextBaseline) {
                    Text(Self.clockTimeText(for: date))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Text(Self.circadianPhaseText(for: date))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Divider()
                    .background(AppColors.surfaceBorder)

                // Dynamic State Content
                if isSessionActive || isSessionPaused {
                    sessionActiveContent
                } else if let task = upNextTask {
                    upNextContent(task: task, referenceDate: date)
                } else if isPlateClear {
                    plateClearContent
                } else {
                    noTasksScheduledContent
                }
            }
            .padding(AppSpacing.md)
            .appCardStyle(cornerRadius: AppRadius.lg)
        }
    }

    // MARK: - State Subviews

    private var sessionActiveContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(isSessionActive ? AppColors.success : AppColors.warning)
                        .frame(width: 8, height: 8)
                    Text(isSessionActive ? "HAPPENING NOW" : "FOCUS PAUSED")
                        .font(AppTypography.captionSmall)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isSessionActive ? AppColors.successTint : AppColors.warningTint)
                .foregroundStyle(isSessionActive ? AppColors.success : AppColors.warning)
                .clipShape(Capsule())

                Spacer()

                if let remaining = remainingTimeText {
                    Text(remaining)
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.primary)
                }
            }

            Text(activeTaskTitle ?? "Focus Session")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            Button(action: onResumeFocus) {
                HStack(spacing: 6) {
                    Image(systemName: isSessionActive ? "arrow.up.left.and.arrow.down.right" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(isSessionActive ? "Open Focus Session" : "Resume Focus")
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(AppColors.primaryGradient)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func upNextContent(task: TaskItem, referenceDate: Date) -> some View {
        let durationMinutes = (task.estimatedDurationMinutes ?? 0) > 0 ? (task.estimatedDurationMinutes ?? 30) : 30
        let suggestedWindow = Self.suggestedTimeWindow(from: referenceDate, durationMinutes: durationMinutes)

        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("UP NEXT")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.primaryTint)
                    .foregroundStyle(AppColors.primary)
                    .clipShape(Capsule())

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(suggestedWindow)
                        .font(AppTypography.captionSmall)
                }
                .foregroundStyle(AppColors.textSecondary)
            }

            Text(task.title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            HStack(spacing: AppSpacing.xs) {
                // Duration Pill
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 10))
                    Text(task.formattedDuration)
                        .font(AppTypography.captionSmall)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppColors.canvasSecondary)
                .foregroundStyle(AppColors.textSecondary)
                .clipShape(Capsule())

                if let priority = task.priority {
                    PriorityBadge(priority: priority)
                }

                if let project = task.projectName, !project.isEmpty {
                    Text(project)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Button {
                onStartFocus(task)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Start Focus (\(task.formattedDuration))")
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(AppColors.primaryGradient)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .shadow(color: AppColors.primary.opacity(0.24), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var plateClearContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("🎉")
                    .font(.system(size: 22))
                Text("All caught up for today!")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text("Your schedule is clear. Take a breath or pull tasks from your backlog.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button(action: onBrowseBacklog) {
                HStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Browse Backlog")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, AppSpacing.sm)
                .frame(height: 32)
                .background(AppColors.primaryTint)
                .foregroundStyle(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var noTasksScheduledContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ready to plan your day")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("No tasks scheduled for today. Add a new task or pull from your backlog.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button(action: onBrowseBacklog) {
                HStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Browse Backlog")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, AppSpacing.sm)
                .frame(height: 32)
                .background(AppColors.primaryTint)
                .foregroundStyle(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - Formatting Helpers

    public static func clockTimeText(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    public static func circadianPhaseText(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let phase: String
        switch hour {
        case 5..<12:
            phase = "Morning Focus"
        case 12..<17:
            phase = "Afternoon Focus"
        case 17..<21:
            phase = "Evening Focus"
        default:
            phase = "Night Calm"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return "\(phase) • \(formatter.string(from: date))"
    }

    public static func suggestedTimeWindow(
        from startDate: Date = Date(),
        durationMinutes: Int,
        calendar: Calendar = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone

        let startStr = formatter.string(from: startDate)
        let endDate = calendar.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
        let endStr = formatter.string(from: endDate)
        return "\(startStr) – \(endStr)"
    }
}

#Preview {
    VStack(spacing: 20) {
        TimeAnchorCardView(
            upNextTask: TaskItem(
                title: "Build iOS time-sticky anchor card",
                priority: .high,
                estimatedDurationMinutes: 45
            )
        )

        TimeAnchorCardView(
            isSessionActive: true,
            activeTaskTitle: "Deep focus on AI knowledge",
            remainingTimeText: "24:18 remaining"
        )

        TimeAnchorCardView(
            isPlateClear: true
        )
    }
    .padding()
    .background(AppColors.canvas)
}

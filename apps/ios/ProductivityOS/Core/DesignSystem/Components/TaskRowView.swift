import SwiftUI

/// Task row component matching the approved visual design in `today.png`
public struct TaskRowView: View {
    private let position: Int?
    private let title: String
    private let projectName: String?
    private let priority: TaskPriority
    private let iconName: String
    private let dueDate: String?
    private let estimatedDurationMinutes: Int?
    private let onRescheduleToday: (() -> Void)?
    private let onRescheduleTomorrow: (() -> Void)?
    private let onMoveToBacklog: (() -> Void)?
    private let onEdit: (() -> Void)?
    private let action: () -> Void
    
    public init(
        position: Int? = nil,
        title: String,
        projectName: String? = "Productivity OS",
        priority: TaskPriority = .medium,
        iconName: String = "flag.fill",
        estimatedDurationMinutes: Int? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.position = position
        self.title = title
        self.projectName = projectName
        self.priority = priority
        self.iconName = iconName
        self.dueDate = nil
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.onRescheduleToday = nil
        self.onRescheduleTomorrow = nil
        self.onMoveToBacklog = nil
        self.onEdit = nil
        self.action = action
    }

    public init(
        position: Int? = nil,
        title: String,
        projectName: String? = "Productivity OS",
        priority: TaskPriority = .medium,
        iconName: String = "flag.fill",
        dueDate: String? = nil,
        estimatedDurationMinutes: Int? = nil,
        onRescheduleToday: (() -> Void)? = nil,
        onRescheduleTomorrow: (() -> Void)? = nil,
        onMoveToBacklog: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.position = position
        self.title = title
        self.projectName = projectName
        self.priority = priority
        self.iconName = iconName
        self.dueDate = dueDate
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.onRescheduleToday = onRescheduleToday
        self.onRescheduleTomorrow = onRescheduleTomorrow
        self.onMoveToBacklog = onMoveToBacklog
        self.onEdit = onEdit
        self.action = action
    }

    private var effectiveProjectName: String? {
        guard let projectName else { return nil }
        let trimmed = projectName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != "—", trimmed != "-" else { return nil }
        return trimmed
    }

    private var formattedDuration: String? {
        guard let minutes = estimatedDurationMinutes, minutes > 0 else { return nil }
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }

    private var dueDateInfo: (text: String, isOverdue: Bool)? {
        TasksViewModel.relativeDueDateDescription(dueDate: dueDate)
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                // Position number (e.g. "01")
                if let position {
                    Text(String(format: "%02d", position))
                        .font(AppTypography.numberBadge)
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 26, alignment: .leading)
                }
                
                // Icon square
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.primaryTint)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                
                // Title and metadata
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppTypography.numberBadge)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    metadataRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Spacer(minLength: AppSpacing.xs)

                // Trailing priority and duration badges
                VStack(alignment: .trailing, spacing: 4) {
                    PriorityBadge(priority: priority)
                        .fixedSize()

                    if let formattedDuration {
                        HStack(spacing: 3) {
                            Image(systemName: "stopwatch")
                                .font(.system(size: 9))
                            Text(formattedDuration)
                                .font(AppTypography.captionSmall)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.canvasSecondary)
                        .foregroundStyle(AppColors.textSecondary)
                        .clipShape(Capsule())
                        .fixedSize()
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)

                // Trailing chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize()
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm + 2)
            .appCardStyle(cornerRadius: AppRadius.lg)
        }
        .buttonStyle(ScaleButtonStyle())
        .modifier(TaskRowActionsModifier(
            onEdit: onEdit,
            onRescheduleToday: onRescheduleToday,
            onRescheduleTomorrow: onRescheduleTomorrow,
            onMoveToBacklog: onMoveToBacklog
        ))
    }

    @ViewBuilder
    private var metadataRow: some View {
        let hasProject = effectiveProjectName != nil
        let hasDueDate = dueDateInfo != nil

        if hasProject || hasDueDate {
            HStack(spacing: 4) {
                if let project = effectiveProjectName {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 6, height: 6)
                    Text(project)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if hasProject && hasDueDate {
                    Text("•")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize()
                }

                if let info = dueDateInfo {
                    dueDateBadge(info: info)
                }
            }
        }
    }

    @ViewBuilder
    private func dueDateBadge(info: (text: String, isOverdue: Bool)) -> some View {
        HStack(spacing: 3) {
            Image(systemName: info.isOverdue ? "exclamationmark.circle.fill" : (info.text == "Today" ? "sun.max.fill" : "calendar"))
                .font(.system(size: 10))
            Text(info.text)
                .font(AppTypography.caption)
                .fontWeight(info.isOverdue ? .semibold : .regular)
                .lineLimit(1)
        }
        .foregroundStyle(info.isOverdue ? Color(hex: "FF6B4A") : (info.text == "Today" ? AppColors.primary : AppColors.textSecondary))
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct TaskRowActionsModifier: ViewModifier {
    let onEdit: (() -> Void)?
    let onRescheduleToday: (() -> Void)?
    let onRescheduleTomorrow: (() -> Void)?
    let onMoveToBacklog: (() -> Void)?

    private var hasActions: Bool {
        onEdit != nil || onRescheduleToday != nil || onRescheduleTomorrow != nil || onMoveToBacklog != nil
    }

    func body(content: Content) -> some View {
        if hasActions {
            content
                .contextMenu {
                    if let onEdit {
                        Button(action: onEdit) {
                            Label("Edit Task", systemImage: "pencil")
                        }
                        Divider()
                    }
                    if let onRescheduleToday {
                        Button(action: onRescheduleToday) {
                            Label("Reschedule to Today", systemImage: "sun.max")
                        }
                    }
                    if let onRescheduleTomorrow {
                        Button(action: onRescheduleTomorrow) {
                            Label("Reschedule to Tomorrow", systemImage: "arrow.right.circle")
                        }
                    }
                    if let onMoveToBacklog {
                        Button(action: onMoveToBacklog) {
                            Label("Move to Backlog", systemImage: "tray")
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if let onMoveToBacklog {
                        Button(action: onMoveToBacklog) {
                            Label("Backlog", systemImage: "tray")
                        }
                        .tint(AppColors.textSecondary)
                    }
                    if let onRescheduleTomorrow {
                        Button(action: onRescheduleTomorrow) {
                            Label("Tomorrow", systemImage: "arrow.right.circle")
                        }
                        .tint(Color.blue)
                    }
                    if let onRescheduleToday {
                        Button(action: onRescheduleToday) {
                            Label("Today", systemImage: "sun.max")
                        }
                        .tint(Color.orange)
                    }
                }
        } else {
            content
        }
    }
}

/// Priority badge pill component
public struct PriorityBadge: View {
    public let priority: TaskPriority
    
    public init(priority: TaskPriority) {
        self.priority = priority
    }
    
    public var body: some View {
        Text(priority.title)
            .font(AppTypography.captionSmall)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(priority.backgroundColor)
            .foregroundStyle(priority.foregroundColor)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskRowView(position: 1, title: "Finish authentication", priority: .high, iconName: "flag.fill")
        TaskRowView(position: 2, title: "Review API implementation", priority: .medium, iconName: "curlybraces")
        TaskRowView(position: 3, title: "Build task dashboard", priority: .low, iconName: "square.grid.2x2.fill")
    }
    .padding()
    .background(AppColors.canvas)
}

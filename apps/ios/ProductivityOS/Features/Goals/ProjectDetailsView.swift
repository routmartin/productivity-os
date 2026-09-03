import SwiftUI

/// Read-only project detail screen. Shows project title, description,
/// progress, status, task count, target date, and the parent goal. No
/// mutation controls — the iOS app is view-only for projects.
public struct ProjectDetailsView: View {
    @Bindable var viewModel: GoalsViewModel
    let projectId: UUID

    public init(viewModel: GoalsViewModel, projectId: UUID) {
        self.viewModel = viewModel
        self.projectId = projectId
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let project = viewModel.project(for: projectId) {
                    headerSection(for: project)
                    progressSection(for: project)
                    if let description = project.description, !description.isEmpty {
                        descriptionSection(description)
                    }
                    metaSection(for: project)
                    if let goal = viewModel.goalCard(for: project.goalId ?? UUID())?.goal ?? parentGoal(for: project) {
                        parentGoalSection(goal)
                    }
                    taskListSection
                } else {
                    Text("Project not found")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, 100)
        }
        .background(AppColors.canvas.ignoresSafeArea())
        .navigationTitle("Project")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Subviews

    private func headerSection(for project: Project) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryTint)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon(for: project.status))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    StatusPill(label: statusText(for: project.status), color: AppColors.primary)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.title), \(statusText(for: project.status)) project")
    }

    private func progressSection(for project: Project) -> some View {
        let progress = computedProgress(for: project)
        return AppCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ProgressBar(progress: progress, tint: AppColors.primary, height: 8)
                HStack {
                    Text("\(GoalsViewModel.progressPercent(progress))% complete")
                        .font(AppTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("\(taskStats.completedCount) of \(taskStats.totalCount) tasks")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress \(GoalsViewModel.progressPercent(progress)) percent complete, \(taskStats.completedCount) of \(taskStats.totalCount) tasks")
    }

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("About this project")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.primary)
                .tracking(0.8)
            Text(description)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaSection(for project: Project) -> some View {
        VStack(spacing: 0) {
            metadataRow(
                icon: "calendar",
                label: "Target Date",
                value: GoalsViewModel.formatDeadline(project.deadline) ?? "Not set"
            )
            Divider().background(AppColors.surfaceBorder)
            metadataRow(
                icon: "checklist",
                label: "Task Count",
                value: "\(taskStats.totalCount)"
            )
            Divider().background(AppColors.surfaceBorder)
            metadataRow(
                icon: statusIcon(for: project.status),
                label: "Status",
                value: statusText(for: project.status)
            )
            if let completedAt = project.completedAt {
                Divider().background(AppColors.surfaceBorder)
                metadataRow(
                    icon: "checkmark.seal.fill",
                    label: "Completed",
                    value: Self.formatDate(completedAt)
                )
            }
        }
        .appCardStyle(cornerRadius: AppRadius.md)
    }

    private func parentGoalSection(_ goal: Goal) -> some View {
        NavigationLink(value: GoalRoute.goal(goal.id)) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.primaryTint)
                        .frame(width: 40, height: 40)
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Parent goal")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(goal.title)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .appCardStyle(cornerRadius: AppRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Parent goal: \(goal.title)")
    }

    @ViewBuilder
    private var taskListSection: some View {
        let tasks = viewModel.tasks(for: projectId)
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeaderView(title: "Tasks")
                VStack(spacing: AppSpacing.xs) {
                    ForEach(tasks) { task in
                        TaskRowView(
                            title: task.title,
                            projectName: nil,
                            priority: task.priority ?? .medium,
                            iconName: task.isCompleted ? "checkmark.circle.fill" : "circle"
                        )
                        .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var taskStats: ProjectStats {
        viewModel.projectStats[projectId] ?? .empty
    }

    private func computedProgress(for project: Project) -> Double {
        let stats = taskStats
        return GoalsViewModel.progressValue(
            completed: stats.completedCount,
            total: stats.totalCount,
            status: project.status
        )
    }

    private func parentGoal(for project: Project) -> Goal? {
        guard let goalId = project.goalId else { return nil }
        return viewModel.goalCard(for: goalId)?.goal
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .frame(width: 24)
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }

    private func icon(for status: ProjectStatus) -> String {
        switch status {
        case .draft: return "square.dashed"
        case .active: return "folder.fill"
        case .completed: return "checkmark.seal.fill"
        case .archived: return "archivebox.fill"
        }
    }

    private func statusIcon(for status: ProjectStatus) -> String {
        switch status {
        case .draft: return "square.dashed"
        case .active: return "play.circle"
        case .completed: return "checkmark.seal.fill"
        case .archived: return "archivebox.fill"
        }
    }

    private func statusText(for status: ProjectStatus) -> String {
        switch status {
        case .draft: return "Not Started"
        case .active: return "In Progress"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
import SwiftUI

/// Read-only goal detail screen. Shows the goal's identity, description,
/// progress, target date, project count, and the projects supporting it.
/// No mutation controls.
public struct GoalDetailsView: View {
    @Bindable var viewModel: GoalsViewModel
    let goalId: UUID

    public init(viewModel: GoalsViewModel, goalId: UUID) {
        self.viewModel = viewModel
        self.goalId = goalId
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection
                progressSection
                if let description = card?.goal.description, !description.isEmpty {
                    descriptionSection(description)
                }
                metaSection
                projectsSection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, 100)
        }
        .background(AppColors.canvas.ignoresSafeArea())
        .navigationTitle("Goal Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(for: GoalRoute.self) { route in
            switch route {
            case .goal:
                GoalDetailsView(viewModel: viewModel, goalId: goalId)
            case .project(let id):
                ProjectDetailsView(viewModel: viewModel, projectId: id)
            }
        }
    }

    // MARK: - Subviews

    private var card: GoalCardModel? {
        viewModel.goalCard(for: goalId)
    }

    @ViewBuilder
    private var headerSection: some View {
        if let card {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryTint)
                        .frame(width: 56, height: 56)
                    Image(systemName: "target")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.goal.title)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    if card.goal.status == .completed {
                        StatusPill(label: "Completed", color: AppColors.primary)
                    } else if card.goal.status == .draft {
                        StatusPill(label: "Draft", color: AppColors.textTertiary)
                    } else {
                        StatusPill(label: "Active", color: AppColors.primary)
                    }
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(card.goal.title), \(card.goal.status.rawValue.capitalized) goal")
        } else {
            Text("Goal not found")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if let card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ProgressBar(progress: card.aggregateProgress, tint: AppColors.primary, height: 8)
                    Text("\(GoalsViewModel.progressPercent(card.aggregateProgress))% complete")
                        .font(AppTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .appCardStyle(cornerRadius: AppRadius.lg)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Progress \(GoalsViewModel.progressPercent(card.aggregateProgress)) percent complete")
        }
    }

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("About this goal")
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

    @ViewBuilder
    private var metaSection: some View {
        if let card {
            HStack(spacing: AppSpacing.md) {
                metaTile(
                    icon: "calendar",
                    label: "Target",
                    value: GoalsViewModel.formatDeadline(card.goal.deadline) ?? "—"
                )
                metaTile(
                    icon: "folder.fill",
                    label: "Projects",
                    value: "\(card.projectCount)"
                )
            }
        }
    }

    private func metaTile(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                Text(label.uppercased())
                    .font(AppTypography.captionSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                    .tracking(0.6)
            }
            Text(value)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .appCardStyle(cornerRadius: AppRadius.lg)
    }

    @ViewBuilder
    private var projectsSection: some View {
        if let card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeaderView(title: "Projects")
                if card.projects.isEmpty {
                    AppCard(cornerRadius: AppRadius.lg) {
                        Text("No projects yet")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    ForEach(card.projects) { summary in
                        NavigationLink(value: GoalRoute.project(summary.project.id)) {
                            ProjectSummaryRow(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Project summary row (used on goal details)

struct ProjectSummaryRow: View {
    let summary: GoalCardModel.ProjectSummary

    var body: some View {
        AppCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .center, spacing: AppSpacing.sm) {
                    iconBadge
                    Text(summary.project.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("\(GoalsViewModel.progressPercent(summary.progress))%")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                        .monospacedDigit()
                }

                ProgressBar(progress: summary.progress, tint: AppColors.primary)

                HStack(spacing: AppSpacing.xs) {
                    Text("\(summary.taskCount) \(summary.taskCount == 1 ? "task" : "tasks")")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("·")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(statusText(for: summary.project.status))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.project.title), \(GoalsViewModel.progressPercent(summary.progress)) percent complete, \(summary.taskCount) tasks, \(statusText(for: summary.project.status))")
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppColors.primaryTint)
                .frame(width: 32, height: 32)
            Image(systemName: iconName(for: summary.project.status))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primary)
        }
        .accessibilityHidden(true)
    }

    private func iconName(for status: ProjectStatus) -> String {
        switch status {
        case .draft: return "square.dashed"
        case .active: return "folder.fill"
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
}

// MARK: - Status pill

struct StatusPill: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(AppTypography.captionSmall)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    GoalsView(
        viewModel: GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )
    )
}
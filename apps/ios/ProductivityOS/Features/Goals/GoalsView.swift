import SwiftUI

/// Goals & Projects landing screen — read-only presentation of all the
/// user's goals and an overall progress overview. Adopts the same light
/// DesignSystem tokens used by Today / Tasks so the feature belongs to the
/// same application.
public struct GoalsView: View {
    @State private var viewModel = GoalsViewModel()

    public init(viewModel: GoalsViewModel = GoalsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerSection

                    overallProgressCard

                    goalsList
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .navigationTitle("Goals & Projects")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityLabel("Refresh goals")
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                if case .idle = viewModel.loadState {
                    await viewModel.loadData()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .navigationDestination(for: GoalRoute.self) { route in
                switch route {
                case .goal(let id):
                    GoalDetailsView(viewModel: viewModel, goalId: id)
                case .project(let id):
                    ProjectDetailsView(viewModel: viewModel, projectId: id)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("Goals & Projects")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Keep your work connected to what matters.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var overallProgressCard: some View {
        OverallProgressCard(progress: viewModel.overallProgress)
    }

    @ViewBuilder
    private var goalsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeaderView(title: "Goals")
            contentForGoalsList
        }
    }

    @ViewBuilder
    private var contentForGoalsList: some View {
        if viewModel.isLoading && viewModel.goalCards.isEmpty {
            APIStateView(kind: .loading(message: "Loading your goals..."))
        } else if let message = viewModel.errorMessage {
            APIStateView(
                kind: .error(message: message),
                onRetry: { Task { await viewModel.refresh() } }
            )
        } else if viewModel.isEmpty {
            APIStateView(
                kind: .empty(
                    icon: "target",
                    title: "No goals yet",
                    subtitle: "Your goals will appear here once they are created on the web or another device."
                )
            )
        } else {
            ForEach(viewModel.goalCards) { card in
                NavigationLink(value: GoalRoute.goal(card.goal.id)) {
                    GoalCardView(card: card)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Navigation routes

enum GoalRoute: Hashable {
    case goal(UUID)
    case project(UUID)
}

// MARK: - Overall Progress Card

private struct OverallProgressCard: View {
    let progress: OverallProgress

    var body: some View {
        AppCard(cornerRadius: AppRadius.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Overall Progress")
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(AppColors.primary)
                    .tracking(0.8)

                HStack(alignment: .center, spacing: AppSpacing.lg) {
                    ProgressRing(
                        progress: progress.percent,
                        lineWidth: 9,
                        size: 86,
                        accessibilityLabel: "Overall progress"
                    )
                    .overlay {
                        Text(progress.hasData ? "\(GoalsViewModel.progressPercent(progress.percent))%" : "—")
                            .font(AppTypography.title)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        legendRow(
                            icon: "checkmark.circle.fill",
                            color: AppColors.primary,
                            label: "Completed",
                            value: progress.completed
                        )
                        legendRow(
                            icon: "circle.dotted",
                            color: AppColors.primary.opacity(0.6),
                            label: "In Progress",
                            value: progress.inProgress
                        )
                        legendRow(
                            icon: "circle",
                            color: AppColors.textTertiary,
                            label: "Not Started",
                            value: progress.notStarted
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard progress.hasData else {
            return "Overall progress: no projects yet"
        }
        return "Overall progress: \(GoalsViewModel.progressPercent(progress.percent)) percent. \(progress.completed) completed, \(progress.inProgress) in progress, \(progress.notStarted) not started."
    }

    private func legendRow(icon: String, color: Color, label: String, value: Int) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 16)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: AppSpacing.xs)
            Text("\(value)")
                .font(AppTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
        }
    }
}

// MARK: - Goal Card

private struct GoalCardView: View {
    let card: GoalCardModel

    var body: some View {
        AppCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .center, spacing: AppSpacing.sm) {
                    iconBadge
                    Text(card.goal.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }

                ProgressBar(
                    progress: card.aggregateProgress,
                    tint: AppColors.primary
                )

                HStack(spacing: AppSpacing.xs) {
                    Text(metadata)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppColors.primaryTint)
                .frame(width: 36, height: 36)
            Image(systemName: "target")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primary)
        }
        .accessibilityHidden(true)
    }

    private var metadata: String {
        let projectWord = card.projectCount == 1 ? "Project" : "Projects"
        var pieces: [String] = ["\(card.projectCount) \(projectWord)"]
        if let deadline = GoalsViewModel.relativeDeadline(card.goal.deadline) {
            pieces.append(deadline)
        }
        return pieces.joined(separator: " · ")
    }

    private var accessibilityLabel: String {
        let percent = GoalsViewModel.progressPercent(card.aggregateProgress)
        let projectWord = card.projectCount == 1 ? "project" : "projects"
        var label = "\(card.goal.title), \(percent) percent complete, \(card.projectCount) \(projectWord)"
        if let deadline = GoalsViewModel.relativeDeadline(card.goal.deadline) {
            label += ", \(deadline.lowercased())"
        }
        return label
    }
}

// MARK: - Progress primitives

struct ProgressBar: View {
    let progress: Double
    let tint: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            let clamped = max(0, min(1, progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.primaryTint)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * clamped)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let accessibilityLabel: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.primaryTint, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(
                    AppColors.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppMotion.standard, value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(GoalsViewModel.progressPercent(progress)) percent")
    }
}

#Preview("Goals with data") {
    GoalsView(viewModel: GoalsViewModel(
        preloadGoals: SampleData.mockGoals,
        preloadProjects: SampleData.mockProjectsForGoals,
        preloadProjectTasks: SampleData.mockProjectTasks
    ))
}

#Preview("Empty") {
    GoalsView(viewModel: GoalsViewModel(
        preloadGoals: [],
        preloadProjects: []
    ))
}
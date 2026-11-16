import SwiftUI

/// Tasks browsing view backed by the real tasks API and Time-Sticky UX paradigm.
public struct TasksView: View {
    @State private var viewModel: TasksViewModel
    @State private var projectsViewModel: ProjectsViewModel
    private var focusViewModel: FocusSessionViewModel?
    @State private var editingTask: TaskItem?
    private let onResumeFocus: () -> Void
    private let onSelectTask: (TaskItem) -> Void

    public init(
        apiClient: APIRequesting = APIClient.shared,
        projectsViewModel: ProjectsViewModel = ProjectsViewModel(),
        focusViewModel: FocusSessionViewModel? = nil,
        onResumeFocus: @escaping () -> Void = {},
        onSelectTask: @escaping (TaskItem) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: TasksViewModel(apiClient: apiClient))
        _projectsViewModel = State(initialValue: projectsViewModel)
        self.focusViewModel = focusViewModel
        self.onResumeFocus = onResumeFocus
        self.onSelectTask = onSelectTask
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // In-canvas Screen Header
                    headerSection

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textTertiary)
                        TextField("Search tasks...", text: $viewModel.searchText)
                            .font(AppTypography.body)
                    }
                    .padding(AppSpacing.sm)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(AppColors.surfaceBorder, lineWidth: 1)
                    )

                    // Single unified fluid segment bar: Today, Upcoming, Backlog, Done, All
                    TaskDateSegmentBar(
                        selectedSegment: $viewModel.dateSegment,
                        counts: viewModel.segmentCounts
                    )

                    if viewModel.isLoading && viewModel.filteredTasks.isEmpty {
                        APIStateView(kind: .loading(message: "Loading tasks..."))
                    } else if case .failed(let message) = viewModel.loadState {
                        APIStateView(
                            kind: .error(message: message),
                            onRetry: { Task { await viewModel.loadTasks() } }
                        )
                    } else if viewModel.dateSegment == .today {
                        todaySegmentContent
                    } else {
                        standardSegmentContent
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 140)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .sheet(item: $editingTask) { task in
                TaskEditSheet(
                    task: task,
                    onSaved: { updated in
                        viewModel.replace(updated)
                    }
                )
            }
            .task {
                if case .idle = viewModel.loadState {
                    await viewModel.loadTasks()
                }
                if case .idle = projectsViewModel.loadState {
                    await projectsViewModel.loadProjects()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Tasks")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Organize, schedule, and execute your commitments")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Today Segment View (Time Anchor & Overdue Split)

    @ViewBuilder
    private var todaySegmentContent: some View {
        let isPlateClear = viewModel.overdueTasks.isEmpty && viewModel.todayScheduledTasks.isEmpty

        // Time-Sticky Anchor Card answering "What should I do right now?"
        TimeAnchorCardView(
            focusViewModel: focusViewModel,
            upNextTask: viewModel.upNextTask,
            isPlateClear: isPlateClear,
            onStartFocus: { task in onSelectTask(task) },
            onResumeFocus: onResumeFocus,
            onBrowseBacklog: {
                withAnimation(AppMotion.spring) {
                    viewModel.dateSegment = .backlog
                }
            }
        )

        if isPlateClear {
            APIStateView(
                kind: .empty(
                    icon: emptyIcon,
                    title: emptyTitle,
                    subtitle: emptySubtitle
                )
            )
        } else {
            // Overdue Tasks Section (Isolated visually with warning coral accent)
            if !viewModel.overdueTasks.isEmpty {
                SectionHeaderView(title: "OVERDUE (\(viewModel.overdueTasks.count))")

                ForEach(viewModel.overdueTasks) { task in
                    taskRow(for: task)
                }
            }

            // Today's Scheduled Tasks Section
            if !viewModel.todayScheduledTasks.isEmpty {
                SectionHeaderView(title: "TODAY (\(viewModel.todayScheduledTasks.count))")

                ForEach(viewModel.todayScheduledTasks) { task in
                    taskRow(for: task)
                }
            }
        }
    }

    // MARK: - Standard Segment View (Upcoming, Backlog, Done, All)

    @ViewBuilder
    private var standardSegmentContent: some View {
        SectionHeaderView(title: sectionTitle)

        if viewModel.filteredTasks.isEmpty {
            APIStateView(
                kind: .empty(
                    icon: emptyIcon,
                    title: emptyTitle,
                    subtitle: emptySubtitle
                )
            )
        } else {
            ForEach(viewModel.filteredTasks) { task in
                taskRow(for: task)
            }
        }
    }

    // MARK: - Task Row View Builder

    @ViewBuilder
    private func taskRow(for task: TaskItem) -> some View {
        TaskRowView(
            title: task.title,
            projectName: projectsViewModel.projectName(for: task),
            priority: task.priority ?? .medium,
            iconName: task.isCompleted ? "checkmark.circle.fill" : "checklist",
            dueDate: task.dueDate,
            estimatedDurationMinutes: task.estimatedDurationMinutes,
            onRescheduleToday: {
                Task {
                    try? await viewModel.rescheduleTask(id: task.id, dueDate: TasksViewModel.todayISO)
                }
            },
            onRescheduleTomorrow: {
                Task {
                    try? await viewModel.rescheduleTask(id: task.id, dueDate: TasksViewModel.tomorrowISO)
                }
            },
            onMoveToBacklog: {
                Task {
                    try? await viewModel.rescheduleTask(id: task.id, dueDate: nil)
                }
            },
            onEdit: {
                editingTask = task
            }
        ) {
            // Completed / cancelled tasks aren't eligible for a focus session (spec §AC-003)
            guard !task.isCompleted && task.status != .cancelled else { return }
            onSelectTask(task)
        }
    }

    // MARK: - Empty State Titles & Icons

    private var sectionTitle: String {
        switch viewModel.dateSegment {
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .backlog: return "Backlog"
        case .completed: return "Done"
        case .all: return "All Tasks"
        }
    }

    private var emptyIcon: String {
        if !viewModel.searchText.isEmpty { return "magnifyingglass" }
        switch viewModel.dateSegment {
        case .today: return "sun.max"
        case .upcoming: return "calendar"
        case .backlog: return "tray"
        case .completed: return "checkmark.circle"
        case .all: return "checklist"
        }
    }

    private var emptyTitle: String {
        if !viewModel.searchText.isEmpty { return "No matches" }
        switch viewModel.dateSegment {
        case .today: return "Clear plate for today"
        case .upcoming: return "No upcoming tasks"
        case .backlog: return "Backlog is empty"
        case .completed: return "No completed tasks yet"
        case .all: return "No tasks yet"
        }
    }

    private var emptySubtitle: String? {
        if !viewModel.searchText.isEmpty { return "Try adjusting your search query." }
        switch viewModel.dateSegment {
        case .today:
            return "No tasks scheduled for today. Pull tasks from your backlog or enjoy the calm."
        case .upcoming:
            return "Your future schedule is clear. Plan ahead by scheduling dates on your tasks."
        case .backlog:
            return "All your tasks are scheduled on the calendar. Capture new ideas anytime."
        case .completed:
            return "Tasks you complete will appear here."
        case .all:
            return "Capture something you're thinking about."
        }
    }
}

#Preview {
    TasksView()
}

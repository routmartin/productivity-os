import SwiftUI

/// Tasks browsing view backed by the real tasks API.
public struct TasksView: View {
    @State private var viewModel: TasksViewModel
    @State private var projectsViewModel: ProjectsViewModel
    @State private var editingTask: TaskItem?
    private let onSelectTask: (TaskItem) -> Void

    public init(
        apiClient: APIRequesting = APIClient.shared,
        projectsViewModel: ProjectsViewModel = ProjectsViewModel(),
        onSelectTask: @escaping (TaskItem) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: TasksViewModel(apiClient: apiClient))
        _projectsViewModel = State(initialValue: projectsViewModel)
        self.onSelectTask = onSelectTask
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
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

                    // Primary date segment picker with reactive count badges
                    Picker("Segment", selection: $viewModel.dateSegment) {
                        ForEach(TasksViewModel.DateSegmentFilter.allCases) { segment in
                            let count = viewModel.segmentCounts[segment] ?? 0
                            Text("\(segment.title) (\(count))")
                                .tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Secondary status filter chips
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(TasksViewModel.TaskStatusFilter.allCases) { filter in
                            let isSelected = viewModel.statusFilter == filter
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.statusFilter = filter
                                }
                            } label: {
                                Text(filter.title)
                                    .font(AppTypography.captionSmall)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .frame(height: 32)
                                    .background(isSelected ? AppColors.primaryTint : AppColors.surface)
                                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                            .stroke(isSelected ? AppColors.primary : AppColors.surfaceBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }

                    SectionHeaderView(title: sectionTitle)

                    if viewModel.isLoading && viewModel.filteredTasks.isEmpty {
                        APIStateView(kind: .loading(message: "Loading tasks..."))
                    } else if case .failed(let message) = viewModel.loadState {
                        APIStateView(
                            kind: .error(message: message),
                            onRetry: { Task { await viewModel.loadTasks() } }
                        )
                    } else if viewModel.filteredTasks.isEmpty {
                        APIStateView(
                            kind: .empty(
                                icon: emptyIcon,
                                title: emptyTitle,
                                subtitle: emptySubtitle
                            )
                        )
                    } else {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(
                                title: task.title,
                                projectName: projectsViewModel.projectName(for: task) ?? "—",
                                priority: task.priority ?? .medium,
                                iconName: task.isCompleted ? "checkmark.circle.fill" : "checklist",
                                dueDate: task.dueDate,
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
                                // Completed / cancelled tasks aren't eligible
                                // for a focus session (spec §AC-003).
                                guard !task.isCompleted && task.status != .cancelled else { return }
                                onSelectTask(task)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 100)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .navigationTitle("Tasks")
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

    private var sectionTitle: String {
        if viewModel.statusFilter == .active {
            switch viewModel.dateSegment {
            case .today: return "Today"
            case .upcoming: return "Upcoming"
            case .backlog: return "Backlog"
            case .all: return "All Tasks"
            }
        } else {
            return "\(viewModel.dateSegment.title) • \(viewModel.statusFilter.title)"
        }
    }

    private var emptyIcon: String {
        if !viewModel.searchText.isEmpty { return "magnifyingglass" }
        if viewModel.statusFilter == .completed { return "checkmark.circle" }
        if viewModel.statusFilter == .cancelled { return "xmark.circle" }
        switch viewModel.dateSegment {
        case .today: return "sun.max"
        case .upcoming: return "calendar"
        case .backlog: return "tray"
        case .all: return "checklist"
        }
    }

    private var emptyTitle: String {
        if !viewModel.searchText.isEmpty { return "No matches" }
        if viewModel.statusFilter == .completed { return "No completed tasks" }
        if viewModel.statusFilter == .cancelled { return "No cancelled tasks" }
        switch viewModel.dateSegment {
        case .today: return "Clear plate for today"
        case .upcoming: return "No upcoming tasks"
        case .backlog: return "Backlog is empty"
        case .all: return "No tasks yet"
        }
    }

    private var emptySubtitle: String? {
        if !viewModel.searchText.isEmpty { return "Try adjusting your search query." }
        if viewModel.statusFilter == .completed {
            return "Completed tasks in this segment will appear here."
        }
        if viewModel.statusFilter == .cancelled {
            return "Cancelled tasks in this segment will appear here."
        }
        switch viewModel.dateSegment {
        case .today:
            return "No tasks scheduled for today. Pull tasks from your backlog or enjoy the calm."
        case .upcoming:
            return "Your future schedule is clear. Plan ahead by scheduling dates on your tasks."
        case .backlog:
            return "All your tasks are scheduled on the calendar. Capture new ideas anytime."
        case .all:
            return "Capture something you're thinking about."
        }
    }
}

#Preview {
    TasksView()
}

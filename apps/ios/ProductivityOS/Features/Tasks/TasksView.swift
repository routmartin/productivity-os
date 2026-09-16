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

                    // Status filter chips. Defaults to "Active" so the screen always opens
                    // focused on actionable work (spec §15).
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
                                icon: "checklist",
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
                                iconName: task.isCompleted ? "checkmark.circle.fill" : "checklist"
                            ) {
                                // Completed / cancelled tasks aren't eligible
                                // for a focus session (spec §AC-003). Open the
                                // edit sheet only.
                                if !task.isCompleted && task.status != .cancelled {
                                    onSelectTask(task)
                                }
                                editingTask = task
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
            .sheet(item: $editingTask) { task in
                TaskEditSheet(
                    task: task,
                    onSaved: { updated in
                        viewModel.replace(updated)
                    },
                    onDismiss: {
                        editingTask = nil
                    }
                )
            }
        }
    }

    private var sectionTitle: String {
        switch viewModel.statusFilter {
        case .all: return "All Tasks"
        case .active: return "Active Tasks"
        case .completed: return "Completed Tasks"
        case .cancelled: return "Cancelled Tasks"
        }
    }

    private var emptyTitle: String {
        if !viewModel.searchText.isEmpty { return "No matches" }
        switch viewModel.statusFilter {
        case .all: return "No tasks yet"
        case .active: return "No active tasks"
        case .completed: return "No completed tasks"
        case .cancelled: return "No cancelled tasks"
        }
    }

    private var emptySubtitle: String? {
        if !viewModel.searchText.isEmpty { return nil }
        if viewModel.statusFilter == .active {
            return "Create a task on web or pick one from Today."
        }
        return nil
    }
}

#Preview {
    TasksView()
}

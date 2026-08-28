import SwiftUI

/// Tasks browsing view backed by the real tasks API.
public struct TasksView: View {
    @State private var viewModel: TasksViewModel
    @State private var projectsViewModel: ProjectsViewModel
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

                    SectionHeaderView(title: "Active Tasks")

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
                                title: viewModel.searchText.isEmpty ? "No active tasks" : "No matches",
                                subtitle: viewModel.searchText.isEmpty
                                    ? "Create a task on web or pick one from Today."
                                    : nil
                            )
                        )
                    } else {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(
                                title: task.title,
                                projectName: projectsViewModel.projectName(for: task) ?? "—",
                                priority: task.priority ?? .medium,
                                iconName: "checklist"
                            ) {
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
            .task {
                if case .idle = viewModel.loadState {
                    await viewModel.loadTasks()
                }
                await projectsViewModel.loadProjects()
            }
            .refreshable {
                await viewModel.loadTasks()
            }
        }
    }
}

#Preview {
    TasksView()
}

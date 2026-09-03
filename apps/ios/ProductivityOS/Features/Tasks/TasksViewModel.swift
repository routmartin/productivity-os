import Foundation
import Observation

/// State for the Tasks screen backed by `GET /api/v1/tasks`.
@Observable
public final class TasksViewModel {
    public enum LoadState {
        case idle
        case loading
        case loaded([TaskItem])
        case failed(String)
    }

    public private(set) var loadState: LoadState = .idle
    public var searchText: String = ""

    private let taskService: TaskService

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.taskService = TaskService(apiClient: apiClient)
    }

    /// Search-filtered view of the loaded tasks (local filtering only).
    public var filteredTasks: [TaskItem] {
        guard case .loaded(let tasks) = loadState else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return tasks }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    public var isLoading: Bool {
        if case .loading = loadState { return true }
        return false
    }

    public func loadTasks() async {
        loadState = .loading
        do {
            let tasks = try await taskService.listActiveTasks()
            loadState = .loaded(tasks)
        } catch {
            loadState = .failed(FocusSessionViewModel.userMessage(for: error))
        }
    }

    /// Swap a task in the loaded list by id. Used by the edit sheet to
    /// keep the row in sync after a successful save without a refetch.
    public func replace(_ task: TaskItem) {
        guard case .loaded(var tasks) = loadState else { return }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            loadState = .loaded(tasks)
        }
    }
}

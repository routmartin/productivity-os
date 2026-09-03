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

    /// Client-side filter applied to the loaded task list. The backend's
    /// `listActiveTasks` already excludes completed/cancelled/deleted tasks,
    /// but we still let the user surface them when the API does return them
    /// (e.g. during a race with a server-side update) by switching to
    /// `.all`. Default is `.active` per spec §15 (active = not completed,
    /// not cancelled, not deleted).
    public enum TaskStatusFilter: String, CaseIterable, Identifiable, Sendable {
        case all
        case active
        case completed
        case cancelled

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .all: return "All"
            case .active: return "Active"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }
    }

    public private(set) var loadState: LoadState = .idle
    public var searchText: String = ""
    public var statusFilter: TaskStatusFilter = .active

    private let taskService: TaskService

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.taskService = TaskService(apiClient: apiClient)
    }

    /// Search- and status-filtered view of the loaded tasks.
    /// Both filters are local-only — the loaded list is whatever the API
    /// returned for `listActiveTasks()`.
    public var filteredTasks: [TaskItem] {
        guard case .loaded(let tasks) = loadState else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return tasks.filter { task in
            guard Self.matches(statusFilter, task: task) else { return false }
            guard !query.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(query)
        }
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

    private static func matches(_ filter: TaskStatusFilter, task: TaskItem) -> Bool {
        switch filter {
        case .all:
            return true
        case .active:
            return !task.isCompleted && task.status != .cancelled && task.deletedAt == nil
        case .completed:
            return task.isCompleted
        case .cancelled:
            return task.status == .cancelled
        }
    }
}

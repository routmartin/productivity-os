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

    /// Top-level temporal segment filter aligning with Plan 015 and spec §7.
    /// Default is `.today` per North Star ("know what to do today").
    public enum DateSegmentFilter: String, CaseIterable, Identifiable, Sendable {
        case today
        case upcoming
        case backlog
        case all

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .today: return "Today"
            case .upcoming: return "Upcoming"
            case .backlog: return "Backlog"
            case .all: return "All"
            }
        }
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
    public var dateSegment: DateSegmentFilter = .today
    public var statusFilter: TaskStatusFilter = .active

    private let taskService: TaskService

    public static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public static var todayISO: String {
        isoDateFormatter.string(from: Date())
    }

    public static var tomorrowISO: String {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            return todayISO
        }
        return isoDateFormatter.string(from: tomorrow)
    }

    public static func todayISO(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    public static func tomorrowISO(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: tomorrow)
    }

    public init(apiClient: APIRequesting = APIClient.shared, taskService: TaskService? = nil) {
        self.taskService = taskService ?? TaskService(apiClient: apiClient)
    }

    /// Reactive count of active tasks belonging to each date segment bucket.
    /// Active tasks are those not completed, not cancelled, and not deleted.
    /// Independent of the secondary `statusFilter` (spec §7.2, §7.3).
    public var segmentCounts: [DateSegmentFilter: Int] {
        guard case .loaded(let tasks) = loadState else {
            return Dictionary(uniqueKeysWithValues: DateSegmentFilter.allCases.map { ($0, 0) })
        }
        let today = Self.todayISO
        let activeTasks = tasks.filter { Self.matches(.active, task: $0) }

        var counts: [DateSegmentFilter: Int] = [:]
        for segment in DateSegmentFilter.allCases {
            switch segment {
            case .all:
                counts[.all] = activeTasks.count
            case .today:
                counts[.today] = activeTasks.filter { task in
                    guard let dueDate = task.dueDate else { return false }
                    return dueDate <= today
                }.count
            case .upcoming:
                counts[.upcoming] = activeTasks.filter { task in
                    guard let dueDate = task.dueDate else { return false }
                    return dueDate > today
                }.count
            case .backlog:
                counts[.backlog] = activeTasks.filter { $0.dueDate == nil }.count
            }
        }
        return counts
    }

    /// Multi-dimensional filtered view of the loaded tasks:
    /// Conjunction of Date Segment, Status Filter, and Search Text.
    public var filteredTasks: [TaskItem] {
        guard case .loaded(let tasks) = loadState else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let today = Self.todayISO
        return tasks.filter { task in
            guard Self.matches(dateSegment, task: task, todayISO: today) else { return false }
            guard Self.matches(statusFilter, task: task) else { return false }
            guard !query.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(query)
        }
    }

    public static func matches(
        _ segment: DateSegmentFilter,
        task: TaskItem,
        todayISO: String = todayISO
    ) -> Bool {
        switch segment {
        case .today:
            guard let dueDate = task.dueDate else { return false }
            return dueDate <= todayISO
        case .upcoming:
            guard let dueDate = task.dueDate else { return false }
            return dueDate > todayISO
        case .backlog:
            return task.dueDate == nil
        case .all:
            return true
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
            FocusWidgetPublisher.publish(tasks)
        } catch {
            loadState = .failed(FocusSessionViewModel.userMessage(for: error))
        }
    }

    /// Bypasses the shared `APICache` for the active-tasks list. Pull-to-
    /// refresh and the user's manual expectation that "Refresh" means
    /// "really fetch" both flow through here.
    public func refresh() async {
        await APICache.shared.evict(prefix: "/api/v1/tasks")
        await loadTasks()
    }

    /// Swap a task in the loaded list by id. Used by the edit sheet to
    /// keep the row in sync after a successful save without a refetch.
    public func replace(_ task: TaskItem) {
        guard case .loaded(var tasks) = loadState else { return }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            loadState = .loaded(tasks)
            FocusWidgetPublisher.publish(tasks)
        }
    }

    /// Reschedule task to a new due date (or clear it to move to backlog).
    /// Preserves existing fields per the backend full-replace PUT contract
    /// and immediately updates the in-memory task item.
    public func rescheduleTask(id: UUID, dueDate: String?) async throws {
        guard case .loaded(let tasks) = loadState,
              let existing = tasks.first(where: { $0.id == id }) else {
            return
        }
        let updated = try await taskService.updateTask(
            id: id,
            title: existing.title,
            description: existing.description,
            dueDate: dueDate,
            priority: existing.priority,
            energy: existing.energy,
            estimatedDurationMinutes: existing.estimatedDurationMinutes
        )
        replace(updated)
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

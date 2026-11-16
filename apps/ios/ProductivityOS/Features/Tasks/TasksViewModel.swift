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
        case completed
        case all

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .today: return "Today"
            case .upcoming: return "Upcoming"
            case .backlog: return "Backlog"
            case .completed: return "Done"
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
    public private(set) var completedTasks: [TaskItem] = []
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
            case .completed:
                counts[.completed] = candidateCompletedTasks.count
            }
        }
        return counts
    }

    /// Reactive status counts for the currently selected date segment.
    /// Reflects tasks in each lifecycle state matching `dateSegment`.
    public var statusCounts: [TaskStatusFilter: Int] {
        let today = Self.todayISO
        let activeList: [TaskItem]
        if case .loaded(let tasks) = loadState {
            activeList = tasks
        } else {
            activeList = []
        }

        // Active non-completed tasks matching segment
        let segmentActive = activeList.filter {
            Self.matches(dateSegment, task: $0, todayISO: today) && Self.matches(.active, task: $0)
        }

        // Completed tasks matching segment
        var seenCompleted = Set<UUID>()
        var segmentCompleted: [TaskItem] = []
        for task in completedTasks where task.isCompleted {
            if Self.matches(dateSegment, task: task, todayISO: today) && seenCompleted.insert(task.id).inserted {
                segmentCompleted.append(task)
            }
        }
        for task in activeList where task.isCompleted {
            if Self.matches(dateSegment, task: task, todayISO: today) && seenCompleted.insert(task.id).inserted {
                segmentCompleted.append(task)
            }
        }

        // Cancelled tasks matching segment
        let segmentCancelled = activeList.filter {
            Self.matches(dateSegment, task: $0, todayISO: today) && Self.matches(.cancelled, task: $0)
        }

        var counts: [TaskStatusFilter: Int] = [:]
        counts[.active] = segmentActive.count
        counts[.completed] = segmentCompleted.count
        counts[.cancelled] = segmentCancelled.count
        counts[.all] = segmentActive.count + segmentCompleted.count + segmentCancelled.count
        return counts
    }

    /// Active tasks whose due date has passed (< todayISO).
    public var overdueTasks: [TaskItem] {
        guard case .loaded(let tasks) = loadState else { return [] }
        let today = Self.todayISO
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return tasks.filter { task in
            guard Self.matches(.today, task: task, todayISO: today) else { return false }
            guard Self.matches(.active, task: task) else { return false }
            guard let due = task.dueDate, due < today else { return false }
            guard !query.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(query)
        }
    }

    /// Active tasks scheduled precisely for today (== todayISO).
    public var todayScheduledTasks: [TaskItem] {
        guard case .loaded(let tasks) = loadState else { return [] }
        let today = Self.todayISO
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return tasks.filter { task in
            guard Self.matches(.today, task: task, todayISO: today) else { return false }
            guard Self.matches(.active, task: task) else { return false }
            guard task.dueDate == today else { return false }
            guard !query.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(query)
        }
    }

    /// The primary next task to tackle: highest priority scheduled task for today,
    /// or the highest priority overdue task if no today task exists.
    public var upNextTask: TaskItem? {
        func weight(_ p: TaskPriority?) -> Int {
            switch p {
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            case .some(.none), nil: return 0
            }
        }

        if !todayScheduledTasks.isEmpty {
            return todayScheduledTasks.max(by: { weight($0.priority) < weight($1.priority) })
        }
        if !overdueTasks.isEmpty {
            return overdueTasks.max(by: { weight($0.priority) < weight($1.priority) })
        }
        return nil
    }

    /// Helper computing relative due date description: e.g. "8d overdue", "Today", "Tomorrow", "Sep 2"
    public static func relativeDueDateDescription(
        dueDate: String?,
        todayISO: String = todayISO,
        calendar: Calendar = .current
    ) -> (text: String, isOverdue: Bool)? {
        guard let dueDate else { return nil }

        let formatter = isoDateFormatter
        guard let dueDateTime = formatter.date(from: dueDate),
              let todayDateTime = formatter.date(from: todayISO) else {
            return (dueDate, dueDate < todayISO)
        }

        let startOfDue = calendar.startOfDay(for: dueDateTime)
        let startOfToday = calendar.startOfDay(for: todayDateTime)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDue)
        guard let diff = components.day else {
            return (dueDate, dueDate < todayISO)
        }

        if diff < 0 {
            let daysOverdue = abs(diff)
            if daysOverdue > 90 {
                let monthDayFormatter = DateFormatter()
                monthDayFormatter.dateFormat = "MMM d"
                monthDayFormatter.locale = Locale(identifier: "en_US_POSIX")
                monthDayFormatter.timeZone = calendar.timeZone
                let dateStr = monthDayFormatter.string(from: startOfDue)
                return ("\(dateStr) • Overdue", true)
            } else {
                return ("\(daysOverdue)d overdue", true)
            }
        } else if diff == 0 {
            return ("Today", false)
        } else if diff == 1 {
            return ("Tomorrow", false)
        } else {
            let monthDayFormatter = DateFormatter()
            monthDayFormatter.dateFormat = "MMM d"
            monthDayFormatter.locale = Locale(identifier: "en_US_POSIX")
            monthDayFormatter.timeZone = calendar.timeZone
            return (monthDayFormatter.string(from: startOfDue), false)
        }
    }

    public func relativeDueDateDescription(for task: TaskItem) -> (text: String, isOverdue: Bool)? {
        Self.relativeDueDateDescription(dueDate: task.dueDate, todayISO: Self.todayISO)
    }

    private var candidateCompletedTasks: [TaskItem] {
        var seen = Set<UUID>()
        var list: [TaskItem] = []
        for task in completedTasks where task.isCompleted {
            if seen.insert(task.id).inserted {
                list.append(task)
            }
        }
        if case .loaded(let tasks) = loadState {
            for task in tasks where task.isCompleted {
                if seen.insert(task.id).inserted {
                    list.append(task)
                }
            }
        }
        return list
    }

    private var combinedAllTasks: [TaskItem] {
        var seen = Set<UUID>()
        var list: [TaskItem] = []
        if case .loaded(let tasks) = loadState {
            for task in tasks {
                if seen.insert(task.id).inserted {
                    list.append(task)
                }
            }
        }
        for task in completedTasks {
            if seen.insert(task.id).inserted {
                list.append(task)
            }
        }
        return list
    }

    /// Multi-dimensional filtered view of the loaded tasks:
    /// Conjunction of Date Segment, Status Filter, and Search Text.
    public var filteredTasks: [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let today = Self.todayISO

        let sourceTasks: [TaskItem]
        if dateSegment == .completed || statusFilter == .completed {
            sourceTasks = candidateCompletedTasks
        } else if statusFilter == .all {
            sourceTasks = combinedAllTasks
        } else {
            if case .loaded(let tasks) = loadState {
                sourceTasks = tasks.filter { Self.matches(statusFilter, task: $0) }
            } else {
                sourceTasks = []
            }
        }

        return sourceTasks.filter { task in
            if dateSegment != .completed {
                guard Self.matches(dateSegment, task: task, todayISO: today) else { return false }
            }
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
        case .completed:
            return task.isCompleted
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
            async let activeFetch = taskService.listActiveTasks()
            async let completedFetch = taskService.listCompletedTasks()
            let (active, completed) = try await (activeFetch, completedFetch)
            self.completedTasks = completed
            self.loadState = .loaded(active)
            FocusWidgetPublisher.publish(active)
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
        if let compIndex = completedTasks.firstIndex(where: { $0.id == task.id }) {
            completedTasks[compIndex] = task
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

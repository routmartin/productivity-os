import Foundation
import Observation

/// Goals & Projects view-only state.
///
/// Data flow:
///   1. `GET /api/v1/goals`     → `[Goal]`
///   2. `GET /api/v1/projects`  → `[Project]` (filtered by `goalId` per goal)
///   3. `GET /api/v1/projects/{id}/tasks` (per project) → `[TaskItem]`
///
/// Progress is derived client-side because the backend Goal/Project DTOs do
/// not expose a `progress` field. Project progress = completed tasks / total
/// non-cancelled tasks (or 100% when project status is COMPLETED, 0% when
/// DRAFT with no tasks yet). Goal progress is the unweighted mean of its
/// projects' progress.
@Observable
public final class GoalsViewModel {
    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    public private(set) var loadState: LoadState = .idle

    /// Goals in display order (the API returns all the user's goals; we hide
    /// archived goals behind a future filter, keeping only DRAFT / ACTIVE /
    /// COMPLETED in the read-only presentation per spec).
    public private(set) var goalCards: [GoalCardModel] = []
    public private(set) var overallProgress: OverallProgress = .empty

    /// All projects loaded for the user, keyed by ID.
    public private(set) var projectsById: [UUID: Project] = [:]
    /// Task counts and per-status breakdown per project.
    public private(set) var projectStats: [UUID: ProjectStats] = [:]

    private let goalService: GoalService
    private let projectService: ProjectService
    private let authSession: AuthSession

    /// Preview / design-review data.
    public init(
        apiClient: APIRequesting = APIClient.shared,
        authSession: AuthSession = .shared,
        preloadGoals: [Goal]? = nil,
        preloadProjects: [Project]? = nil,
        preloadProjectTasks: [UUID: [TaskItem]]? = nil
    ) {
        self.goalService = GoalService(apiClient: apiClient)
        self.projectService = ProjectService(apiClient: apiClient)
        self.authSession = authSession

        if let preloadGoals, let preloadProjects {
            self.projectsById = Dictionary(uniqueKeysWithValues: preloadProjects.map { ($0.id, $0) })
            if let preloadProjectTasks {
                for (projectId, tasks) in preloadProjectTasks {
                    projectStats[projectId] = ProjectStats(tasks: tasks)
                }
            }
            rebuildGoalCards(from: preloadGoals)
        }
    }

    public var isLoading: Bool {
        if case .loading = loadState { return true }
        return false
    }

    public var errorMessage: String? {
        if case .failed(let message) = loadState { return message }
        return nil
    }

    public var isEmpty: Bool {
        loadState == .loaded && goalCards.isEmpty
    }

    // MARK: - Loading

    public func loadData() async {
        guard authSession.isAuthenticated else { return }
        loadState = .loading
        do {
            let goals = try await goalService.listGoals()
            let projects = try await projectService.listProjects()

            projectsById = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

            // Fetch per-project tasks in parallel so progress is meaningful
            // without serialising N+1 round-trips.
            let projectIDs = projects.map(\.id)
            await loadProjectStats(for: projectIDs)

            rebuildGoalCards(from: goals)
            loadState = .loaded
        } catch {
            loadState = .failed(FocusSessionViewModel.userMessage(for: error))
        }
    }

    /// Bypasses the shared `APICache` and re-fetches everything. Used by
    /// pull-to-refresh and the toolbar refresh button.
    public func refresh() async {
        await APICache.shared.evict(prefix: "/api/v1/goals")
        await APICache.shared.evict(prefix: "/api/v1/projects")
        await loadData()
    }

    private func loadProjectStats(for projectIDs: [UUID]) async {
        await withTaskGroup(of: (UUID, ProjectStats).self) { group in
            for id in projectIDs {
                group.addTask { [projectService] in
                    do {
                        let tasks = try await projectService.listTasks(projectId: id)
                        return (id, ProjectStats(tasks: tasks))
                    } catch {
                        return (id, ProjectStats.empty)
                    }
                }
            }
            for await (id, stats) in group {
                projectStats[id] = stats
            }
        }
    }

    // MARK: - Card rebuild

    private func rebuildGoalCards(from goals: [Goal]) {
        let visibleGoals = goals.filter { $0.status != .archived }

        let cards: [GoalCardModel] = visibleGoals.map { goal in
            let projects = projectsById.values
                .filter { $0.goalId == goal.id && $0.status != .archived }
                .sorted { $0.createdAt < $1.createdAt }

            let projectSummaries = projects.map { project -> GoalCardModel.ProjectSummary in
                let stats = projectStats[project.id] ?? .empty
                return GoalCardModel.ProjectSummary(
                    project: project,
                    taskCount: stats.totalCount,
                    progress: progress(for: project, stats: stats)
                )
            }

            let aggregateProgress = projectSummaries.isEmpty
                ? 0
                : projectSummaries.map(\.progress).reduce(0, +) / Double(projectSummaries.count)

            return GoalCardModel(
                goal: goal,
                projects: projectSummaries,
                aggregateProgress: aggregateProgress
            )
        }

        goalCards = cards
        overallProgress = OverallProgress(from: cards.flatMap(\.projects))
    }

    /// Client-side progress. Returns `0.0…1.0` (`NaN`-safe).
    static func progressValue(completed: Int, total: Int, status: ProjectStatus) -> Double {
        if status == .completed { return 1 }
        if total == 0 { return 0 }
        return Double(completed) / Double(total)
    }

    private func progress(for project: Project, stats: ProjectStats) -> Double {
        Self.progressValue(
            completed: stats.completedCount,
            total: stats.totalCount,
            status: project.status
        )
    }

    // MARK: - Lookups

    public func goalCard(for id: UUID) -> GoalCardModel? {
        goalCards.first(where: { $0.goal.id == id })
    }

    public func project(for id: UUID) -> Project? {
        projectsById[id]
    }

    public func tasks(for projectId: UUID) -> [TaskItem] {
        projectStats[projectId]?.tasks ?? []
    }

    // MARK: - Formatting helpers

    public static func progressPercent(_ value: Double) -> Int {
        let clamped = max(0, min(1, value))
        return Int((clamped * 100).rounded())
    }

    public static func formatDeadline(_ date: Date?, now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    /// Human-friendly relative deadline ("Due Dec 31" / "Due in 3 days" / "Overdue").
    public static func relativeDeadline(_ date: Date?, now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let date else { return nil }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        if days < 0 {
            return "Overdue"
        }
        if days == 0 {
            return "Due today"
        }
        if days <= 14 {
            return "Due in \(days) day\(days == 1 ? "" : "s")"
        }
        return "Due \(formattedShortDate(date))"
    }

    private static func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Derived models

/// Goal + its projects (read-only presentation model).
public struct GoalCardModel: Identifiable, Hashable {
    public let goal: Goal
    public let projects: [ProjectSummary]
    public let aggregateProgress: Double

    public var id: UUID { goal.id }
    public var projectCount: Int { projects.count }

    public init(goal: Goal, projects: [ProjectSummary], aggregateProgress: Double) {
        self.goal = goal
        self.projects = projects
        self.aggregateProgress = aggregateProgress
    }

    public struct ProjectSummary: Identifiable, Hashable {
        public let project: Project
        public let taskCount: Int
        public let progress: Double

        public var id: UUID { project.id }

        public init(project: Project, taskCount: Int, progress: Double) {
            self.project = project
            self.taskCount = taskCount
            self.progress = progress
        }
    }
}

/// Overall (cross-goal) progress rolled up across all visible projects.
public struct OverallProgress: Hashable {
    public let completed: Int
    public let inProgress: Int
    public let notStarted: Int
    public let total: Int

    public static let empty = OverallProgress(completed: 0, inProgress: 0, notStarted: 0, total: 0)

    public init(completed: Int, inProgress: Int, notStarted: Int, total: Int) {
        self.completed = completed
        self.inProgress = inProgress
        self.notStarted = notStarted
        self.total = total
    }

    public var percent: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    public var hasData: Bool { total > 0 }

    init(from summaries: [GoalCardModel.ProjectSummary]) {
        var completed = 0
        var inProgress = 0
        var notStarted = 0
        var total = 0
        for summary in summaries {
            let status = summary.project.status
            if status == .completed { completed += 1; total += 1; continue }
            if status == .draft {
                notStarted += 1; total += 1; continue
            }
            if status == .archived { continue }
            // Active project: split by derived progress band.
            if summary.progress >= 0.999 {
                completed += 1
            } else if summary.progress <= 0.001 {
                notStarted += 1
            } else {
                inProgress += 1
            }
            total += 1
        }
        self.completed = completed
        self.inProgress = inProgress
        self.notStarted = notStarted
        self.total = total
    }
}

/// Per-project task breakdown.
public struct ProjectStats: Hashable {
    public let tasks: [TaskItem]
    public let completedCount: Int
    public let inProgressCount: Int
    public let totalCount: Int

    public static let empty = ProjectStats(tasks: [], completedCount: 0, inProgressCount: 0, totalCount: 0)

    public init(tasks: [TaskItem], completedCount: Int, inProgressCount: Int, totalCount: Int) {
        self.tasks = tasks
        self.completedCount = completedCount
        self.inProgressCount = inProgressCount
        self.totalCount = totalCount
    }

    init(tasks: [TaskItem]) {
        let active = tasks.filter { $0.status != .cancelled }
        self.tasks = active
        self.totalCount = active.count
        self.completedCount = active.filter { $0.status == .completed }.count
        self.inProgressCount = active.filter { $0.status == .inProgress }.count
    }
}
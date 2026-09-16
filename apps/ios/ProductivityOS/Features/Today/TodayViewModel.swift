import Foundation
import Observation

/// Today screen state. All data comes from the real API:
/// - Top 3 from `GET /daily-top-three/{date}` (+ task lookup for selection)
/// - Focus stats derived client-side from `GET /focus` sessions
/// Daily inspiration stays local — there is no backend contract for quotes.
@Observable
public final class TodayViewModel {
    public var userName: String
    public var intentionQuote: String = "Protect your attention.\nFocus on what matters now."
    public var intentionFooter: String = "Small steps. Deep focus. Real progress."

    public var topThreeTasks: [TaskItem] = []
    public var todayFocusedSeconds: TimeInterval = 0
    public var todayFocusProgress: Double = 0
    public var completedSessionsCount: Int = 0
    public var dayStreak: Int = 0
    public var weeklyFocusFormatted: String = "0h 0m"

    public private(set) var isLoading: Bool = false
    public var errorMessage: String?
    public var isEmpty: Bool { !isLoading && errorMessage == nil && topThreeTasks.isEmpty }

    private let taskService: TaskService
    private let topThreeService: TopThreeService
    private let focusService: FocusService
    private let authSession: AuthSession

    /// Loaded tasks cache so Top 3 selections pass full TaskItems into Focus.
    private var availableTasks: [TaskItem] = []
    private var loadedSessions: [FocusSession] = []

    public init(
        apiClient: APIRequesting = APIClient.shared,
        authSession: AuthSession = .shared,
        preloadTasks: [TaskItem]? = nil,
        preloadTopThree: [TaskItem]? = nil,
        preloadSessions: [FocusSession]? = nil
    ) {
        self.taskService = TaskService(apiClient: apiClient)
        self.topThreeService = TopThreeService(apiClient: apiClient)
        self.focusService = FocusService(apiClient: apiClient)
        self.authSession = authSession
        self.userName = authSession.currentUser?.displayName ?? "Rout"

        // Preview / design-review mode only.
        if let preloadTasks {
            self.availableTasks = preloadTasks
            self.topThreeTasks = Array(preloadTasks.prefix(3))
        }
        if let preloadSessions {
            applyStats(from: preloadSessions)
        }
    }

    public var formattedTodayFocusedTime: String {
        Self.formatFocusTime(todayFocusedSeconds)
    }

    public static func formatFocusTime(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    public func loadData() async {
        guard authSession.isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let topThree = topThreeService.today()
            async let tasks = taskService.listActiveTasks()
            async let sessions = focusService.listSessions(page: 0, size: 50)

            let (topThreeItems, loadedTasks, loadedSessions) = try await (topThree, tasks, sessions)
            self.availableTasks = loadedTasks
            self.loadedSessions = loadedSessions

            self.topThreeTasks = topThreeItems
                .filter { !$0.isDeleted && !$0.isCancelled }
                .sorted { $0.position < $1.position }
                .map { Self.taskItem(from: $0, in: loadedTasks) }

            userName = authSession.currentUser?.displayName ?? userName
            applyStats(from: loadedSessions)
        } catch {
            errorMessage = Self.userMessage(for: error)
        }
    }

    /// Bypasses the shared `APICache` for today's top-three, the active
    /// task list, and the recent focus sessions. Used by pull-to-refresh.
    public func refresh() async {
        await APICache.shared.evict(prefix: "/api/v1/daily-top-three")
        await APICache.shared.evict(prefix: "/api/v1/tasks")
        await APICache.shared.evict(prefix: "/api/v1/focus")
        await loadData()
    }

    // MARK: - Mapping helpers

    /// Maps a TopThreeItem to a TaskItem for the existing row UI and for
    /// handing the selected task into Focus. Prefers the real task when found.
    static func taskItem(from item: TopThreeItem, in tasks: [TaskItem]) -> TaskItem {
        if let taskId = item.taskId, let match = tasks.first(where: { $0.id == taskId }) {
            return match
        }
        return TaskItem(
            id: item.taskId ?? UUID(),
            title: item.taskTitle ?? "Task",
            priority: item.priority,
            status: item.isCompleted ? .completed : .pending,
            projectId: nil,
            projectName: item.projectName
        )
    }

    private func applyStats(from sessions: [FocusSession]) {
        let calendar = Calendar.current
        let now = Date()

        let ended = sessions.filter { $0.endedAt != nil }

        // A session whose wall-clock duration exceeds this cap is treated as
        // a ghost (app killed mid-session, never ended, force-quit, etc.).
        // We clamp it for aggregation so a 3-day forgotten session does not
        // swamp the user's real weekly total. The raw duration on the wire
        // is unchanged.
        let perSessionCap: TimeInterval = 8 * 60 * 60

        let cappedDuration: (FocusSession) -> TimeInterval = { session in
            let raw = TimeInterval(session.durationSeconds ?? 0)
            return min(raw, perSessionCap)
        }

        let todaySessions = ended.filter { session in
            calendar.isDate(session.startedAt, inSameDayAs: now)
        }
        completedSessionsCount = todaySessions.count
        todayFocusedSeconds = todaySessions.reduce(TimeInterval(0)) { total, session in
            total + cappedDuration(session)
        }

        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let weekSessions = ended.filter { $0.startedAt >= weekAgo }
        let weeklySeconds = weekSessions.reduce(TimeInterval(0)) { $0 + cappedDuration($1) }
        weeklyFocusFormatted = Self.formatFocusTime(weeklySeconds)

        // Placeholder daily target until the backend exposes a user-configurable
        // daily focus goal. The ring fills as today's focus approaches this
        // baseline (capped at 100%).
        let goalSeconds = Self.dailyFocusGoalSeconds
        todayFocusProgress = goalSeconds > 0 ? min(1, todayFocusedSeconds / goalSeconds) : 0

        dayStreak = Self.computeStreak(sessions: ended, calendar: calendar, reference: now)
    }

    /// Default daily focus target: 2 hours, expressed in seconds.
    static let dailyFocusGoalSeconds: TimeInterval = 2 * 60 * 60

    /// Consecutive days ending today (or yesterday, if today has no session yet)
    /// with at least one recorded session.
    static func computeStreak(sessions: [FocusSession], calendar: Calendar, reference: Date) -> Int {
        let daysWithSessions = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        var cursor = calendar.startOfDay(for: reference)
        if !daysWithSessions.contains(cursor) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor),
                  daysWithSessions.contains(previous) else { return 0 }
            cursor = previous
        }
        var streak = 0
        while daysWithSessions.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Something went wrong. Please try again."
        }
        return "Could not reach the server. Check your connection and try again."
    }
}

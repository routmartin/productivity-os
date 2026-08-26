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

        let ended = sessions.filter { !$0.isActive || $0.endedAt != nil }

        let todaySessions = ended.filter { session in
            calendar.isDate(session.startedAt, inSameDayAs: now)
        }
        completedSessionsCount = todaySessions.count
        todayFocusedSeconds = todaySessions.reduce(TimeInterval(0)) { total, session in
            total + TimeInterval(session.durationSeconds ?? 0)
        }

        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let weekSessions = ended.filter { $0.startedAt >= weekAgo }
        let weeklySeconds = weekSessions.reduce(TimeInterval(0)) { $0 + TimeInterval($1.durationSeconds ?? 0) }
        weeklyFocusFormatted = Self.formatFocusTime(weeklySeconds)

        // Ring shows today's share of this week's recorded focus
        // (data-derived placeholder until a daily-goal contract exists).
        todayFocusProgress = weeklySeconds > 0 ? min(1, todayFocusedSeconds / weeklySeconds) : 0

        dayStreak = Self.computeStreak(sessions: ended, calendar: calendar, reference: now)
    }

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

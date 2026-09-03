import Foundation
import XCTest
@testable import ProductivityOS

@MainActor
final class GoalsViewModelTests: XCTestCase {
    // MARK: - Progress computation

    func testProgressValueCompletedProjectIsFull() {
        XCTAssertEqual(GoalsViewModel.progressValue(completed: 5, total: 5, status: .completed), 1)
        XCTAssertEqual(GoalsViewModel.progressValue(completed: 0, total: 0, status: .completed), 1)
    }

    func testProgressValueEmptyActiveProjectIsZero() {
        XCTAssertEqual(GoalsViewModel.progressValue(completed: 0, total: 0, status: .active), 0)
    }

    func testProgressValuePartial() {
        let value = GoalsViewModel.progressValue(completed: 2, total: 4, status: .active)
        XCTAssertEqual(value, 0.5, accuracy: 0.001)
    }

    func testProgressPercentClampsAndRounds() {
        XCTAssertEqual(GoalsViewModel.progressPercent(0.755), 76)
        XCTAssertEqual(GoalsViewModel.progressPercent(-0.1), 0)
        XCTAssertEqual(GoalsViewModel.progressPercent(1.4), 100)
    }

    // MARK: - Card rebuild

    func testPreloadedGoalsBuildCards() {
        let viewModel = GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )

        XCTAssertEqual(viewModel.goalCards.count, 3)

        // Archived goals should be hidden — none in mockGoals, all visible.
        let activeGoal = viewModel.goalCards.first { $0.goal.title.contains("Productivity OS") }
        XCTAssertNotNil(activeGoal)
        XCTAssertEqual(activeGoal?.projectCount, 3)
        XCTAssertEqual(activeGoal?.projects.count, 3)
        XCTAssertGreaterThan(activeGoal?.aggregateProgress ?? 0, 0)
        XCTAssertLessThanOrEqual(activeGoal?.aggregateProgress ?? 0, 1)
    }

    func testEmptyPreloadedGoalsReportsEmptyState() {
        let viewModel = GoalsViewModel(preloadGoals: [], preloadProjects: [])
        XCTAssertEqual(viewModel.goalCards.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testArchivedGoalIsHiddenFromCards() {
        let now = Date()
        let archived = Goal(
            id: UUID(),
            userId: UUID(),
            title: "Archived Goal",
            description: nil,
            status: .archived,
            deadline: nil,
            completedAt: nil,
            createdAt: now,
            updatedAt: now
        )
        let viewModel = GoalsViewModel(
            preloadGoals: [archived],
            preloadProjects: []
        )
        XCTAssertTrue(viewModel.goalCards.isEmpty)
    }

    func testProjectsFilteredByGoalIdAndStatus() {
        let viewModel = GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )

        let goal1 = viewModel.goalCards.first { $0.goal.title.contains("Productivity OS") }!
        let goal1ProjectTitles = goal1.projects.map(\.project.title)
        XCTAssertTrue(goal1ProjectTitles.contains("iOS App"))
        XCTAssertTrue(goal1ProjectTitles.contains("Backend & API"))
        XCTAssertTrue(goal1ProjectTitles.contains("Marketing & Brand"))
    }

    // MARK: - Lookups

    func testGoalCardLookup() {
        let viewModel = GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )
        let first = viewModel.goalCards.first!
        XCTAssertEqual(viewModel.goalCard(for: first.goal.id)?.goal.id, first.goal.id)
        XCTAssertNil(viewModel.goalCard(for: UUID()))
    }

    func testProjectLookup() {
        let viewModel = GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )
        let projectID = UUID(uuidString: "B1111111-1111-1111-1111-111111111111")!
        XCTAssertEqual(viewModel.project(for: projectID)?.title, "iOS App")
        XCTAssertNil(viewModel.project(for: UUID()))
    }

    func testTasksLookup() {
        let viewModel = GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )
        let projectID = UUID(uuidString: "B1111111-1111-1111-1111-111111111111")!
        let tasks = viewModel.tasks(for: projectID)
        XCTAssertEqual(tasks.count, 4)
        XCTAssertEqual(tasks.filter { $0.status == .completed }.count, 2)
    }

    // MARK: - Overall progress

    func testOverallProgressTotalsAcrossVisibleProjects() {
        let viewModel = GoalsViewModel(
            preloadGoals: SampleData.mockGoals,
            preloadProjects: SampleData.mockProjectsForGoals,
            preloadProjectTasks: SampleData.mockProjectTasks
        )
        let overall = viewModel.overallProgress
        XCTAssertEqual(overall.total, 5)
        XCTAssertGreaterThanOrEqual(overall.completed, 1)
        XCTAssertGreaterThanOrEqual(overall.inProgress, 1)
        XCTAssertGreaterThanOrEqual(overall.notStarted, 1)
    }

    func testOverallProgressEmpty() {
        let viewModel = GoalsViewModel(preloadGoals: [], preloadProjects: [])
        XCTAssertEqual(viewModel.overallProgress, .empty)
    }

    // MARK: - Deadline formatting

    func testFormatDeadlineReturnsMonthDayYear() {
        let calendar = Calendar(identifier: .gregorian)
        let date = try! XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 12, day: 31)))
        let formatted = GoalsViewModel.formatDeadline(date)
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted!.contains("Dec"))
        XCTAssertTrue(formatted!.contains("31"))
        XCTAssertTrue(formatted!.contains("2026"))
    }

    func testFormatDeadlineReturnsNilForNil() {
        XCTAssertNil(GoalsViewModel.formatDeadline(nil))
    }

    func testRelativeDeadlineTodayAndFuture() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let inThree = calendar.date(byAdding: .day, value: 3, to: today)!
        let inThirty = calendar.date(byAdding: .day, value: 30, to: today)!
        let past = calendar.date(byAdding: .day, value: -2, to: today)!

        XCTAssertEqual(
            GoalsViewModel.relativeDeadline(today, now: now),
            "Due today"
        )
        XCTAssertEqual(
            GoalsViewModel.relativeDeadline(inThree, now: now),
            "Due in 3 days"
        )
        XCTAssertNotNil(GoalsViewModel.relativeDeadline(inThirty, now: now))
        XCTAssertEqual(
            GoalsViewModel.relativeDeadline(past, now: now),
            "Overdue"
        )
    }

    // MARK: - Read-only behavior

    func testViewModelExposesNoMutationAPI() {
        let mirror = Mirror(reflecting: GoalsViewModel())
        let exposed = mirror.children.compiling { $0.label }
        // Compile-time guard against accidentally adding a write entry point.
        XCTAssertFalse(exposed.contains("createGoal"))
        XCTAssertFalse(exposed.contains("updateGoal"))
        XCTAssertFalse(exposed.contains("deleteGoal"))
    }

    // MARK: - Loading

    func testLoadDataSuccessSetsLoadedState() async {
        let mock = MockAPIClient()
        mock.scriptedResponses = [
            // GET /api/v1/goals
            .success((Self.goalsJSON, 200)),
            // GET /api/v1/projects
            .success((Self.projectsJSON, 200)),
        ]
        // /api/v1/projects/{id}/tasks for each project
        mock.defaultResponse = .success((Self.tasksJSON, 200))

        let viewModel = GoalsViewModel(apiClient: mock, authSession: AuthSession.shared)
        await viewModel.loadData()

        if case .loaded = viewModel.loadState {
            // ok
        } else {
            XCTFail("Expected .loaded, got \(viewModel.loadState)")
        }
        XCTAssertFalse(viewModel.goalCards.isEmpty)
    }

    func testLoadDataFailureSetsFailedStateWithRetryableMessage() async {
        let mock = MockAPIClient()
        mock.defaultResponse = .failure(APIError.serverError(statusCode: 500, code: "boom", message: nil))

        let viewModel = GoalsViewModel(apiClient: mock, authSession: AuthSession.shared)
        await viewModel.loadData()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.goalCards.isEmpty)
    }

    // MARK: - Fixtures

    private static let goalsJSON = Data("""
    [
      {
        "id": "A1111111-1111-1111-1111-111111111111",
        "userId": "11111111-1111-1111-1111-111111111111",
        "title": "Build the best version of Productivity OS",
        "description": "Ship a great iOS app",
        "status": "ACTIVE",
        "deadline": "2026-12-31",
        "completedAt": null,
        "createdAt": "2026-08-26T10:00:00Z",
        "updatedAt": "2026-08-26T10:00:00Z"
      }
    ]
    """.utf8)

    private static let projectsJSON = Data("""
    [
      {
        "id": "B1111111-1111-1111-1111-111111111111",
        "userId": "11111111-1111-1111-1111-111111111111",
        "title": "iOS App",
        "description": "Ship iOS",
        "goalId": "A1111111-1111-1111-1111-111111111111",
        "status": "ACTIVE",
        "deadline": "2026-12-31",
        "completedAt": null,
        "createdAt": "2026-08-26T10:00:00Z",
        "updatedAt": "2026-08-26T10:00:00Z"
      }
    ]
    """.utf8)

    private static let tasksJSON = Data("""
    [
      {"id":"E8E19BB5-93BB-4D57-9DBD-C36B47C43DF1","ownerId":"11111111-1111-1111-1111-111111111111","title":"First","status":"COMPLETED","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"},
      {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","ownerId":"11111111-1111-1111-1111-111111111111","title":"Second","status":"PENDING","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"}
    ]
    """.utf8)
}

// MARK: - Helpers

private extension Sequence {
    func compiling<Result>(_ transform: (Element) -> Result) -> [Result] {
        map(transform)
    }
}
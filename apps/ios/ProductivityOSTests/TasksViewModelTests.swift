import Foundation
import XCTest
@testable import ProductivityOS

final class TasksViewModelTests: XCTestCase {
    func testDateSegmentFilterProperties() {
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.allCases, [.today, .upcoming, .backlog, .all])
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.today.title, "Today")
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.upcoming.title, "Upcoming")
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.backlog.title, "Backlog")
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.all.title, "All")

        let vm = TasksViewModel(taskService: TaskService(apiClient: MockAPIClient(), cache: APICache()))
        XCTAssertEqual(vm.dateSegment, .today, "North Star default must be .today")
    }

    func testSegmentCountsForActiveTasks() async {
        let mock = MockAPIClient()
        let today = TasksViewModel.todayISO
        let tomorrow = TasksViewModel.tomorrowISO

        let taskToday = TaskItem(id: UUID(), title: "Today task", dueDate: today, status: .planned)
        let taskOverdue = TaskItem(id: UUID(), title: "Overdue task", dueDate: "2020-01-01", status: .inProgress)
        let taskUpcoming = TaskItem(id: UUID(), title: "Upcoming task", dueDate: tomorrow, status: .planned)
        let taskBacklog = TaskItem(id: UUID(), title: "Backlog task", dueDate: nil, status: .planned)
        let taskCompleted = TaskItem(id: UUID(), title: "Completed task", dueDate: today, status: .completed)
        let taskCancelled = TaskItem(id: UUID(), title: "Cancelled task", dueDate: today, status: .cancelled)

        let taskService = TaskService(apiClient: mock, cache: APICache())
        let vm = TasksViewModel(taskService: taskService)
        // Before loading, counts are 0
        XCTAssertEqual(vm.segmentCounts[.today], 0)
        XCTAssertEqual(vm.segmentCounts[.upcoming], 0)
        XCTAssertEqual(vm.segmentCounts[.backlog], 0)
        XCTAssertEqual(vm.segmentCounts[.all], 0)

        // Inject loaded tasks
        let allTasks = [taskToday, taskOverdue, taskUpcoming, taskBacklog, taskCompleted, taskCancelled]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(allTasks)
        mock.defaultResponse = .success((data, 200))
        await vm.loadTasks()

        let counts = vm.segmentCounts
        // Today captures today + overdue active tasks (2). Completed/cancelled excluded.
        XCTAssertEqual(counts[.today], 2)
        // Upcoming captures future active tasks (1).
        XCTAssertEqual(counts[.upcoming], 1)
        // Backlog captures nil-dueDate active tasks (1).
        XCTAssertEqual(counts[.backlog], 1)
        // All captures all active tasks (4).
        XCTAssertEqual(counts[.all], 4)
    }

    func testFilteredTasksFiltering() async {
        let mock = MockAPIClient()
        let today = TasksViewModel.todayISO
        let tomorrow = TasksViewModel.tomorrowISO

        let taskToday = TaskItem(id: UUID(), title: "Today task", dueDate: today, status: .planned)
        let taskOverdue = TaskItem(id: UUID(), title: "Overdue task", dueDate: "2020-01-01", status: .inProgress)
        let taskUpcoming = TaskItem(id: UUID(), title: "Upcoming task", dueDate: tomorrow, status: .planned)
        let taskBacklog = TaskItem(id: UUID(), title: "Backlog task", dueDate: nil, status: .planned)
        let taskCompleted = TaskItem(id: UUID(), title: "Completed task", dueDate: today, status: .completed)

        let allTasks = [taskToday, taskOverdue, taskUpcoming, taskBacklog, taskCompleted]
        let data = try! JSONEncoder().encode(allTasks)
        mock.defaultResponse = .success((data, 200))

        let taskService = TaskService(apiClient: mock, cache: APICache())
        let vm = TasksViewModel(taskService: taskService)
        await vm.loadTasks()

        // 1. Default: .today dateSegment and .active statusFilter
        vm.dateSegment = .today
        vm.statusFilter = .active
        let todayTasks = vm.filteredTasks
        XCTAssertEqual(todayTasks.count, 2)
        XCTAssertTrue(todayTasks.contains(where: { $0.id == taskToday.id }))
        XCTAssertTrue(todayTasks.contains(where: { $0.id == taskOverdue.id }))

        // 2. Upcoming
        vm.dateSegment = .upcoming
        let upcomingTasks = vm.filteredTasks
        XCTAssertEqual(upcomingTasks.count, 1)
        XCTAssertEqual(upcomingTasks.first?.id, taskUpcoming.id)

        // 3. Backlog
        vm.dateSegment = .backlog
        let backlogTasks = vm.filteredTasks
        XCTAssertEqual(backlogTasks.count, 1)
        XCTAssertEqual(backlogTasks.first?.id, taskBacklog.id)

        // 4. All
        vm.dateSegment = .all
        let allFiltered = vm.filteredTasks
        XCTAssertEqual(allFiltered.count, 4) // 4 active tasks

        // 5. Status filter conjunction: completed
        vm.dateSegment = .today
        vm.statusFilter = .completed
        let completedToday = vm.filteredTasks
        XCTAssertEqual(completedToday.count, 1)
        XCTAssertEqual(completedToday.first?.id, taskCompleted.id)

        // 6. Search conjunction
        vm.dateSegment = .today
        vm.statusFilter = .active
        vm.searchText = "Overdue"
        let searched = vm.filteredTasks
        XCTAssertEqual(searched.count, 1)
        XCTAssertEqual(searched.first?.id, taskOverdue.id)
    }

    func testRescheduleTaskUpdatesDateAndLocalState() async throws {
        let mock = MockAPIClient()
        let taskId = UUID()
        let initial = TaskItem(
            id: taskId,
            title: "Plan project",
            description: "Some notes",
            dueDate: nil,
            priority: .high,
            energy: .medium,
            estimatedDurationMinutes: 60,
            status: .planned
        )

        let initialData = try! JSONEncoder().encode([initial])
        mock.defaultResponse = .success((initialData, 200))

        let taskService = TaskService(apiClient: mock, cache: APICache())
        let vm = TasksViewModel(taskService: taskService)
        await vm.loadTasks()
        XCTAssertEqual(vm.filteredTasks.count, 0) // because default dateSegment is .today, and initial is in backlog

        vm.dateSegment = .backlog
        XCTAssertEqual(vm.filteredTasks.count, 1)

        // Mock PUT response with new due date
        let updatedDate = TasksViewModel.todayISO
        let updatedTask = TaskItem(
            id: taskId,
            title: "Plan project",
            description: "Some notes",
            dueDate: updatedDate,
            priority: .high,
            energy: .medium,
            estimatedDurationMinutes: 60,
            status: .planned
        )
        let updatedData = try! JSONEncoder().encode(updatedTask)
        mock.defaultResponse = .success((updatedData, 200))

        try await vm.rescheduleTask(id: taskId, dueDate: updatedDate)

        // Task should now be in .today, not .backlog
        vm.dateSegment = .backlog
        XCTAssertEqual(vm.filteredTasks.count, 0)

        vm.dateSegment = .today
        XCTAssertEqual(vm.filteredTasks.count, 1)
        XCTAssertEqual(vm.filteredTasks.first?.dueDate, updatedDate)

        // Verify request payload
        let lastRequest = try XCTUnwrap(mock.recordedRequests.last)
        XCTAssertEqual(lastRequest.method, "PUT")
        XCTAssertEqual(lastRequest.path, "/api/v1/tasks/\(taskId.uuidString.lowercased())")
        let body = try JSONDecoder().decode(UpdateTaskRequestBody.self, from: XCTUnwrap(lastRequest.body))
        XCTAssertEqual(body.dueDate, updatedDate)
        XCTAssertEqual(body.title, "Plan project")
        XCTAssertEqual(body.priority, "HIGH")
    }
}

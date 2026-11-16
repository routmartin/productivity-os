import Foundation
import XCTest
@testable import ProductivityOS

final class TasksViewModelTests: XCTestCase {
    func testDateSegmentFilterProperties() {
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.allCases, [.today, .upcoming, .backlog, .completed, .all])
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.today.title, "Today")
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.upcoming.title, "Upcoming")
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.backlog.title, "Backlog")
        XCTAssertEqual(TasksViewModel.DateSegmentFilter.completed.title, "Done")
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
        XCTAssertEqual(vm.segmentCounts[.completed], 0)
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
        // Completed captures completed tasks (1).
        XCTAssertEqual(counts[.completed], 1)
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

    func testStatusCountsWithinDateSegment() async {
        let mock = MockAPIClient()
        let today = TasksViewModel.todayISO
        let tomorrow = TasksViewModel.tomorrowISO

        let activeToday1 = TaskItem(id: UUID(), title: "Active today 1", dueDate: today, status: .planned)
        let activeToday2 = TaskItem(id: UUID(), title: "Active today 2", dueDate: today, status: .inProgress)
        let overdueToday = TaskItem(id: UUID(), title: "Overdue today", dueDate: "2026-11-06", status: .planned)
        let completedToday = TaskItem(id: UUID(), title: "Completed today", dueDate: today, status: .completed)
        let cancelledToday = TaskItem(id: UUID(), title: "Cancelled today", dueDate: today, status: .cancelled)

        let activeUpcoming = TaskItem(id: UUID(), title: "Active upcoming", dueDate: tomorrow, status: .planned)
        let completedUpcoming = TaskItem(id: UUID(), title: "Completed upcoming", dueDate: tomorrow, status: .completed)

        let allActive = [activeToday1, activeToday2, overdueToday, cancelledToday, activeUpcoming]
        let allCompleted = [completedToday, completedUpcoming]

        let encoder = JSONEncoder()
        let activeData = try! encoder.encode(allActive)
        mock.defaultResponse = .success((activeData, 200))

        let vm = TasksViewModel(taskService: TaskService(apiClient: mock, cache: APICache()))
        await vm.loadTasks()

        // Test Today segment status counts
        vm.dateSegment = .today
        let todayCounts = vm.statusCounts
        // active Today: activeToday1, activeToday2, overdueToday (3)
        XCTAssertEqual(todayCounts[.active], 3)
        // cancelled Today: cancelledToday (1)
        XCTAssertEqual(todayCounts[.cancelled], 1)
        // all Today: active (3) + completed (0 from activeList) + cancelled (1) = 4 (or + completed if present)

        // Inject completed tasks
        let completedData = try! encoder.encode(allCompleted)
        let mock2 = MockAPIClient()
        mock2.responsesByPath = [
            "/api/v1/tasks": .success((activeData, 200)),
            "/api/v1/tasks/completed": .success((completedData, 200))
        ]
        let completedService = TaskService(apiClient: mock2, cache: APICache())
        let vm2 = TasksViewModel(taskService: completedService)
        await vm2.loadTasks()
        vm2.dateSegment = .today
        let countsWithCompleted = vm2.statusCounts
        XCTAssertEqual(countsWithCompleted[.active], 3)
        XCTAssertEqual(countsWithCompleted[.completed], 1)
        XCTAssertEqual(countsWithCompleted[.cancelled], 1)
        XCTAssertEqual(countsWithCompleted[.all], 5)

        // Test Upcoming segment status counts
        vm2.dateSegment = .upcoming
        let upcomingCounts = vm2.statusCounts
        XCTAssertEqual(upcomingCounts[.active], 1)
        XCTAssertEqual(upcomingCounts[.completed], 1)
        XCTAssertEqual(upcomingCounts[.cancelled], 0)
        XCTAssertEqual(upcomingCounts[.all], 2)
    }

    func testOverdueAndTodaySeparation() async {
        let mock = MockAPIClient()
        let today = TasksViewModel.todayISO

        let overdueTask1 = TaskItem(id: UUID(), title: "Overdue 8d", dueDate: "2026-11-06", priority: .high, status: .planned)
        let overdueTask2 = TaskItem(id: UUID(), title: "Overdue 73d", dueDate: "2026-09-02", priority: .low, status: .planned)
        let todayTask1 = TaskItem(id: UUID(), title: "Today task high", dueDate: today, priority: .high, status: .planned)
        let todayTask2 = TaskItem(id: UUID(), title: "Today task medium", dueDate: today, priority: .medium, status: .planned)

        let tasks = [overdueTask1, overdueTask2, todayTask1, todayTask2]
        let data = try! JSONEncoder().encode(tasks)
        mock.defaultResponse = .success((data, 200))

        let vm = TasksViewModel(taskService: TaskService(apiClient: mock, cache: APICache()))
        await vm.loadTasks()

        vm.dateSegment = .today
        XCTAssertEqual(vm.overdueTasks.count, 2)
        XCTAssertTrue(vm.overdueTasks.contains(where: { $0.id == overdueTask1.id }))
        XCTAssertTrue(vm.overdueTasks.contains(where: { $0.id == overdueTask2.id }))

        XCTAssertEqual(vm.todayScheduledTasks.count, 2)
        XCTAssertTrue(vm.todayScheduledTasks.contains(where: { $0.id == todayTask1.id }))
        XCTAssertTrue(vm.todayScheduledTasks.contains(where: { $0.id == todayTask2.id }))
    }

    func testUpNextTaskSelection() async {
        let mock = MockAPIClient()
        let today = TasksViewModel.todayISO

        let todayLow = TaskItem(id: UUID(), title: "Low today", dueDate: today, priority: .low, status: .planned)
        let todayHigh = TaskItem(id: UUID(), title: "High today", dueDate: today, priority: .high, status: .planned)
        let overdueHigh = TaskItem(id: UUID(), title: "Overdue high", dueDate: "2026-11-06", priority: .high, status: .planned)

        // 1. When today task exists, pick highest priority today task
        let data = try! JSONEncoder().encode([todayLow, todayHigh, overdueHigh])
        mock.defaultResponse = .success((data, 200))

        let vm = TasksViewModel(taskService: TaskService(apiClient: mock, cache: APICache()))
        await vm.loadTasks()
        vm.dateSegment = .today

        XCTAssertEqual(vm.upNextTask?.id, todayHigh.id)

        // 2. When no today tasks, fallback to overdue task
        let overdueOnly = try! JSONEncoder().encode([overdueHigh])
        mock.defaultResponse = .success((overdueOnly, 200))
        let vm2 = TasksViewModel(taskService: TaskService(apiClient: mock, cache: APICache()))
        await vm2.loadTasks()
        vm2.dateSegment = .today

        XCTAssertEqual(vm2.upNextTask?.id, overdueHigh.id)

        // 3. When empty
        mock.defaultResponse = .success((Data("[]".utf8), 200))
        let vm3 = TasksViewModel(taskService: TaskService(apiClient: mock, cache: APICache()))
        await vm3.loadTasks()
        vm3.dateSegment = .today

        XCTAssertNil(vm3.upNextTask)
    }

    func testRelativeDueDateDescription() {
        let today = "2026-11-14"

        // 8 days overdue
        let overdue8 = TasksViewModel.relativeDueDateDescription(dueDate: "2026-11-06", todayISO: today)
        XCTAssertEqual(overdue8?.text, "8d overdue")
        XCTAssertEqual(overdue8?.isOverdue, true)

        // Today
        let todayDesc = TasksViewModel.relativeDueDateDescription(dueDate: "2026-11-14", todayISO: today)
        XCTAssertEqual(todayDesc?.text, "Today")
        XCTAssertEqual(todayDesc?.isOverdue, false)

        // Tomorrow
        let tomorrowDesc = TasksViewModel.relativeDueDateDescription(dueDate: "2026-11-15", todayISO: today)
        XCTAssertEqual(tomorrowDesc?.text, "Tomorrow")
        XCTAssertEqual(tomorrowDesc?.isOverdue, false)

        // Far overdue (> 90 days)
        let farOverdue = TasksViewModel.relativeDueDateDescription(dueDate: "2026-08-01", todayISO: today)
        XCTAssertTrue(farOverdue?.text.contains("Overdue") == true)
        XCTAssertEqual(farOverdue?.isOverdue, true)

        // Nil dueDate
        XCTAssertNil(TasksViewModel.relativeDueDateDescription(dueDate: nil, todayISO: today))
    }

    func testFormattedDuration() {
        let task30 = TaskItem(title: "Task 1", estimatedDurationMinutes: 30)
        XCTAssertEqual(task30.formattedDuration, "30m")

        let task45 = TaskItem(title: "Task 2", estimatedDurationMinutes: 45)
        XCTAssertEqual(task45.formattedDuration, "45m")

        let task60 = TaskItem(title: "Task 3", estimatedDurationMinutes: 60)
        XCTAssertEqual(task60.formattedDuration, "1h")

        let task90 = TaskItem(title: "Task 4", estimatedDurationMinutes: 90)
        XCTAssertEqual(task90.formattedDuration, "1h 30m")

        let taskDefault = TaskItem(title: "Task 5", estimatedDurationMinutes: nil)
        XCTAssertEqual(taskDefault.formattedDuration, "30m")
    }
}

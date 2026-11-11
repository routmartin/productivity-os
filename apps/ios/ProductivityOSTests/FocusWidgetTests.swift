import XCTest
#if canImport(FocusWidgetShared)
import FocusWidgetShared
#endif
@testable import ProductivityOS

final class FocusWidgetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FocusWidgetSnapshot.clear()
    }

    override func tearDown() {
        FocusWidgetSnapshot.clear()
        super.tearDown()
    }

    // MARK: - 1. JSON Encoding & Decoding

    func testSnapshotJSONEncodingAndDecoding() throws {
        let task1 = FocusWidgetTask(
            id: UUID(),
            title: "Write design doc",
            projectName: "Productivity OS",
            priority: "HIGH",
            isCompleted: false
        )
        let task2 = FocusWidgetTask(
            id: UUID(),
            title: "Review pull request",
            projectName: "Mobile",
            priority: "MEDIUM",
            isCompleted: false
        )

        let timestamp = Date(timeIntervalSince1970: 1700000000)
        let originalSnapshot = FocusWidgetSnapshot(tasks: [task1, task2], updatedAt: timestamp)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalSnapshot)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedSnapshot = try decoder.decode(FocusWidgetSnapshot.self, from: data)

        XCTAssertEqual(decodedSnapshot.tasks.count, 2)
        XCTAssertEqual(decodedSnapshot.tasks[0].id, task1.id)
        XCTAssertEqual(decodedSnapshot.tasks[0].title, task1.title)
        XCTAssertEqual(decodedSnapshot.tasks[0].projectName, task1.projectName)
        XCTAssertEqual(decodedSnapshot.tasks[0].priority, task1.priority)
        XCTAssertEqual(decodedSnapshot.tasks[0].isCompleted, task1.isCompleted)

        XCTAssertEqual(decodedSnapshot.tasks[1].id, task2.id)
        XCTAssertEqual(decodedSnapshot.tasks[1].title, task2.title)
        XCTAssertEqual(decodedSnapshot.tasks[1].projectName, task2.projectName)
        XCTAssertEqual(decodedSnapshot.tasks[1].priority, task2.priority)
        XCTAssertEqual(decodedSnapshot.tasks[1].isCompleted, task2.isCompleted)

        XCTAssertEqual(decodedSnapshot.updatedAt.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - 2. Task Mapping and Filtering

    func testTaskMappingAndFilteringIgnoresCompletedCancelledOrDeleted() {
        let activeTask = TaskItem(
            id: UUID(),
            title: "Active task",
            priority: .high,
            status: .pending,
            projectName: "Core",
            createdAt: Date()
        )
        let completedTaskStatus = TaskItem(
            id: UUID(),
            title: "Completed status task",
            status: .completed,
            createdAt: Date()
        )
        let completedDateTask = TaskItem(
            id: UUID(),
            title: "Completed date task",
            status: .pending,
            completedAt: Date(),
            createdAt: Date()
        )
        let cancelledTask = TaskItem(
            id: UUID(),
            title: "Cancelled task",
            status: .cancelled,
            createdAt: Date()
        )
        let deletedTask = TaskItem(
            id: UUID(),
            title: "Deleted task",
            status: .pending,
            deletedAt: Date(),
            createdAt: Date()
        )

        let allTasks = [activeTask, completedTaskStatus, completedDateTask, cancelledTask, deletedTask]
        let mapped = FocusWidgetPublisher.mapAndFilter(allTasks)

        XCTAssertEqual(mapped.count, 1)
        XCTAssertEqual(mapped.first?.id, activeTask.id)
        XCTAssertEqual(mapped.first?.title, "Active task")
        XCTAssertEqual(mapped.first?.projectName, "Core")
        XCTAssertEqual(mapped.first?.priority, TaskPriority.high.rawValue)
        XCTAssertFalse(mapped.first?.isCompleted ?? true)
    }

    // MARK: - 3. Newest-First Sorting

    func testNewestFirstSorting() {
        let now = Date()
        let oldest = TaskItem(
            id: UUID(),
            title: "Oldest task",
            status: .pending,
            createdAt: now.addingTimeInterval(-3600 * 24 * 3)
        )
        let middle = TaskItem(
            id: UUID(),
            title: "Middle task",
            status: .pending,
            createdAt: now.addingTimeInterval(-3600 * 24)
        )
        let newest = TaskItem(
            id: UUID(),
            title: "Newest task",
            status: .pending,
            createdAt: now
        )

        let mapped = FocusWidgetPublisher.mapAndFilter([oldest, newest, middle])

        XCTAssertEqual(mapped.count, 3)
        XCTAssertEqual(mapped[0].id, newest.id)
        XCTAssertEqual(mapped[1].id, middle.id)
        XCTAssertEqual(mapped[2].id, oldest.id)
    }

    // MARK: - 4. Capping at FocusWidgetSnapshot.maxTasks (3 tasks)

    func testCappingAtMaxTasks() {
        let now = Date()
        let tasks = (0..<6).map { index in
            TaskItem(
                id: UUID(),
                title: "Task \(index)",
                status: .pending,
                createdAt: now.addingTimeInterval(Double(index * 60))
            )
        }

        XCTAssertEqual(FocusWidgetSnapshot.maxTasks, 3)

        let mapped = FocusWidgetPublisher.mapAndFilter(tasks)

        XCTAssertEqual(mapped.count, FocusWidgetSnapshot.maxTasks)
        // Since newest is first, tasks[5], tasks[4], tasks[3] should be chosen
        XCTAssertEqual(mapped[0].id, tasks[5].id)
        XCTAssertEqual(mapped[1].id, tasks[4].id)
        XCTAssertEqual(mapped[2].id, tasks[3].id)
    }

    // MARK: - 5. Snapshot Clearing on Logout

    func testSnapshotClearingOnLogout() async {
        let task = TaskItem(
            id: UUID(),
            title: "Widget task",
            status: .pending,
            createdAt: Date()
        )

        FocusWidgetPublisher.publish([task])
        let loadedBefore = FocusWidgetSnapshot.load()
        XCTAssertNotNil(loadedBefore)
        XCTAssertEqual(loadedBefore?.tasks.count, 1)
        XCTAssertEqual(loadedBefore?.tasks.first?.id, task.id)

        // Clear snapshot (as called during logout in AuthService)
        FocusWidgetPublisher.clear()

        let loadedAfter = FocusWidgetSnapshot.load()
        XCTAssertNil(loadedAfter)
    }
}

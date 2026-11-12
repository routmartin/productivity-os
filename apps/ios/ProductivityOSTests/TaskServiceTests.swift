import Foundation
import XCTest
@testable import ProductivityOS

final class TaskServiceTests: XCTestCase {
    func testListActiveTasksDecodesPlainArray() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            [
              {"id":"E8E19BB5-93BB-4D57-9DBD-C36B47C43DF1","ownerId":"F7D2A8B3-11BB-4D57-9DBD-C36B47C43DF2","title":"First","priority":"LOW","status":"PENDING","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"},
              {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","ownerId":"F7D2A8B3-11BB-4D57-9DBD-C36B47C43DF2","title":"Second","status":"IN_PROGRESS","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"}
            ]
            """.utf8),
            200
        ))

        let tasks = try await TaskService(apiClient: mock, cache: APICache()).listActiveTasks()

        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks[0].title, "First")
        XCTAssertEqual(tasks[0].priority, .low)
        XCTAssertEqual(tasks[1].status, .inProgress)

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/tasks")
    }

    func testEmptyTaskList() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((Data("[]".utf8), 200))

        let tasks = try await TaskService(apiClient: mock, cache: APICache()).listActiveTasks()
        XCTAssertTrue(tasks.isEmpty)
    }

    func testUpdateTaskWithDueDateEncodesPayload() async throws {
        let mock = MockAPIClient()
        let taskId = UUID(uuidString: "E8E19BB5-93BB-4D57-9DBD-C36B47C43DF1")!
        mock.defaultResponse = .success((
            Data("""
            {
              "id":"\(taskId.uuidString)",
              "title":"Updated",
              "description":"Desc",
              "dueDate":"2026-11-12",
              "priority":"HIGH",
              "energy":"MEDIUM",
              "estimatedDurationMinutes":45,
              "status":"PLANNED"
            }
            """.utf8),
            200
        ))

        let service = TaskService(apiClient: mock, cache: APICache())
        let updated = try await service.updateTask(
            id: taskId,
            title: "Updated",
            description: "Desc",
            dueDate: "2026-11-12",
            priority: .high,
            energy: .medium,
            estimatedDurationMinutes: 45
        )

        XCTAssertEqual(updated.title, "Updated")
        XCTAssertEqual(updated.dueDate, "2026-11-12")

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/tasks/\(taskId.uuidString.lowercased())")
        XCTAssertEqual(request.method, "PUT")

        let bodyData = try XCTUnwrap(request.body)
        let body = try JSONDecoder().decode(UpdateTaskRequestBody.self, from: bodyData)
        XCTAssertEqual(body.title, "Updated")
        XCTAssertEqual(body.dueDate, "2026-11-12")
        XCTAssertEqual(body.priority, "HIGH")
        XCTAssertEqual(body.energy, "MEDIUM")
        XCTAssertEqual(body.estimatedDurationMinutes, 45)
    }

    func testUpdateTaskWithoutDueDateMaintainsCompatibility() async throws {
        let mock = MockAPIClient()
        let taskId = UUID(uuidString: "A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D")!
        mock.defaultResponse = .success((
            Data("""
            {
              "id":"\(taskId.uuidString)",
              "title":"Compat",
              "status":"PLANNED"
            }
            """.utf8),
            200
        ))

        let service = TaskService(apiClient: mock, cache: APICache())
        // Caller omitting dueDate completely
        let updated = try await service.updateTask(
            id: taskId,
            title: "Compat",
            description: nil,
            priority: .low,
            energy: nil,
            estimatedDurationMinutes: nil
        )

        XCTAssertEqual(updated.title, "Compat")
        let request = try XCTUnwrap(mock.recordedRequests.first)
        let bodyData = try XCTUnwrap(request.body)
        let body = try JSONDecoder().decode(UpdateTaskRequestBody.self, from: bodyData)
        XCTAssertNil(body.dueDate)
    }
}

final class TopThreeServiceTests: XCTestCase {
    func testDateQueryStringFormatting() throws {
        var lisbon = Calendar(identifier: .gregorian)
        lisbon.timeZone = TimeZone(identifier: "Europe/Lisbon")!

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!

        // 2026-08-26 13:00 UTC — still Aug 26 in Lisbon.
        let instant = try XCTUnwrap(utc.date(from: DateComponents(year: 2026, month: 8, day: 26, hour: 13)))

        XCTAssertEqual(
            TopThreeService.apiDateString(for: instant, calendar: lisbon),
            "2026-08-26"
        )

        // Same instant is already Aug 27 in Auckland (+12).
        var auckland = Calendar(identifier: .gregorian)
        auckland.timeZone = TimeZone(identifier: "Pacific/Auckland")!
        XCTAssertEqual(
            TopThreeService.apiDateString(for: instant, calendar: auckland),
            "2026-08-27"
        )
    }

    func testTodayUsesDailyTopThreePath() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            [{"id":"33333333-3333-3333-3333-333333333333","taskId":"E8E19BB5-93BB-4D57-9DBD-C36B47C43DF1","taskTitle":"Finish authentication","calendarDate":"2026-08-26","position":1,"selectedAt":"2026-08-26T08:00:00Z","isCompleted":false,"isDeleted":false,"isCancelled":false}]
            """.utf8),
            200
        ))

        let items = try await TopThreeService(apiClient: mock, cache: APICache()).today()

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].taskTitle, "Finish authentication")
        XCTAssertTrue(mock.recordedRequests[0].path.hasPrefix("/api/v1/daily-top-three/"))
    }
}

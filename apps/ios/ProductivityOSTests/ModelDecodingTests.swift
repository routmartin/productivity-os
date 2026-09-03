import XCTest
@testable import ProductivityOS

final class ModelDecodingTests: XCTestCase {
    
    func testDecodeTaskResponse() throws {
        let json = """
        {
            "id": "e8e19bb5-93bb-4d57-9dbd-c36b47c43df1",
            "ownerId": "f7d2a8b3-11bb-4d57-9dbd-c36b47c43df2",
            "title": "Finish authentication",
            "description": "Implement JWT refresh",
            "dueDate": "2026-08-26",
            "priority": "HIGH",
            "energy": "HIGH",
            "estimatedDurationMinutes": 90,
            "status": "IN_PROGRESS",
            "completedAt": null,
            "deletedAt": null,
            "projectId": null,
            "createdAt": "2026-08-26T10:00:00Z",
            "updatedAt": "2026-08-26T10:30:00Z"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let task = try decoder.decode(TaskItem.self, from: json)
        XCTAssertEqual(task.title, "Finish authentication")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.energy, .high)
        XCTAssertEqual(task.status, .inProgress)
        XCTAssertEqual(task.estimatedDurationMinutes, 90)
        XCTAssertFalse(task.isCompleted)
    }
    
    func testDecodeFocusSessionResponse() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
            "taskId": "e8e19bb5-93bb-4d57-9dbd-c36b47c43df1",
            "taskTitle": "Finish authentication",
            "startedAt": "2026-08-26T10:00:00Z",
            "endedAt": null,
            "durationSeconds": null,
            "configuredDurationSeconds": 2700,
            "note": "Deep work session",
            "isActive": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let session = try decoder.decode(FocusSession.self, from: json)
        XCTAssertEqual(session.taskTitle, "Finish authentication")
        XCTAssertEqual(session.configuredDurationSeconds, 2700)
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endedAt)
    }
    
    func testDecodeTopThreeResponse() throws {
        let json = """
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "taskId": "e8e19bb5-93bb-4d57-9dbd-c36b47c43df1",
            "taskTitle": "Finish authentication",
            "calendarDate": "2026-08-26",
            "position": 1,
            "isCompleted": false,
            "isDeleted": false,
            "isCancelled": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let item = try decoder.decode(TopThreeItem.self, from: json)
        XCTAssertEqual(item.taskTitle, "Finish authentication")
        XCTAssertEqual(item.position, 1)
        XCTAssertFalse(item.isCompleted)
    }

    func testDecodeGoalResponse() throws {
        let json = """
        {
            "id": "11111111-2222-3333-4444-555555555555",
            "userId": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "title": "Build the best version of Productivity OS",
            "description": "Ship a great iOS app",
            "status": "ACTIVE",
            "deadline": "2026-12-31",
            "completedAt": null,
            "createdAt": "2026-08-26T10:00:00Z",
            "updatedAt": "2026-08-26T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: dateString) { return date }
            let day = DateFormatter()
            day.dateFormat = "yyyy-MM-dd"
            day.timeZone = TimeZone(identifier: "UTC")
            day.locale = Locale(identifier: "en_US_POSIX")
            if let date = day.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date \(dateString)")
        }

        let goal = try decoder.decode(Goal.self, from: json)
        XCTAssertEqual(goal.title, "Build the best version of Productivity OS")
        XCTAssertEqual(goal.status, .active)
        XCTAssertNotNil(goal.deadline)
        XCTAssertEqual(goal.description, "Ship a great iOS app")
    }

    func testDecodeProjectResponse() throws {
        let json = """
        {
            "id": "b1111111-1111-1111-1111-111111111111",
            "userId": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "title": "iOS App",
            "description": "Ship the iOS read-only experience",
            "goalId": "a1111111-1111-1111-1111-111111111111",
            "status": "ACTIVE",
            "deadline": "2026-12-31",
            "completedAt": null,
            "createdAt": "2026-08-26T10:00:00Z",
            "updatedAt": "2026-08-26T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: dateString) { return date }
            let day = DateFormatter()
            day.dateFormat = "yyyy-MM-dd"
            day.timeZone = TimeZone(identifier: "UTC")
            day.locale = Locale(identifier: "en_US_POSIX")
            if let date = day.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date \(dateString)")
        }

        let project = try decoder.decode(Project.self, from: json)
        XCTAssertEqual(project.title, "iOS App")
        XCTAssertEqual(project.status, .active)
        XCTAssertNotNil(project.deadline)
        XCTAssertEqual(project.goalId?.uuidString.lowercased(), "a1111111-1111-1111-1111-111111111111")
    }
}

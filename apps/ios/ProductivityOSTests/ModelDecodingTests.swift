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
}

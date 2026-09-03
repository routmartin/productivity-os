import Foundation
import XCTest
@testable import ProductivityOS

final class GoalServiceTests: XCTestCase {
    func testListGoalsDecodesPlainArray() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            [
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
            ]
            """.utf8),
            200
        ))

        let goals = try await GoalService(apiClient: mock).listGoals()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals[0].title, "Build the best version of Productivity OS")
        XCTAssertEqual(goals[0].status, .active)
        XCTAssertNotNil(goals[0].deadline)
        XCTAssertEqual(goals[0].description, "Ship a great iOS app")

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/goals")
    }

    func testGetGoalDecodesSingleResponse() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            {
              "id": "11111111-2222-3333-4444-555555555555",
              "userId": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
              "title": "Financial Freedom",
              "description": null,
              "status": "ACTIVE",
              "deadline": null,
              "completedAt": null,
              "createdAt": "2026-08-26T10:00:00Z",
              "updatedAt": "2026-08-26T10:30:00Z"
            }
            """.utf8),
            200
        ))

        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let goal = try await GoalService(apiClient: mock).getGoal(id: id)

        XCTAssertEqual(goal.title, "Financial Freedom")
        XCTAssertEqual(goal.status, .active)
        XCTAssertNil(goal.deadline)
        XCTAssertNil(goal.description)
        XCTAssertEqual(goal.id, id)

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/goals/\(id.uuidString.lowercased())")
    }

    func testEmptyGoalsList() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((Data("[]".utf8), 200))

        let goals = try await GoalService(apiClient: mock).listGoals()
        XCTAssertTrue(goals.isEmpty)
    }
}

final class ProjectServiceTests: XCTestCase {
    func testListProjectTasksDecodesArray() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            [
              {"id":"E8E19BB5-93BB-4D57-9DBD-C36B47C43DF1","ownerId":"F7D2A8B3-11BB-4D57-9DBD-C36B47C43DF2","title":"First","status":"COMPLETED","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"},
              {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","ownerId":"F7D2A8B3-11BB-4D57-9DBD-C36B47C43DF2","title":"Second","status":"PENDING","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"}
            ]
            """.utf8),
            200
        ))

        let projectId = UUID(uuidString: "B1111111-1111-1111-1111-111111111111")!
        let tasks = try await ProjectService(apiClient: mock).listTasks(projectId: projectId)

        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks[0].status, .completed)

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/projects/\(projectId.uuidString.lowercased())/tasks")
    }
}
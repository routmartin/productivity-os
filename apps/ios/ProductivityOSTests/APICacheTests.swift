import Foundation
import XCTest
@testable import ProductivityOS

final class APICacheTests: XCTestCase {
    override func setUp() async throws {
        await APICache.shared.reset()
    }

    override func tearDown() async throws {
        await APICache.shared.reset()
    }

    func testMissThenHitReturnsCachedData() async {
        let key = CacheKey(method: "GET", path: "/api/v1/projects")
        let first = await APICache.shared.get(key: key)
        XCTAssertNil(first)

        let payload = Data(#"{"hello":"world"}"#.utf8)
        await APICache.shared.set(key: key, data: payload, statusCode: 200, ttl: 60)

        let cached = await APICache.shared.get(key: key)
        XCTAssertEqual(cached?.0, payload)
        XCTAssertEqual(cached?.1, 200)
    }

    func testExpiredEntryIsEvictedOnRead() async {
        let key = CacheKey(method: "GET", path: "/api/v1/goals")
        await APICache.shared.set(
            key: key,
            data: Data(),
            statusCode: 200,
            ttl: 0,
            now: Date(timeIntervalSinceNow: -10)
        )

        let cached = await APICache.shared.get(key: key)
        XCTAssertNil(cached)
    }

    func testEvictByPrefixRemovesMatchingEntries() async {
        await APICache.shared.set(
            key: CacheKey(method: "GET", path: "/api/v1/projects"),
            data: Data(),
            statusCode: 200,
            ttl: 600
        )
        await APICache.shared.set(
            key: CacheKey(method: "GET", path: "/api/v1/projects/B/tasks"),
            data: Data(),
            statusCode: 200,
            ttl: 600
        )
        await APICache.shared.set(
            key: CacheKey(method: "GET", path: "/api/v1/goals"),
            data: Data(),
            statusCode: 200,
            ttl: 600
        )

        await APICache.shared.evict(prefix: "/api/v1/projects")

        XCTAssertNil(await APICache.shared.get(key: CacheKey(method: "GET", path: "/api/v1/projects")))
        XCTAssertNil(await APICache.shared.get(key: CacheKey(method: "GET", path: "/api/v1/projects/B/tasks")))
        let goals = await APICache.shared.get(key: CacheKey(method: "GET", path: "/api/v1/goals"))
        XCTAssertNotNil(goals)
    }

    func testCacheKeyEncodesQueryString() {
        let endpoint = AppEndpoint.listTasks(page: 2, size: 10)
        let key = CacheKey(endpoint: endpoint)
        XCTAssertTrue(key.path.contains("page=2"))
        XCTAssertTrue(key.path.contains("size=10"))

        let otherEndpoint = AppEndpoint.listTasks(page: 3, size: 10)
        let otherKey = CacheKey(endpoint: otherEndpoint)
        XCTAssertNotEqual(key, otherKey)
    }

    func testServiceListProjectsHitsCacheOnSecondCall() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            [{"id":"B1111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","title":"Cached","status":"ACTIVE","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"}]
            """.utf8),
            200
        ))

        let service = ProjectService(apiClient: mock)

        _ = try await service.listProjects()
        _ = try await service.listProjects()

        XCTAssertEqual(mock.recordedRequests.count, 1)
        XCTAssertEqual(mock.recordedRequests.first?.path, "/api/v1/projects")
    }

    func testServiceUpdateTaskEvictsRelatedPrefixes() async throws {
        let mock = MockAPIClient()
        let taskID = UUID()
        mock.scriptedResponses = [
            // First populate the caches
            .success((Data("[]".utf8), 200)), // projects
            .success((Data("[]".utf8), 200)), // goals
            .success((Data("[]".utf8), 200)), // tasks
            .success((Data("[]".utf8), 200)), // daily-top-three
            // Then the PUT
            .success((
                Data("""
                {"id":"\(taskID.uuidString)","ownerId":"11111111-1111-1111-1111-111111111111","title":"Updated","status":"PENDING","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"}
                """.utf8),
                200
            ))
        ]

        let projects = ProjectService(apiClient: mock)
        let goals = GoalService(apiClient: mock)
        let tasks = TaskService(apiClient: mock)

        _ = try await projects.listProjects()
        _ = try await goals.listGoals()
        _ = try await tasks.listActiveTasks()

        // Confirm caches are warm — second call should hit cache.
        _ = try await projects.listProjects()
        XCTAssertEqual(mock.recordedRequests.count, 3)

        // Mutate. updateTask calls the endpoint itself, then evicts.
        _ = try await tasks.updateTask(
            id: taskID,
            title: "Updated",
            description: nil,
            priority: .high,
            energy: nil,
            estimatedDurationMinutes: nil
        )

        // Next reads should hit the network again.
        _ = try await projects.listProjects()
        _ = try await goals.listGoals()
        _ = try await tasks.listActiveTasks()

        // 3 cache populates + 1 PUT + 3 repopulates after eviction = 7
        XCTAssertEqual(mock.recordedRequests.count, 7)
    }
}
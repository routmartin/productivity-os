import Foundation
import XCTest
@testable import ProductivityOS

final class APIClientTests: XCTestCase {
    private var authSession: AuthSession!
    private var apiClient: APIClient!

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        authSession = AuthSession(keychain: KeychainManager(serviceName: "com.productivityos.tests.\(UUID().uuidString)"))
        apiClient = APIClient(
            session: URLSession(configuration: config),
            config: APIConfiguration(environment: .development, customBaseURL: URL(string: "https://stub.local")!),
            authSession: authSession
        )
    }

    override func tearDown() {
        authSession.logout()
        StubURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Decoding

    func testDecodesTypedResponse() async throws {
        authSession.setSession(accessToken: "old-token", user: nil)
        StubURLProtocol.enqueue(
            path: "/api/v1/tasks",
            status: 200,
            data: Data("""
            [{"id":"E8E19BB5-93BB-4D57-9DBD-C36B47C43DF1","ownerId":"F7D2A8B3-11BB-4D57-9DBD-C36B47C43DF2","title":"Real task","priority":"HIGH","status":"PENDING","createdAt":"2026-08-26T10:00:00Z","updatedAt":"2026-08-26T10:00:00Z"}]
            """.utf8)
        )

        let tasks = try await apiClient.request(AppEndpoint.listTasks()) as [TaskItem]

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].title, "Real task")
        XCTAssertEqual(tasks[0].priority, .high)

        let sent = StubURLProtocol.recorded(pathContains: "/api/v1/tasks")
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(sent[0].authorizationHeader, "Bearer old-token")
    }

    func testStructuredErrorBodyIsSurfaced() async {
        StubURLProtocol.enqueue(
            path: "/api/v1/daily-top-three/2026-08-26",
            status: 400,
            data: Data("""
            {"code":"TOP3_FULL","message":"Top 3 is full","details":null,"traceId":"abc"}
            """.utf8)
        )

        do {
            _ = try await apiClient.request(
                AppEndpoint.getDailyTopThree(date: "2026-08-26")
            ) as [TopThreeItem]
            XCTFail("Expected error")
        } catch let error as APIError {
            guard case .serverError(let status, let code, let message) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertEqual(status, 400)
            XCTAssertEqual(code, "TOP3_FULL")
            XCTAssertEqual(message, "Top 3 is full")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNotFoundErrorCase() async {
        StubURLProtocol.enqueue(path: "/api/v1/focus/active", status: 404)
        do {
            _ = try await apiClient.request(AppEndpoint.getActiveFocusSession) as FocusSession
            XCTFail("Expected error")
        } catch let error as APIError {
            guard case .notFound = error else {
                return XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Silent refresh

    func testUnauthorizedTriggersRefreshThenRetriesOnce() async throws {
        authSession.setSession(accessToken: "expired-token", user: nil)
        StubURLProtocol.enqueue(path: "/api/v1/tasks", status: 401)
        StubURLProtocol.enqueue(
            path: "/api/v1/tasks",
            status: 200,
            data: Data("[]".utf8)
        )
        StubURLProtocol.enqueue(
            path: "/api/v1/auth/refresh",
            status: 200,
            data: Data(#"{"accessToken":"fresh-token","user":null}"#.utf8)
        )

        let tasks = try await apiClient.request(AppEndpoint.listTasks()) as [TaskItem]
        XCTAssertTrue(tasks.isEmpty)
        XCTAssertEqual(authSession.accessToken, "fresh-token")

        let taskCalls = StubURLProtocol.recorded(pathContains: "/api/v1/tasks")
        XCTAssertEqual(taskCalls.count, 2)
        XCTAssertEqual(taskCalls[0].authorizationHeader, "Bearer expired-token")
        XCTAssertEqual(taskCalls[1].authorizationHeader, "Bearer fresh-token")

        let refreshCalls = StubURLProtocol.recorded(pathContains: "/auth/refresh")
        XCTAssertEqual(refreshCalls.count, 1)
        XCTAssertNil(refreshCalls[0].authorizationHeader)
    }

    func testFailedRefreshClearsSessionAndThrowsUnauthorized() async {
        authSession.setSession(accessToken: "expired-token", user: nil)
        StubURLProtocol.enqueue(path: "/api/v1/tasks", status: 401)
        StubURLProtocol.enqueue(
            path: "/api/v1/auth/refresh",
            status: 401,
            data: Data(#"{"code":"UNAUTHORIZED","message":"Authentication required","traceId":"t"}"#.utf8)
        )

        do {
            _ = try await apiClient.request(AppEndpoint.listTasks()) as [TaskItem]
            XCTFail("Expected unauthorized")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                return XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertFalse(authSession.isAuthenticated)
        XCTAssertNil(authSession.currentUser)

        // No retry after failed refresh.
        XCTAssertEqual(StubURLProtocol.recorded(pathContains: "/api/v1/tasks").count, 1)
    }

    func testAuthEndpointNeverTriggersRefresh() async {
        StubURLProtocol.enqueue(path: "/api/v1/auth/login", status: 401)

        do {
            let body = try APIClient.encodedBody(LoginRequestBody(email: "a@b.co", password: "pw"))
            _ = try await apiClient.request(AppEndpoint.login(body: body)) as AuthResponse
            XCTFail("Expected unauthorized")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                return XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(StubURLProtocol.recorded(pathContains: "/auth/refresh").count, 0)
    }

    func testConcurrentUnauthorizedRequestsShareOneRefresh() async throws {
        authSession.setSession(accessToken: "expired-token", user: nil)
        // Both requests hit 401 first; the delay on refresh guarantees overlap.
        StubURLProtocol.enqueue(path: "/api/v1/tasks", status: 401)
        StubURLProtocol.enqueue(path: "/api/v1/tasks", status: 401)
        StubURLProtocol.enqueue(path: "/api/v1/tasks", status: 200, data: Data("[]".utf8))
        StubURLProtocol.enqueue(path: "/api/v1/tasks", status: 200, data: Data("[]".utf8))
        StubURLProtocol.enqueue(
            path: "/api/v1/auth/refresh",
            status: 200,
            data: Data(#"{"accessToken":"shared-fresh","user":null}"#.utf8),
            delay: 0.15
        )

        async let a = apiClient.request(AppEndpoint.listTasks()) as [TaskItem]
        async let b = apiClient.request(AppEndpoint.listTasks(page: 1)) as [TaskItem]
        _ = try await (a, b)

        XCTAssertEqual(authSession.accessToken, "shared-fresh")
        XCTAssertEqual(StubURLProtocol.recorded(pathContains: "/auth/refresh").count, 1)
    }
}

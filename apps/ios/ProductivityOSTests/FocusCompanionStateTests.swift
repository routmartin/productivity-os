import XCTest
@testable import ProductivityOS

@MainActor
final class FocusCompanionStateTests: XCTestCase {
    private var mockAPIClient: MockAPIClient!
    private var focusService: FocusService!
    private var keychain: KeychainManager!
    private var authSession: AuthSession!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        let cache = APICache()
        focusService = FocusService(apiClient: mockAPIClient, cache: cache)
        keychain = KeychainManager(serviceName: "com.productivityos.test.mac.state")
        keychain.clearAll()
        authSession = AuthSession(keychain: keychain)
    }

    override func tearDown() {
        keychain.clearAll()
        super.tearDown()
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private func makeSession(id: UUID = UUID(), minutesAgo: Int = 5) -> FocusSession {
        FocusSession(
            id: id,
            taskId: UUID(),
            taskTitle: "Write tests",
            startedAt: Date().addingTimeInterval(-Double(minutesAgo * 60)),
            endedAt: nil,
            durationSeconds: nil,
            configuredDurationSeconds: 1500,
            note: nil,
            isActive: true
        )
    }

    func testUnauthenticatedWhenNoSession() {
        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        if case .unauthenticated = state.phase { /* expected */ } else {
            XCTFail("Expected .unauthenticated, got \(state.phase)")
        }
    }

    func testStartPollingWithNoAuthDoesNotCrash() {
        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        state.startPolling()  // should be a no-op when unauthenticated
        state.stopPolling()
    }

    func testStartPollingWithAuthButNoMockResponse() async {
        authSession.setSession(accessToken: "t", user: nil)
        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        state.startPolling()
        try? await Task.sleep(nanoseconds: 200_000_000)
        state.stopPolling()
    }

    func testActiveAfterPollerReportsSession() async {
        authSession.setSession(accessToken: "t", user: nil)
        let session = makeSession()
        let data = (try? encoder.encode(session)) ?? Data()
        mockAPIClient.scriptedResponses = [.success((data, 200))]

        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        state.startPolling()

        // Wait for the poller's first tick to land.
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        state.stopPolling()

        switch state.phase {
        case .active(let s):
            XCTAssertEqual(s.id, session.id)
        default:
            XCTFail("Expected .active, got \(state.phase)")
        }
    }

    func testIdleAfterPollerReports404() async {
        authSession.setSession(accessToken: "t", user: nil)
        mockAPIClient.scriptedResponses = [.failure(APIError.notFound)]

        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        state.startPolling()

        try? await Task.sleep(nanoseconds: 500_000_000)
        state.stopPolling()

        if case .idle = state.phase { /* expected */ } else {
            XCTFail("Expected .idle, got \(state.phase)")
        }
    }

    func testEndSessionCallsServiceAndFlipsToIdle() async {
        authSession.setSession(accessToken: "t", user: nil)
        let session = makeSession()
        let data = (try? encoder.encode(session)) ?? Data()
        let endedResponse = makeSession(id: session.id, minutesAgo: 5)
        let endedData = (try? encoder.encode(endedResponse)) ?? Data()
        mockAPIClient.scriptedResponses = [
            .success((data, 200)),
            .success((endedData, 200))
        ]

        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        state.startPolling()
        try? await Task.sleep(nanoseconds: 500_000_000)
        // Sanity: we're in .active
        guard case .active = state.phase else {
            return XCTFail("Expected .active after first tick, got \(state.phase)")
        }
        await state.endSession()
        state.stopPolling()

        if case .idle = state.phase { /* expected */ } else {
            XCTFail("Expected .idle after endSession, got \(state.phase)")
        }
        XCTAssertEqual(mockAPIClient.recordedRequests.count, 2)
        XCTAssertEqual(mockAPIClient.recordedRequests.last?.path, "/api/v1/focus/\(session.id.uuidString.lowercased())/end")
    }

    func testSignedOutClearsAuthAndFlipsToUnauthenticated() async {
        authSession.setSession(accessToken: "t", user: nil)
        mockAPIClient.scriptedResponses = [
            .failure(APIError.unauthorized(code: "expired", message: nil))
        ]

        let state = FocusCompanionState(focusService: focusService, authSession: authSession)
        state.startPolling()
        try? await Task.sleep(nanoseconds: 500_000_000)
        state.stopPolling()

        XCTAssertFalse(authSession.isAuthenticated)
        if case .unauthenticated = state.phase { /* expected */ } else {
            XCTFail("Expected .unauthenticated, got \(state.phase)")
        }
    }
}

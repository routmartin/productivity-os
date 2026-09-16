import XCTest
@testable import ProductivityOS

final class FocusPollerTests: XCTestCase {
    private var mockAPIClient: MockAPIClient!
    private var focusService: FocusService!

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        focusService = FocusService(apiClient: mockAPIClient, cache: APICache())
    }

    private func makeSession(id: UUID = UUID(), startedMinutesAgo: Int = 5) -> FocusSession {
        FocusSession(
            id: id,
            taskId: UUID(),
            taskTitle: "Test task",
            startedAt: Date().addingTimeInterval(-Double(startedMinutesAgo * 60)),
            endedAt: nil,
            durationSeconds: nil,
            configuredDurationSeconds: 1500,
            note: nil,
            isActive: true
        )
    }

    /// Helper: subscribe to a poller's updates, run `body`, return the
    /// first update received. Used by every test to keep the tests
    /// focused on the assertion rather than the subscription dance.
    private func firstUpdate(of poller: FocusPoller, _ body: @escaping () async -> Void) async -> FocusCompanionUpdate? {
        let stream = await poller.updates()
        return await withCheckedContinuation { continuation in
            Task {
                for await update in stream {
                    continuation.resume(returning: update)
                    break
                }
            }
            Task {
                await body()
            }
        }
    }

    func testTickReturnsIdleWhenServerHasNoSession() async {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.notFound),
            .failure(APIError.notFound)
        ]
        let poller = FocusPoller(focusService: focusService)
        let update = await firstUpdate(of: poller) {
            await poller.tick()
        }
        XCTAssertEqual(update, .idle)
    }

    func testTickReturnsActiveWhenServerHasSession() async {
        let session = makeSession()
        let data = (try? encoder.encode(session)) ?? Data()
        mockAPIClient.scriptedResponses = [
            .success((data, 200))
        ]
        let poller = FocusPoller(focusService: focusService)
        let update = await firstUpdate(of: poller) {
            await poller.tick()
        }
        if case .active(let received) = update {
            XCTAssertEqual(received.id, session.id)
            XCTAssertEqual(received.taskTitle, "Test task")
        } else {
            XCTFail("Expected .active, got \(String(describing: update))")
        }
    }

    func testTickReturnsReconnectingOnNetworkError() async {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.networkError("offline"))
        ]
        let poller = FocusPoller(focusService: focusService)
        let update = await firstUpdate(of: poller) {
            await poller.tick()
        }
        if case .reconnecting(let lastKnown) = update {
            XCTAssertNil(lastKnown)
        } else {
            XCTFail("Expected .reconnecting(nil), got \(String(describing: update))")
        }
    }

    func testReconnectingPreservesLastKnownSession() async {
        let session = makeSession()
        let data = (try? encoder.encode(session)) ?? Data()
        mockAPIClient.scriptedResponses = [
            .success((data, 200)),
            .failure(APIError.networkError("offline"))
        ]
        let poller = FocusPoller(focusService: focusService)
        // Subscribe so the stream doesn't get cancelled before both ticks
        // publish.
        let stream = await poller.updates()
        let consumer = Task {
            for await _ in stream { /* discard */ }
        }
        await poller.tick()
        await poller.tick()
        consumer.cancel()
        let last = await poller.lastSession
        XCTAssertEqual(last?.id, session.id)
    }

    func testSignedOutStopsPollingOn401() async {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.unauthorized(code: "expired", message: nil))
        ]
        let poller = FocusPoller(focusService: focusService)
        let update = await firstUpdate(of: poller) {
            await poller.tick()
        }
        XCTAssertEqual(update, .signedOut)
    }
}

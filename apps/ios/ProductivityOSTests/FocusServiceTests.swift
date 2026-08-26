import Foundation
import XCTest
@testable import ProductivityOS

final class FocusServiceTests: XCTestCase {
    private let taskID = UUID(uuidString: "e8e19bb5-93bb-4d57-9dbd-c36b47c43df1")!

    func testStartSendsTaskIdAndConfiguredDuration() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","taskId":"\(taskID.uuidString.lowercased())","taskTitle":"Real task","startedAt":"2026-08-26T10:00:00Z","endedAt":null,"durationSeconds":null,"configuredDurationSeconds":1500,"note":null,"isActive":true}
            """.utf8),
            201
        ))

        let session = try await FocusService(apiClient: mock).start(taskId: taskID, configuredDurationSeconds: 1500)

        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.configuredDurationSeconds, 1500)

        let request = try XCTUnwrap(mock.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/focus")
        XCTAssertEqual(request.method, "POST")

        let body = try JSONDecoder().decode(StartFocusRequestBody.self, from: XCTUnwrap(request.body))
        XCTAssertEqual(body.taskId, taskID)
        XCTAssertEqual(body.configuredDurationSeconds, 1500)
    }

    func testUnlimitedStartOmitsConfiguredDuration() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","taskId":"\(taskID.uuidString.lowercased())","startedAt":"2026-08-26T10:00:00Z","endedAt":null,"durationSeconds":null,"configuredDurationSeconds":null,"note":null,"isActive":true}
            """.utf8),
            201
        ))

        _ = try await FocusService(apiClient: mock).start(taskId: taskID, configuredDurationSeconds: nil)

        let body = try JSONDecoder().decode(
            StartFocusRequestBody.self,
            from: XCTUnwrap(mock.recordedRequests.first?.body)
        )
        XCTAssertNil(body.configuredDurationSeconds)
    }

    func testActiveReturnsNilOn404() async throws {
        let mock = MockAPIClient()
        mock.scriptedResponses = [.failure(APIError.notFound)]

        let active = try await FocusService(apiClient: mock).active()
        XCTAssertNil(active)
    }

    func testActiveReturnsSession() async throws {
        let mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","taskId":"\(taskID.uuidString.lowercased())","startedAt":"2026-08-26T10:00:00Z","endedAt":null,"durationSeconds":null,"configuredDurationSeconds":2700,"note":null,"isActive":true}
            """.utf8),
            200
        ))

        let active = try await FocusService(apiClient: mock).active()
        XCTAssertEqual(active?.configuredDurationSeconds, 2700)
        XCTAssertEqual(active?.taskId, taskID)
    }

    func testEndCallsEndPathAndReturnsEndedSession() async throws {
        let mock = MockAPIClient()
        let id = UUID(uuidString: "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d")!
        mock.defaultResponse = .success((
            Data("""
            {"id":"\(id.uuidString)","taskId":"\(taskID.uuidString.lowercased())","startedAt":"2026-08-26T10:00:00Z","endedAt":"2026-08-26T10:25:00Z","durationSeconds":1500,"configuredDurationSeconds":1500,"note":null,"isActive":false}
            """.utf8),
            200
        ))

        let ended = try await FocusService(apiClient: mock).end(id: id)

        XCTAssertFalse(ended.isActive)
        XCTAssertEqual(ended.durationSeconds, 1500)
        XCTAssertEqual(mock.recordedRequests.first?.path, "/api/v1/focus/\(id.uuidString.lowercased())/end")
        XCTAssertEqual(mock.recordedRequests.first?.method, "POST")
    }
}

final class FocusViewModelSyncTests: XCTestCase {
    private var mock: MockAPIClient!
    private var viewModel: FocusSessionViewModel!

    override func setUp() {
        super.setUp()
        mock = MockAPIClient()
        // Valid FocusSessionResponse for start/end calls unless overridden.
        mock.defaultResponse = .success((
            Data("""
            {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","taskId":"e8e19bb5-93bb-4d57-9dbd-c36b47c43df1","startedAt":"2026-08-26T10:00:00Z","endedAt":null,"durationSeconds":null,"configuredDurationSeconds":null,"note":null,"isActive":true}
            """.utf8),
            200
        ))
        viewModel = FocusSessionViewModel(apiClient: mock)
    }

    func testStartWithoutTaskRunsLocallyAndWarnsNoSave() async {
        viewModel.selectedTask = nil
        viewModel.startFocus()

        XCTAssertEqual(viewModel.sessionState.state, .running)
        // Let the sync Task run.
        await waitUntil { [viewModel] in viewModel?.syncErrorMessage != nil }
        XCTAssertEqual(viewModel.syncErrorMessage, "No task selected — this session won't be saved.")
        XCTAssertTrue(mock.recordedRequests.isEmpty)

        viewModel.resetToPreparing()
    }

    func testCompleteAfterStartedSessionSendsEndCall() async {
        let task = SampleData.taskAuth
        viewModel.selectedTask = task
        viewModel.sessionState.start(task: task, duration: .pomodoro25)
        await viewModel.syncStart()

        viewModel.completeFocus()
        XCTAssertEqual(viewModel.sessionState.state, .completed)
        // completeFocus spawns its own end-sync task.
        await waitUntil { [mock] in mock.recordedRequests.count >= 2 }

        let paths = mock.recordedRequests.map(\.path)
        XCTAssertEqual(paths.first, "/api/v1/focus")
        XCTAssertTrue(paths.dropFirst().allSatisfy { $0 == "/api/v1/focus/a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d/end" })
    }

    func testCancelAlsoEndsServerSession() async {
        let task = SampleData.taskAuth
        viewModel.selectedTask = task
        viewModel.sessionState.start(task: task, duration: .unlimited)
        await viewModel.syncStart()

        viewModel.cancelFocus()
        XCTAssertEqual(viewModel.sessionState.state, .cancelled)
        await waitUntil { [mock] in mock.recordedRequests.count >= 2 }

        XCTAssertTrue(mock.recordedRequests.dropFirst().allSatisfy {
            $0.path.contains("/end") && $0.method == "POST"
        })
        viewModel.resetToPreparing()
    }

    func testEndFailureKeepsPendingSessionForRetry() async {
        let task = SampleData.taskAuth
        viewModel.selectedTask = task
        viewModel.sessionState.start(task: task, duration: .pomodoro25)

        // Start succeeds…
        await viewModel.syncStart()
        XCTAssertNil(viewModel.syncErrorMessage)

        // …then ending the session fails.
        mock.scriptedResponses = [.failure(APIError.networkError("offline"))]
        viewModel.sessionState.complete()
        await viewModel.syncEnd()

        XCTAssertNotNil(viewModel.syncErrorMessage)

        // A later retry persists the result (default mock response = success).
        await viewModel.syncEnd()
        XCTAssertNil(viewModel.syncErrorMessage)
    }

    func testRestoreActiveSessionResumesTimerFromServerTimestamp() async {
        let startedAt = Date().addingTimeInterval(-600) // 10 minutes ago
        mock.defaultResponse = .success((
            Data("""
            {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","taskId":"e8e19bb5-93bb-4d57-9dbd-c36b47c43df1","taskTitle":"Restored task","startedAt":"\(ISO8601DateFormatter().string(from: startedAt))","endedAt":null,"durationSeconds":null,"configuredDurationSeconds":2700,"note":null,"isActive":true}
            """.utf8),
            200
        ))

        await viewModel.restoreActiveSession()

        XCTAssertEqual(viewModel.sessionState.state, .running)
        XCTAssertEqual(viewModel.selectedTask?.title, "Restored task")
        XCTAssertEqual(viewModel.selectedDuration, .deepWork45)
        // Elapsed derived from server timestamp, not from local ticks.
        XCTAssertEqual(viewModel.sessionState.elapsedSeconds(at: Date()), 600, accuracy: 2.0)
    }

    func testDurationMappingForUnknownSecondsFallsBackToUnlimited() {
        XCTAssertEqual(FocusSessionViewModel.duration(forSeconds: 1500), .pomodoro25)
        XCTAssertEqual(FocusSessionViewModel.duration(forSeconds: 2700), .deepWork45)
        XCTAssertEqual(FocusSessionViewModel.duration(forSeconds: 3600), .focused60)
        XCTAssertEqual(FocusSessionViewModel.duration(forSeconds: nil), .unlimited)
        XCTAssertEqual(FocusSessionViewModel.duration(forSeconds: 1234), .unlimited)
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertTrue(condition(), "Condition not met before timeout", file: file, line: line)
    }
}

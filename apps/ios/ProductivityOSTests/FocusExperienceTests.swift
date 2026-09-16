import Foundation
import XCTest
@testable import ProductivityOS

/// Focus Experience polish milestone tests:
/// repeated pause/resume accuracy, natural completion at zero, and
/// backend-confirmed completion (spec §13/§14).
final class FocusTimerAccuracyTests: XCTestCase {
    func testRepeatedPauseResumeCyclesDoNotAccumulateError() throws {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 100_000)
        state.start(task: SampleData.taskAuth, duration: FocusDuration(totalSeconds: 1500), at: start)

        // 5 pause/resume cycles of varying pause lengths.
        var now = start.addingTimeInterval(60) // 1 min focused
        for pauseLength in [10.0, 45.0, 120.0, 7.0, 300.0] {
            state.pause(at: now)
            now = now.addingTimeInterval(pauseLength)
            state.resume(at: now)
            now = now.addingTimeInterval(30) // 30s more focus each cycle
        }

        // Active focus = 60 + 5*30 = 210s; pauses excluded.
        XCTAssertEqual(state.elapsedSeconds(at: now), 210, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(state.remainingSeconds(at: now)), 1500 - 210, accuracy: 0.001)
    }

    func testPauseFreezesRingAndTimer() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 50_000)
        state.start(task: nil, duration: FocusDuration(totalSeconds: 2700), at: start)
        state.pause(at: start.addingTimeInterval(100))

        // Time keeps passing while paused — displayed values must not move.
        XCTAssertEqual(state.elapsedSeconds(at: start.addingTimeInterval(500)), 100)
        XCTAssertEqual(state.progress(at: start.addingTimeInterval(500)), 100.0 / 2700, accuracy: 0.0001)
    }

    func testBackgroundForegroundRecalculationWhilePaused() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 10_000)
        state.start(task: nil, duration: FocusDuration(totalSeconds: 3600), at: start)

        state.pause(at: start.addingTimeInterval(200))
        // App backgrounded mid-pause for an hour.
        let foreground = start.addingTimeInterval(3_800)
        state.resume(at: foreground)

        // The hour in background happened while paused → not active focus.
        XCTAssertEqual(state.elapsedSeconds(at: foreground.addingTimeInterval(10)), 210)
    }

    func testCompletionClampsElapsedAtEndTime() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 0)
        state.start(task: nil, duration: FocusDuration(totalSeconds: 1500), at: start)
        state.complete(at: start.addingTimeInterval(600))

        // Checking far later must not grow the elapsed time.
        XCTAssertEqual(state.elapsedSeconds(at: start.addingTimeInterval(9_999)), 600)
        XCTAssertEqual(state.state, .completed)
    }

    func testInitialStateHasNoProgress() {
        let state = FocusSessionState(configuredDuration: FocusDuration(totalSeconds: 1500))
        XCTAssertEqual(state.elapsedSeconds(), 0)
        XCTAssertEqual(state.remainingSeconds(), 1500)
        XCTAssertEqual(state.progress(), 0)
    }
}

final class FocusNaturalCompletionTests: XCTestCase {
    private var mock: MockAPIClient!
    private var viewModel: FocusSessionViewModel!

    override func setUp() {
        super.setUp()
        mock = MockAPIClient()
        mock.defaultResponse = .success((
            Data("""
            {"id":"A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D","taskId":"e8e19bb5-93bb-4d57-9dbd-c36b47c43df1","startedAt":"2026-08-26T10:00:00Z","endedAt":null,"durationSeconds":null,"configuredDurationSeconds":null,"note":null,"isActive":true}
            """.utf8),
            200
        ))
        viewModel = FocusSessionViewModel(apiClient: mock)
    }

    func testFixedDurationSessionReachesZero() {
        viewModel.selectedTask = SampleData.taskAuth
        viewModel.sessionState.start(
            task: viewModel.selectedTask,
            duration: FocusDuration(totalSeconds: 1500),
            at: Date().addingTimeInterval(-1500)
        )

        XCTAssertTrue(viewModel.hasReachedZero)
    }

    func testUnlimitedSessionNeverReachesZero() {
        viewModel.selectedTask = SampleData.taskAuth
        viewModel.sessionState.start(
            task: viewModel.selectedTask,
            duration: .unlimited,
            at: Date().addingTimeInterval(-99_999)
        )

        XCTAssertFalse(viewModel.hasReachedZero)
    }

    func testCompletionRequiresBackendConfirmation() async {
        viewModel.selectedTask = SampleData.taskAuth
        viewModel.selectedDuration = FocusDuration(totalSeconds: 1500)
        viewModel.sessionState.start(task: viewModel.selectedTask, duration: FocusDuration(totalSeconds: 1500))
        await viewModel.syncStart()
        XCTAssertNotNil(viewModel.serverSession)

        viewModel.completeFocus()
        // Completion only becomes visible once the backend confirms.
        await waitUntil { [viewModel] in viewModel?.sessionState.state == .completed }
        XCTAssertEqual(viewModel.sessionState.state, .completed)
        XCTAssertNotNil(viewModel.sessionState.endTime)
        XCTAssertFalse(viewModel.isCompleting)
        XCTAssertTrue(mock.recordedRequests.contains { $0.path.contains("/end") })
    }

    func testFailedEndKeepsSessionUnclaimedAndRetryCompletesIt() async {
        viewModel.selectedTask = SampleData.taskAuth
        viewModel.selectedDuration = FocusDuration(totalSeconds: 1500)
        viewModel.sessionState.start(task: viewModel.selectedTask, duration: FocusDuration(totalSeconds: 1500))
        await viewModel.syncStart()

        // End call fails.
        mock.scriptedResponses = [.failure(APIError.networkError("offline"))]
        viewModel.completeFocus()
        await waitUntil { [viewModel] in viewModel?.syncErrorMessage != nil && viewModel?.isCompleting == false }

        // Session must NOT be claimed completed while the backend disagrees.
        XCTAssertFalse(viewModel.sessionState.state == .completed)
        XCTAssertNil(viewModel.sessionState.endTime)

        // Retry succeeds → completion is confirmed.
        await viewModel.confirmCompletion()
        XCTAssertEqual(viewModel.sessionState.state, .completed)
        XCTAssertNil(viewModel.syncErrorMessage)
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

final class DurationFormattingTests: XCTestCase {
    func testDetailedDurationFormatting() {
        XCTAssertEqual(FocusCompletionView.formatDetailedDuration(42 * 60 + 18), "42m 18s")
        XCTAssertEqual(FocusCompletionView.formatDetailedDuration(3600 + 4 * 60 + 12), "1h 04m 12s")
        XCTAssertEqual(FocusCompletionView.formatDetailedDuration(45), "45s")
        XCTAssertEqual(FocusCompletionView.formatDetailedDuration(0), "0s")
    }
}

import Foundation
import Observation

/// Drives the Focus flow. Local timer state (`FocusSessionState`) remains
/// timestamp/duration based and is the source of truth for the countdown;
/// server state (`FocusSession`) is synced separately:
/// - start  → POST /focus   (records taskId + configured duration)
/// - end    → POST /focus/{id}/end (on complete or cancel)
/// Pause/resume has no server contract and stays purely local.
@Observable
public final class FocusSessionViewModel {
    public var sessionState: FocusSessionState
    public var isDoNotDisturbEnabled: Bool = true
    public var selectedDuration: FocusDuration = .unlimited
    public var selectedTask: TaskItem?

    /// Server-side sync feedback (never blocks the local timer).
    public var syncErrorMessage: String?

    // UI ticker reference for smooth clock re-renders
    public var currentDate: Date = Date()

    private var serverSession: FocusSession?
    private var pendingEndSessionID: UUID?
    private var syncTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    @ObservationIgnored private let focusService: FocusService

    public init(
        task: TaskItem? = nil,
        state: FocusSessionState = FocusSessionState(),
        apiClient: APIRequesting = APIClient.shared
    ) {
        self.selectedTask = task
        self.sessionState = state
        self.focusService = FocusService(apiClient: apiClient)
    }

    // MARK: - Derived display values

    public var timerDisplayText: String {
        sessionState.formattedTimer(at: currentDate)
    }

    public var timerProgress: Double {
        sessionState.progress(at: currentDate)
    }

    // MARK: - Flow transitions

    public func startFocus() {
        sessionState.start(task: selectedTask, duration: selectedDuration, at: Date())
        startLocalTicker()
        syncTask = Task { [weak self] in await self?.syncStart() }
    }

    public func pauseFocus() {
        // No server pause contract — local-only state transition.
        sessionState.pause(at: Date())
        stopLocalTicker()
    }

    public func resumeFocus() {
        sessionState.resume(at: Date())
        startLocalTicker()
    }

    public func completeFocus() {
        sessionState.complete(at: Date())
        stopLocalTicker()
        syncTask = Task { [weak self] in await self?.syncEnd() }
    }

    public func cancelFocus() {
        sessionState.cancel(at: Date())
        stopLocalTicker()
        // Backend records any ended session; cancelling records the work done.
        syncTask = Task { [weak self] in await self?.syncEnd() }
    }

    public func resetToPreparing() {
        sessionState.reset()
        serverSession = nil
        pendingEndSessionID = nil
        syncErrorMessage = nil
        stopLocalTicker()
    }

    /// Re-evaluates time-dependent display after backgrounding / foregrounding.
    /// Accuracy comes from wall-clock timestamps, not ticker ticks.
    public func refreshClock() {
        currentDate = Date()
    }

    // MARK: - Session restoration (app relaunch / background)

    /// Restores an in-progress session from `GET /focus/active`, resuming the
    /// timer from the server-recorded start time. No-op when none exists.
    public func restoreActiveSession() async {
        guard sessionState.state == .preparing || sessionState.state == .completed || sessionState.state == .cancelled else {
            return
        }
        do {
            syncErrorMessage = nil
            guard let active = try await focusService.active() else { return }
            serverSession = active
            selectedTask = TaskItem(
                id: active.taskId,
                title: active.taskTitle ?? "Focus session",
                priority: .medium,
                status: .inProgress
            )
            selectedDuration = Self.duration(forSeconds: active.configuredDurationSeconds)
            sessionState.start(task: selectedTask, duration: selectedDuration, at: active.startedAt)
            currentDate = Date()
            startLocalTicker()
        } catch {
            syncErrorMessage = Self.userMessage(for: error)
        }
    }

    // MARK: - Server synchronization

    public func retrySync() {
        guard !isSyncInFlight else { return }
        syncTask = Task { [weak self] in
            if self?.pendingEndSessionID != nil {
                await self?.syncEnd()
            } else if self?.serverSession == nil, self?.sessionState.state == .running || self?.sessionState.state == .paused {
                await self?.syncStart()
            }
        }
    }

    private var isSyncInFlight: Bool {
        syncTask != nil && !(syncTask?.isCancelled ?? true)
    }

    func syncStart() async {
        guard let task = selectedTask else {
            // Backend requires a taskId; run locally and tell the user.
            syncErrorMessage = "No task selected — this session won't be saved."
            return
        }
        do {
            syncErrorMessage = nil
            serverSession = try await focusService.start(
                taskId: task.id,
                configuredDurationSeconds: sessionState.configuredDuration.isUnlimited
                    ? nil
                    : sessionState.configuredDuration.totalSeconds
            )
        } catch {
            syncErrorMessage = Self.userMessage(for: error)
        }
    }

    func syncEnd() async {
        guard let session = serverSession else {
            // Never started on the server (offline start or no task) — nothing to end.
            return
        }
        do {
            syncErrorMessage = nil
            _ = try await focusService.end(id: session.id)
            serverSession = nil
            pendingEndSessionID = nil
        } catch {
            // Keep the ID so a later retry can persist the result.
            pendingEndSessionID = session.id
            syncErrorMessage = Self.userMessage(for: error)
        }
    }

    // MARK: - Lightweight Local Ticker
    // The UI ticker only updates the view state for smooth seconds display.
    // The source of truth remains the underlying timestamp calculations.

    private func startLocalTicker() {
        stopLocalTicker()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s refresh
                self?.currentDate = Date()
            }
        }
    }

    private func stopLocalTicker() {
        timerTask?.cancel()
        timerTask = nil
    }

    static func duration(forSeconds seconds: Int?) -> FocusDuration {
        guard let seconds else { return .unlimited }
        return FocusDuration(rawValue: seconds) ?? .unlimited
    }

    static func userMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Something went wrong. Please try again."
        }
        return "Could not reach the server. Check your connection and try again."
    }

    deinit {
        timerTask?.cancel()
        syncTask?.cancel()
    }
}

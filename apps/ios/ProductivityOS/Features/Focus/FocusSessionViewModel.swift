import Foundation
import Observation

/// Drives the Focus flow. Local timer state (`FocusSessionState`) remains
/// timestamp/duration based and is the source of truth for the countdown;
/// server state (`FocusSession`) is synced separately:
/// - start  → POST /focus   (records taskId + configured duration)
/// - end    → POST /focus/{id}/end (on complete or cancel)
/// Pause/resume has no server contract and stays purely local.
///
/// The session is only marked `.completed` after the backend confirms the
/// end call (spec §13); until then the clock freezes and a retry is offered.
@Observable
public final class FocusSessionViewModel {
    public var sessionState: FocusSessionState
    public var isDoNotDisturbEnabled: Bool = true
    public var selectedDuration: FocusDuration = .unlimited
    public var selectedTask: TaskItem?

    /// Server-side sync feedback (never blocks the local timer).
    public var syncErrorMessage: String?

    /// True between the Complete action and backend confirmation.
    public private(set) var isCompleting: Bool = false

    // UI ticker reference for smooth clock re-renders
    public var currentDate: Date = Date()

    var serverSession: FocusSession?
    private var pendingEndSessionID: UUID?
    private var completionDate: Date?
    private var syncTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    @ObservationIgnored private let focusService: FocusService

    public init(
        task: TaskItem? = nil,
        state: FocusSessionState = FocusSessionState(),
        apiClient: APIRequesting = APIClient.shared
    ) {
        self.selectedTask = task
        self.selectedDuration = FocusDuration.fromEstimatedMinutes(task?.estimatedDurationMinutes)
        self.sessionState = state
        self.focusService = FocusService(apiClient: apiClient)
    }

    /// Updates the selected task and snaps the duration to whatever the task
    /// reports on the API. Used by callers wiring a task into the focus flow
    /// so the prep screen and the stored estimate stay in sync.
    public func setSelectedTask(_ task: TaskItem?) {
        selectedTask = task
        selectedDuration = FocusDuration.fromEstimatedMinutes(task?.estimatedDurationMinutes)
    }

    // MARK: - Derived display values

    public var timerDisplayText: String {
        sessionState.formattedTimer(at: currentDate)
    }

    public var timerProgress: Double {
        sessionState.progress(at: currentDate)
    }

    /// True when a fixed-duration session has reached zero.
    /// Evaluated against the wall clock, not the display reference date.
    public var hasReachedZero: Bool {
        guard !sessionState.configuredDuration.isUnlimited else { return false }
        return (sessionState.remainingSeconds(at: Date()) ?? 1) <= 0
    }

    // MARK: - Flow transitions

    public func startFocus() {
        sessionState.start(task: selectedTask, duration: selectedDuration, at: Date())
        currentDate = Date()
        startLocalTicker()
        syncTask = Task { [weak self] in await self?.syncStart() }
    }

    public func pauseFocus() {
        // No server pause contract — local-only state transition.
        sessionState.pause(at: Date())
        currentDate = Date()
        stopLocalTicker()
    }

    public func resumeFocus() {
        sessionState.resume(at: Date())
        currentDate = Date()
        startLocalTicker()
    }

    /// Begins completion: freezes the clock, confirms with the backend, and
    /// only then marks the session completed locally.
    public func completeFocus() {
        guard !isCompleting else { return }
        guard sessionState.state == .running || sessionState.state == .paused else { return }
        isCompleting = true
        completionDate = Date()
        stopLocalTicker()
        syncTask = Task { [weak self] in await self?.confirmCompletion() }
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
        completionDate = nil
        syncErrorMessage = nil
        isCompleting = false
        stopLocalTicker()
    }

    /// Re-evaluates time-dependent display after backgrounding / foregrounding.
    /// Accuracy comes from wall-clock timestamps, not ticker ticks.
    public func refreshClock() {
        guard sessionState.state == .running else { return }
        currentDate = Date()
        autoCompleteAtZero()
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
                await self?.confirmCompletion()
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

    /// Confirms completion with the backend; marks `.completed` only on success.
    func confirmCompletion() async {
        let endedAt = completionDate ?? Date()
        do {
            if let session = serverSession {
                _ = try await focusService.end(id: session.id)
                serverSession = nil
            }
            pendingEndSessionID = nil
            syncErrorMessage = nil
            isCompleting = false
            sessionState.complete(at: endedAt)
        } catch {
            // Backend did not confirm — keep the session unclaimed and retryable.
            pendingEndSessionID = serverSession?.id
            isCompleting = false
            syncErrorMessage = Self.userMessage(for: error)
            startLocalTicker()
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

    // MARK: - Natural completion

    /// Fixed-duration sessions complete themselves when the timestamp math
    /// reaches zero (spec §14). Suppressed while an end-call failure is
    /// pending so failures surface to the user instead of retry-looping.
    private func autoCompleteAtZero() {
        guard sessionState.state == .running, pendingEndSessionID == nil, hasReachedZero else { return }
        completeFocus()
    }

    // MARK: - Lightweight Local Ticker
    // The UI ticker only updates the view state for smooth seconds display.
    // The source of truth remains the underlying timestamp calculations.

    private func startLocalTicker() {
        stopLocalTicker()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s refresh
                guard let self, self.sessionState.state == .running else { continue }
                self.currentDate = Date()
                self.autoCompleteAtZero()
            }
        }
    }

    private func stopLocalTicker() {
        timerTask?.cancel()
        timerTask = nil
    }

    static func duration(forSeconds seconds: Int?) -> FocusDuration {
        FocusDuration.fromSeconds(seconds)
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

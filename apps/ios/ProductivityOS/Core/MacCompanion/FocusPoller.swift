import Foundation
import os.log

/// Outcome of a single `FocusPoller` tick.
public enum FocusCompanionUpdate: Sendable, Equatable {
    /// Server has no active session right now.
    case idle
    /// Server has an active session; payload is the canonical
    /// `FocusSession` whose `startedAt` is server-authoritative.
    case active(FocusSession)
    /// A network error occurred but we still have a previous session to
    /// display. The popover dims the timer and shows a "Reconnecting…"
    /// badge.
    case reconnecting(lastKnown: FocusSession?)
    /// The server rejected our credentials (401). The caller should
    /// clear `AuthSession` and show the unauthenticated state.
    case signedOut
    /// Any other error. The caller surfaces it as an inline message.
    case error(String)

    public var lastKnownSession: FocusSession? {
        if case .reconnecting(let session) = self { return session }
        return nil
    }
}

/// Background poller for `/api/v1/focus/active`.
///
/// Cadence:
/// - Active session: every 5 seconds.
/// - Idle: every 60 seconds.
/// - Unauthenticated: no polling (the start() call short-circuits).
///
/// Low-power mode pauses ticks; the poller does not wake the machine from
/// sleep. A failed tick increments a backoff (5s → 10s → 20s → 30s) so
/// transient outages don't spam the server.
///
/// `FocusPoller` is an `actor` so its `Task` reference and state are
/// safe to mutate from any context. Updates are published through an
/// `AsyncStream` so subscribers can `for await` without juggling
/// callbacks.
public actor FocusPoller {
    private let focusService: FocusService
    private var task: Task<Void, Never>?
    private var continuations: [UUID: AsyncStream<FocusCompanionUpdate>.Continuation] = [:]
    private var currentSession: FocusSession?
    private var failureStreak: Int = 0
    private var lastTickAt: Date?

    public init(focusService: FocusService = .init()) {
        self.focusService = focusService
    }

    /// Begin polling. Cancels any previous in-flight loop.
    public func start() {
        stop()
        task = Task { [weak self] in
            await self?.runLoop()
        }
    }

    /// Stop polling. Safe to call multiple times.
    public func stop() {
        task?.cancel()
        task = nil
    }

    /// Run a single tick on demand. Used by tests; the production loop
    /// is driven by `start()`.
    public func tick() async {
        await runOneTick()
    }

    /// Last session the poller observed. Read-only access for tests.
    public var lastSession: FocusSession? {
        currentSession
    }

    /// Subscribe to update events. Each call gets its own stream; cancel
    /// the task that consumes the stream to unsubscribe.
    public func updates() -> AsyncStream<FocusCompanionUpdate> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { @Sendable _ in
                Task { [weak self] in
                    await self?.removeContinuation(id: id)
                }
            }
        }
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func publish(_ update: FocusCompanionUpdate) {
        for continuation in continuations.values {
            continuation.yield(update)
        }
    }

    // MARK: - Internals

    private func runLoop() async {
        while !Task.isCancelled {
            await runOneTick()
            let isActive = currentSession != nil
            let interval = intervalForNextTick(isActive: isActive)
            try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
        }
    }

    private func runOneTick() async {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return
        }
        lastTickAt = Date()
        do {
            let session = try await focusService.active()
            failureStreak = 0
            currentSession = session
            if let session {
                publish(.active(session))
            } else {
                publish(.idle)
            }
        } catch let error as APIError {
            failureStreak += 1
            switch error {
            case .unauthorized:
                publish(.signedOut)
                currentSession = nil
                stop()
            case .networkError:
                publish(.reconnecting(lastKnown: currentSession))
            default:
                publish(.reconnecting(lastKnown: currentSession))
            }
        } catch {
            failureStreak += 1
            publish(.reconnecting(lastKnown: currentSession))
            os_log(.error, log: .default, "📡 [Mac] Poller error: %{public}@", error.localizedDescription)
        }
    }

    private func intervalForNextTick(isActive: Bool) -> TimeInterval {
        if failureStreak > 0 {
            return min(30.0, pow(2.0, Double(failureStreak - 1)) * 5.0)
        }
        return isActive ? 5.0 : 60.0
    }
}

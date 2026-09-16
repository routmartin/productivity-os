import Foundation
import Observation

/// View-model for the macOS Focus Companion popover.
///
/// Owns the four-state machine (`unauthenticated`, `idle`, `active`,
/// `reconnecting`, `error`), the `FocusPoller` lifecycle, and a 1Hz
/// tick that drives the elapsed-time label in the popover. The view
/// only renders the `phase` and `isEnding` properties; everything else
/// is hidden behind async methods.
@MainActor
@Observable
public final class FocusCompanionState {
    public enum Phase: Equatable {
        case unauthenticated
        case idle
        case active(session: FocusSession)
        case reconnecting(lastKnown: FocusSession?)
        case error(String)

        public var lastSession: FocusSession? {
            switch self {
            case .active(let session), .reconnecting(let .some(session)):
                return session
            case .reconnecting(let session):
                return session
            default:
                return nil
            }
        }
    }

    public private(set) var phase: Phase = .unauthenticated
    public private(set) var isEnding: Bool = false
    public private(set) var lastUpdated: Date?
    /// Server-anchored elapsed seconds, recomputed every second by
    /// `tickClock()`. Read-only from the view.
    public private(set) var elapsedSeconds: Int = 0

    private let focusService: FocusService
    private let authSession: AuthSession
    private var poller: FocusPoller?
    private var clockTask: Task<Void, Never>?
    private var updateListenerTask: Task<Void, Never>?

    public init(
        focusService: FocusService = .init(),
        authSession: AuthSession = .shared
    ) {
        self.focusService = focusService
        self.authSession = authSession
        reactToAuthState()
    }

    // MARK: - Poller lifecycle

    public func startPolling() {
        if !authSession.isAuthenticated {
            phase = .unauthenticated
            return
        }
        let poller = FocusPoller(focusService: focusService)
        self.poller = poller
        self.updateListenerTask = Task { @MainActor [weak self] in
            let updates = await poller.updates()
            for await update in updates {
                self?.apply(update: update)
            }
        }
        Task { await poller.start() }
        startClock()
    }

    public func stopPolling() {
        clockTask?.cancel()
        clockTask = nil
        updateListenerTask?.cancel()
        updateListenerTask = nil
        if let poller {
            Task { await poller.stop() }
        }
        poller = nil
    }

    /// Re-evaluate `isAuthenticated` and (re)start the poller accordingly.
    /// Call this from the URL handler after a successful exchange.
    public func reactToAuthState() {
        if authSession.isAuthenticated {
            if poller == nil {
                startPolling()
            }
        } else {
            stopPolling()
            phase = .unauthenticated
        }
    }

    // MARK: - End session

    public func endSession() async {
        guard case .active(let session) = phase, !isEnding else { return }
        isEnding = true
        defer { isEnding = false }
        do {
            _ = try await focusService.end(id: session.id)
            phase = .idle
            elapsedSeconds = 0
        } catch let error as APIError {
            phase = .error(error.errorDescription ?? "Failed to end session")
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    // MARK: - Internals

    private func apply(update: FocusCompanionUpdate) {
        lastUpdated = Date()
        switch update {
        case .idle:
            phase = .idle
            elapsedSeconds = 0
        case .active(let session):
            phase = .active(session: session)
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(session.startedAt)))
        case .reconnecting(let lastKnown):
            // Preserve last known state if any; otherwise show idle.
            if let lastKnown {
                phase = .reconnecting(lastKnown: lastKnown)
            } else {
                phase = .reconnecting(lastKnown: nil)
            }
        case .signedOut:
            authSession.logout()
            phase = .unauthenticated
        case .error(let message):
            phase = .error(message)
        }
    }

    private func startClock() {
        clockTask?.cancel()
        clockTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.tickClock()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func tickClock() {
        guard let session = phase.lastSession else { return }
        elapsedSeconds = max(0, Int(Date().timeIntervalSince(session.startedAt)))
    }
}

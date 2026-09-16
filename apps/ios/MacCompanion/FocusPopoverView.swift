import SwiftUI
import ProductivityOS

/// The popover body for the macOS Focus Companion menu bar item.
///
/// Reads from `FocusCompanionState` and renders the appropriate UI for
/// each `Phase`. The URL handler, idle prompt, active session card, and
/// reconnecting badge are all driven from this single view.
struct FocusPopoverView: View {
    @Environment(\.macAuthCoordinator) private var coordinator
    @State private var authSession = AuthSession.shared
    @State private var state: FocusCompanionState?
    @State private var lastAuthResult: MacAuthResult?
    @State private var isAuthenticating = false
    @State private var popoverWidth: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            if let state {
                contentBody(state: state)
            } else {
                Text("Initializing…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: popoverWidth)
        .onAppear {
            if state == nil {
                state = FocusCompanionState()
                state?.reactToAuthState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .macAuthAttemptCompleted)) { note in
            let success = note.userInfo?["success"] as? Bool ?? false
            if success {
                let email = note.userInfo?["email"] as? String
                self.lastAuthResult = email.map { .authenticated(email: $0) } ?? .authenticated(email: "connected")
                state?.reactToAuthState()
            } else {
                state?.reactToAuthState()
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("Productivity OS")
                .font(.headline)
            Spacer()
            if authSession.isAuthenticated {
                Button("Sign out") {
                    authSession.logout()
                    state?.reactToAuthState()
                }
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func contentBody(state: FocusCompanionState) -> some View {
        switch state.phase {
        case .unauthenticated:
            UnauthenticatedView(isAuthenticating: isAuthenticating)
        case .idle:
            IdleView()
        case .active(let session):
            ActiveSessionCard(
                session: session,
                elapsedSeconds: state.elapsedSeconds,
                isEnding: state.isEnding,
                onEnd: {
                    Task { await state.endSession() }
                }
            )
        case .reconnecting(let lastKnown):
            ReconnectingView(lastKnown: lastKnown, elapsedSeconds: state.elapsedSeconds)
        case .error(let message):
            ErrorView(message: message, onRetry: { state.reactToAuthState() })
        }
        if let message = authFailureMessage {
            Text(message)
                .font(.caption2)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        } else if case .authenticated(let email) = lastAuthResult {
            Text("Connected to \(email)")
                .font(.caption2)
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var authFailureMessage: String? {
        guard let result = lastAuthResult else { return nil }
        switch result {
        case .authenticated:
            return nil
        case .invalidURL:
            return "Not a valid Productivity OS link."
        case .missingChallenge:
            return "The link is missing a challenge token."
        case .challengeExpired:
            return "That pairing link expired. Generate a new one on the web app."
        case .challengeAlreadyUsed:
            return "That pairing link was already used. Generate a new one."
        case .invalidChallenge:
            return "That pairing link was rejected. Generate a new one on the web app."
        case .network(let detail):
            return "Network error: \(detail)"
        case .unknown(let detail):
            return detail
        }
    }
}

// MARK: - Phase subviews

private struct UnauthenticatedView: View {
    let isAuthenticating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAuthenticating ? "Signing in…" : "Not signed in")
                .font(.subheadline)
            Text("Open the web app's Settings, click 'Generate Login QR', then click the productivityos:// link on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct IdleView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Idle")
                .font(.subheadline)
            Text("No focus session active. Start one on your iPhone.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ActiveSessionCard: View {
    let session: FocusSession
    let elapsedSeconds: Int
    let isEnding: Bool
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.taskTitle ?? "Focus session")
                .font(.subheadline)
                .lineLimit(2)
            Text(formatElapsed(elapsedSeconds))
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
            HStack {
                Spacer()
                Button(isEnding ? "Ending…" : "End session") {
                    onEnd()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isEnding)
            }
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

private struct ReconnectingView: View {
    let lastKnown: FocusSession?
    let elapsedSeconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Reconnecting…")
                    .font(.subheadline)
            }
            if let lastKnown {
                Text(lastKnown.taskTitle ?? "Focus session")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatElapsed(elapsedSeconds))
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text("No data yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Something went wrong")
                .font(.subheadline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
            Button("Retry", action: onRetry)
                .controlSize(.small)
        }
    }
}

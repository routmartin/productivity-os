import Foundation

/// Focus session service backed by the FocusController contract:
/// start (`POST /focus`), end (`POST /focus/{id}/end`), active
/// (`GET /focus/active`, 404 → nil), list (`GET /focus`).
///
/// There is no server pause/resume contract: pause/resume is local timer
/// state only (see FocusSessionViewModel). The backend records
/// `durationSeconds = endedAt - startedAt`.
public struct FocusService: Sendable {
    private let apiClient: APIRequesting

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func start(taskId: UUID, configuredDurationSeconds: Int?, note: String? = nil) async throws -> FocusSession {
        let body = try APIClient.encodedBody(
            StartFocusRequestBody(taskId: taskId, configuredDurationSeconds: configuredDurationSeconds, note: note)
        )
        return try await apiClient.request(AppEndpoint.startFocusSession(body: body))
    }

    /// Returns the in-progress session, or nil when none exists (404).
    public func active() async throws -> FocusSession? {
        do {
            return try await apiClient.request(AppEndpoint.getActiveFocusSession)
        } catch let error as APIError {
            if case .notFound = error { return nil }
            throw error
        }
    }

    public func end(id: UUID) async throws -> FocusSession {
        try await apiClient.request(AppEndpoint.endFocusSession(id: id))
    }

    public func listSessions(page: Int = 0, size: Int = 50) async throws -> [FocusSession] {
        try await apiClient.request(AppEndpoint.listFocusSessions(page: page, size: size))
    }
}

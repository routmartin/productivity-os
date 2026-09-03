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
    private let cache: APICache

    public init(apiClient: APIRequesting = APIClient.shared, cache: APICache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }

    public func start(taskId: UUID, configuredDurationSeconds: Int?, note: String? = nil) async throws -> FocusSession {
        let body = try APIClient.encodedBody(
            StartFocusRequestBody(taskId: taskId, configuredDurationSeconds: configuredDurationSeconds, note: note)
        )
        let session: FocusSession = try await apiClient.request(AppEndpoint.startFocusSession(body: body))
        await cache.evict(prefix: "/api/v1/focus")
        return session
    }

    /// Returns the in-progress session, or nil when none exists (404).
    public func active() async throws -> FocusSession? {
        let endpoint = AppEndpoint.getActiveFocusSession
        let key = CacheKey(endpoint: endpoint)
        if let (data, _) = await cache.get(key: key) {
            if data.isEmpty { return nil }
            return try APIClient.jsonDecoder.decode(FocusSession.self, from: data)
        }
        do {
            let (data, response) = try await apiClient.send(endpoint)
            await cache.set(
                key: key,
                data: data,
                statusCode: response.statusCode,
                ttl: APICache.TTL.activeFocusSession
            )
            return try APIClient.jsonDecoder.decode(FocusSession.self, from: data)
        } catch let error as APIError {
            // 404 means "no active session" — cache the negative so we
            // don't hammer the server while the timer is idle.
            if case .notFound = error {
                await cache.set(
                    key: key,
                    data: Data(),
                    statusCode: 404,
                    ttl: APICache.TTL.activeFocusSession
                )
                return nil
            }
            throw error
        }
    }

    public func end(id: UUID) async throws -> FocusSession {
        let session: FocusSession = try await apiClient.request(AppEndpoint.endFocusSession(id: id))
        await cache.evict(prefix: "/api/v1/focus")
        return session
    }

    public func listSessions(page: Int = 0, size: Int = 50) async throws -> [FocusSession] {
        let endpoint = AppEndpoint.listFocusSessions(page: page, size: size)
        let key = CacheKey(endpoint: endpoint)
        if let (data, _) = await cache.get(key: key) {
            return try APIClient.jsonDecoder.decode([FocusSession].self, from: data)
        }
        let (data, response) = try await apiClient.send(endpoint)
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.focusSessions
        )
        return try APIClient.jsonDecoder.decode([FocusSession].self, from: data)
    }
}

import Foundation

/// Transport abstraction so feature services and tests can mock networking.
public protocol APIRequesting: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
}

/// Native URLSession + async/await API Client.
///
/// Auth behavior mirrors the approved web client (`apps/web/src/lib/api/client.ts`):
/// a 401 on any non-auth endpoint triggers exactly one shared
/// `POST /auth/refresh`; on success the original request is retried once,
/// on failure the session is cleared (the app returns to the login screen).
/// The refresh token travels only in the backend's HttpOnly cookie scoped to
/// `/api/v1/auth`, handled by URLSession's cookie storage.
public final class APIClient: APIRequesting, @unchecked Sendable {
    public static let shared = APIClient()

    private let session: URLSession
    private let config: APIConfiguration
    private let authSession: AuthSession

    /// Single-flight guard so concurrent 401s share one refresh attempt.
    private let lock = NSLock()
    private var refreshTask: Task<Bool, Never>?

    public init(
        session: URLSession = .shared,
        config: APIConfiguration = .shared,
        authSession: AuthSession = .shared
    ) {
        self.session = session
        self.config = config
        self.authSession = authSession
    }

    // MARK: - Shared JSON decoding (ADR-006: ISO-8601 instants, date-only strings)

    public static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractionalFormatter.date(from: dateString) {
                return date
            }

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
        return decoder
    }()

    // MARK: - Typed request

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, _) = try await send(endpoint)

        do {
            return try Self.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Raw transport

    public func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        try await perform(endpoint, isRetry: false)
    }

    /// Encodes a JSON request body.
    public static func encodedBody<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(value)
    }

    private func perform(_ endpoint: Endpoint, isRetry: Bool) async throws -> (Data, HTTPURLResponse) {
        let (data, httpResponse) = try await execute(endpoint)

        switch httpResponse.statusCode {
        case 200...299:
            return (data, httpResponse)

        case 401:
            // Login/register 401 = bad credentials; refresh 401 = session over.
            // Never attempt refresh on auth endpoints (prevents loops).
            guard !endpoint.isAuthEndpoint, !isRetry else {
                throw APIError(statusCode: 401, data: data)
            }
            let refreshed = await refreshAccessToken()
            guard refreshed else {
                // Refresh failed → clear session; app root shows the login screen.
                authSession.logout()
                throw APIError.unauthorized(code: nil, message: nil)
            }
            return try await perform(endpoint, isRetry: true)

        default:
            throw APIError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func execute(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        var urlComponents = URLComponents(
            url: config.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = endpoint.body
        }

        // Bearer access token on authenticated endpoints only.
        if !endpoint.isAuthEndpoint, let token = authSession.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        NetworkLogger.log(request: request)

        let data: Data, response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            NetworkLogger.log(error: error, url: request.url)
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        NetworkLogger.log(response: httpResponse, data: data)
        
        return (data, httpResponse)
    }

    // MARK: - Silent refresh (single flight)

    private func refreshAccessToken() async -> Bool {
        let existing = lock.withLock { refreshTask }
        if let existing {
            return await existing.value
        }
        let task = Task<Bool, Never> { [session, config, authSession] in
            await Self.performRefresh(session: session, config: config, authSession: authSession)
        }
        lock.withLock { refreshTask = task }

        let result = await task.value
        lock.withLock {
            refreshTask = nil
        }
        return result
    }

    private static func performRefresh(session: URLSession, config: APIConfiguration, authSession: AuthSession) async -> Bool {
        let endpoint = AppEndpoint.refresh
        let url = config.baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data, response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            return false
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return false
        }

        guard let decoded = try? APIClient.jsonDecoder.decode(AuthResponse.self, from: data) else {
            return false
        }

        // Preserve cached profile: refresh responds with user == null.
        authSession.setSession(accessToken: decoded.accessToken, refreshToken: nil, user: nil)
        return true
    }
}

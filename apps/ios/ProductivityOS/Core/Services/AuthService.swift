import Foundation
import Observation

/// Authentication service built on the shared APIClient.
/// Mirrors the backend AuthController contract: login/register return an
/// access token (+ user); refresh and logout rely on the HttpOnly cookie.
@Observable
public final class AuthService: @unchecked Sendable {
    public static let shared = AuthService()

    private let apiClient: APIRequesting
    private let authSession: AuthSession

    public init(apiClient: APIRequesting = APIClient.shared, authSession: AuthSession = .shared) {
        self.apiClient = apiClient
        self.authSession = authSession
    }

    // MARK: - Login / Register / Logout

    public func login(email: String, password: String) async throws {
        let body = try APIClient.encodedBody(LoginRequestBody(email: email, password: password))
        let response = try await apiClient.request(AppEndpoint.login(body: body)) as AuthResponse
        authSession.setSession(accessToken: response.accessToken, user: response.domainUser)
    }

    public func register(email: String, password: String) async throws {
        // Backend requires password >= 12 chars (RegisterRequest validation).
        let body = try APIClient.encodedBody(
            RegisterRequestBody(email: email, password: password, timezone: Self.currentTimeZoneIdentifier)
        )
        _ = try await apiClient.request(AppEndpoint.register(body: body)) as UserDTO
    }

    public func logout() async {
        // Best-effort server logout (revokes the refresh token + clears cookie).
        _ = try? await apiClient.send(AppEndpoint.logout)
        authSession.logout()
    }

    // MARK: - Session restoration

    /// Restores the persisted session from Keychain (access token + profile).
    /// The app root observes `AuthSession.isAuthenticated`, so a still-valid
    /// token lands directly in the authenticated state; an expired one simply
    /// triggers the silent refresh on the first API call.
    @discardableResult
    public func restoreSession() -> Bool {
        authSession.isAuthenticated
    }

    private static var currentTimeZoneIdentifier: String? {
        TimeZone.current.identifier
    }
}

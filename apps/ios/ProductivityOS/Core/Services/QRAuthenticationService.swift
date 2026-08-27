import Foundation

/// DTO for QR Authentication exchange
public struct QrExchangeRequest: Encodable {
    public let challenge: String
    
    public init(challenge: String) {
        self.challenge = challenge
    }
}

/// Service for QR-based authentication on iOS.
public final class QRAuthenticationService: Sendable {
    public static let shared = QRAuthenticationService()
    
    private let apiClient: APIRequesting
    private let authSession: AuthSession
    
    public init(apiClient: APIRequesting = APIClient.shared, authSession: AuthSession = .shared) {
        self.apiClient = apiClient
        self.authSession = authSession
    }
    
    /// Exchanges a scanned QR challenge for a full session.
    public func authenticate(challenge: String) async throws {
        let request = QrExchangeRequest(challenge: challenge)
        let body = try APIClient.encodedBody(request)
        
        // The backend returns a standard LoginResponse on successful exchange.
        let response: AuthResponse = try await apiClient.request(AppEndpoint.qrExchange(body: body))
        
        // Update the session: accessToken + domainUser.
        // Refresh token is handled by HTTP-only cookie in URLSession.
        authSession.setSession(
            accessToken: response.accessToken,
            user: response.domainUser
        )
    }
    
    /// Validates if a QR string is a valid Productivity OS auth URL.
    public func parseChallenge(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              url.scheme == "productivityos",
              url.host == "auth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let challenge = components.queryItems?.first(where: { $0.name == "challenge" })?.value
        else {
            return nil
        }
        return challenge
    }
}

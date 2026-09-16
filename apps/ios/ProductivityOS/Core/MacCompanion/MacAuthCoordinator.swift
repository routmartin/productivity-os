import Foundation
import OSLog

/// Outcome of handling an incoming `productivityos://auth?challenge=...` URL.
public enum MacAuthResult: Equatable, Sendable {
    case authenticated(email: String)
    case invalidURL
    case missingChallenge
    case challengeExpired
    case challengeAlreadyUsed
    case invalidChallenge
    case network(String)
    case unknown(String)
}

/// Handles QR-pairing deep links on macOS.
///
/// The web app issues a `productivityos://auth?challenge=<token>` URL after
/// the user clicks "Generate Login QR" while signed in. The Mac companion
/// receives that URL via `.onOpenURL`, validates the shape, exchanges the
/// challenge for an access token, and updates the shared `AuthSession`.
///
/// This type is the single source of truth for what counts as a valid Mac
/// pairing URL and what to do with it. The iOS app uses a private
/// `QRAuthenticationService` for the inverse flow (scan a QR produced by
/// another device); both share the same `POST /api/v1/auth/qr/exchange`
/// endpoint.
public struct MacAuthCoordinator: Sendable {
    private let apiClient: APIRequesting
    private let authSession: AuthSession

    public init(apiClient: APIRequesting = APIClient.shared, authSession: AuthSession = .shared) {
        self.apiClient = apiClient
        self.authSession = authSession
    }

    /// Extract the challenge token from a `productivityos://auth?challenge=...` URL.
    /// Returns `nil` for anything else (wrong scheme, host, or missing query item).
    public static func parseChallenge(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              url.scheme == "productivityos",
              url.host == "auth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let challenge = components.queryItems?.first(where: { $0.name == "challenge" })?.value,
              !challenge.isEmpty
        else {
            return nil
        }
        return challenge
    }

    /// Validate a URL and, if it carries a usable challenge, attempt the exchange.
    /// Updates `AuthSession` on success. The caller is expected to surface the
    /// result via UI (popover message, banner, etc.).
    @discardableResult
    public func handle(urlString: String) async -> MacAuthResult {
        guard let challenge = Self.parseChallenge(from: urlString) else {
            os_log(.error, log: .default, "🔐 [Mac] URL not a valid pairing link: %{private}@", urlString)
            return .invalidURL
        }
        return await handle(challenge: challenge)
    }

    @discardableResult
    public func handle(challenge: String) async -> MacAuthResult {
        os_log(.debug, log: .default, "🔐 [Mac] Exchanging pairing challenge (length=%d)", challenge.count)
        let request = QrExchangeRequest(challenge: challenge)
        guard let body = try? APIClient.encodedBody(request) else {
            return .unknown("Failed to encode request")
        }
        do {
            let response: AuthResponse = try await apiClient.request(AppEndpoint.qrExchange(body: body))
            authSession.setSession(
                accessToken: response.accessToken,
                user: response.domainUser
            )
            let email = response.domainUser?.email ?? "unknown"
            os_log(.info, log: .default, "🔐 [Mac] Authenticated as %{private}@", email)
            return .authenticated(email: email)
        } catch let error as APIError {
            os_log(.error, log: .default, "🔐 [Mac] Exchange failed: %{public}@", String(describing: error))
            return Self.classify(error: error)
        } catch {
            os_log(.error, log: .default, "🔐 [Mac] Exchange failed: %{public}@", error.localizedDescription)
            return .unknown(error.localizedDescription)
        }
    }

    private static func classify(error: APIError) -> MacAuthResult {
        switch error {
        case .unauthorized(let code, _):
            // Backend maps invalid/used/expired challenges to 401 with a
            // distinct `code` per cause. Surface the most common ones
            // explicitly so the popover can prompt the user to generate
            // a fresh QR on the web app.
            switch code {
            case "challenge_expired":
                return .challengeExpired
            case "challenge_already_used":
                return .challengeAlreadyUsed
            case "invalid_challenge":
                return .invalidChallenge
            default:
                return .invalidChallenge
            }
        case .networkError(let message):
            return .network(message)
        case .decodingError(let message):
            return .unknown(message)
        case .invalidURL:
            return .invalidURL
        case .serverError(_, _, let message):
            return .unknown(message ?? "Server error")
        case .forbidden, .notFound, .unknown:
            return .unknown(error.errorDescription ?? "Unknown error")
        }
    }
}

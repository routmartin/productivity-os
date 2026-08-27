import Foundation
import Observation

/// Observable authentication session state and credentials holder.
///
/// The backend never returns the refresh token in a response body; it sets an
/// HttpOnly cookie scoped to `/api/v1/auth` which URLSession's shared cookie
/// storage attaches automatically to refresh/logout calls. Only the short-lived
/// access token and the cached user profile are stored here (Keychain-backed).
@Observable
public final class AuthSession: @unchecked Sendable {
    public static let shared = AuthSession()

    private let keychain: KeychainManager
    private let accessTokenKey = "auth_access_token"
    private let userStorageKey = "auth_current_user"

    public var currentUser: User?

    public var isAuthenticated: Bool {
        accessToken != nil
    }

    public var accessToken: String? {
        didSet {
            if let accessToken {
                _ = keychain.save(key: accessTokenKey, string: accessToken)
            } else {
                keychain.delete(key: accessTokenKey)
            }
        }
    }

    public init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
        self.accessToken = keychain.readString(key: accessTokenKey)

        if let userData = keychain.readData(key: userStorageKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
    }

    public func setSession(accessToken: String, refreshToken: String? = nil, user: User?) {
        self.accessToken = accessToken
        if let user {
            self.currentUser = user
            if let encoded = try? JSONEncoder().encode(user) {
                _ = keychain.save(key: userStorageKey, data: encoded)
            }
        }
    }

    public func logout() {
        self.accessToken = nil
        self.currentUser = nil
        _ = keychain.delete(key: userStorageKey)
    }
}

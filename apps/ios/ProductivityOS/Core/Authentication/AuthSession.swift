import Foundation
import Observation

/// Observable authentication session state and credentials holder.
///
/// Authentication tokens and user profile are persisted securely in Keychain.
/// The access token is used as a Bearer token on authenticated endpoints.
/// The refresh token is returned in the auth response body and persisted in
/// Apple Keychain, then sent via `X-Refresh-Token` header as a fallback to
/// URLSession HttpOnly cookies for rotation and logout.
@Observable
public final class AuthSession: @unchecked Sendable {
    public static let shared = AuthSession()

    private let keychain: KeychainManager
    private let accessTokenKey = "auth_access_token"
    private let refreshTokenKey = "auth_refresh_token"
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

    public var refreshToken: String? {
        didSet {
            if let refreshToken {
                _ = keychain.save(key: refreshTokenKey, string: refreshToken)
            } else {
                keychain.delete(key: refreshTokenKey)
            }
        }
    }

    public init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
        self.accessToken = keychain.readString(key: accessTokenKey)
        self.refreshToken = keychain.readString(key: refreshTokenKey)

        if let userData = keychain.readData(key: userStorageKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
    }

    public func setSession(accessToken: String, refreshToken: String? = nil, user: User?) {
        self.accessToken = accessToken
        if let refreshToken {
            self.refreshToken = refreshToken
        }
        if let user {
            self.currentUser = user
            if let encoded = try? JSONEncoder().encode(user) {
                _ = keychain.save(key: userStorageKey, data: encoded)
            }
        }
    }

    public func logout() {
        self.accessToken = nil
        self.refreshToken = nil
        self.currentUser = nil
        keychain.delete(key: accessTokenKey)
        keychain.delete(key: refreshTokenKey)
        keychain.delete(key: userStorageKey)
    }
}

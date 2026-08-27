import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Endpoint protocol for type-safe API definitions
public protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    /// Auth endpoints never trigger a token refresh attempt and never carry
    /// the Bearer header (mirrors web client `isNonRefreshablePath`).
    var isAuthEndpoint: Bool { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var isAuthEndpoint: Bool { false }
}

/// Predefined API endpoints matching the Productivity OS backend controllers.
/// Paths are the source of truth from the Kotlin controllers — do not invent.
public enum AppEndpoint: Endpoint {
    // Auth (/api/v1/auth)
    case register(body: Data)
    case login(body: Data)
    case qrExchange(body: Data)
    case refresh
    case logout

    // Tasks (/api/v1/tasks)
    case listTasks(page: Int = 0, size: Int = 50)

    // Daily Top 3 (/api/v1/daily-top-three/{date})
    case getDailyTopThree(date: String)

    // Focus (/api/v1/focus)
    case getActiveFocusSession
    case startFocusSession(body: Data)
    case endFocusSession(id: UUID)
    case listFocusSessions(page: Int = 0, size: Int = 50)

    public var path: String {
        switch self {
        case .register:
            return "/api/v1/auth/register"
        case .login:
            return "/api/v1/auth/login"
        case .qrExchange:
            return "/api/v1/auth/qr/exchange"
        case .refresh:
            return "/api/v1/auth/refresh"
        case .logout:
            return "/api/v1/auth/logout"

        case .listTasks:
            return "/api/v1/tasks"

        case .getDailyTopThree(let date):
            return "/api/v1/daily-top-three/\(date)"

        case .getActiveFocusSession:
            return "/api/v1/focus/active"
        case .startFocusSession:
            return "/api/v1/focus"
        case .endFocusSession(let id):
            return "/api/v1/focus/\(id.uuidString.lowercased())/end"
        case .listFocusSessions:
            return "/api/v1/focus"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .register, .login, .qrExchange, .refresh, .logout,
             .startFocusSession, .endFocusSession:
            return .post
        case .listTasks, .getDailyTopThree, .getActiveFocusSession, .listFocusSessions:
            return .get
        }
    }

    public var body: Data? {
        switch self {
        case .register(let data), .login(let data), .qrExchange(let data), .startFocusSession(let data):
            return data
        default:
            return nil
        }
    }

    public var isAuthEndpoint: Bool {
        switch self {
        case .register, .login, .qrExchange, .refresh, .logout:
            return true
        default:
            return false
        }
    }

    public var queryItems: [URLQueryItem]? {
        switch self {
        case .listTasks(let page, let size):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "size", value: "\(size)")
            ]
        case .listFocusSessions(let page, let size):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "size", value: "\(size)")
            ]
        default:
            return nil
        }
    }
}

import Foundation

/// Shared in-memory response cache for read-only API endpoints.
///
/// The iOS app is read-only for projects/goals/tasks (mutations live on the
/// web client per spec), and those resources change rarely. This cache
/// makes tab-switching between Today / Tasks / Goals feel instant after
/// the first load, while pull-to-refresh and explicit mutations always
/// bypass it.
///
/// Design:
/// - One `actor` for thread-safe access from any context.
/// - Entries keyed by the canonical request signature (HTTP method, path,
///   query items). Path-only is sufficient for the current endpoint set
///   because the only GETs we cache take no body and use path/query for
///   identity.
/// - Each entry has a `TTL`. Missing/expired entries fall through to the
///   network.
/// - Mutations (task update, focus session end) call `evict(matching:)`
///   so stale reads can't survive a write.
/// - `reset()` clears everything — used by tests so per-test mocks see a
///   clean slate.
public actor APICache {
    public static let shared = APICache()

    private struct Entry {
        let data: Data
        let storedAt: Date
        let ttl: TimeInterval
        let statusCode: Int
    }

    private var entries: [CacheKey: Entry] = [:]

    public init() {}

    // MARK: - Read / write

    /// Returns cached response bytes + status if a fresh entry exists.
    public func get(key: CacheKey, now: Date = Date()) -> (Data, Int)? {
        guard let entry = entries[key] else { return nil }
        if now.timeIntervalSince(entry.storedAt) >= entry.ttl {
            entries.removeValue(forKey: key)
            return nil
        }
        return (entry.data, entry.statusCode)
    }

    /// Stores a response. Replaces any prior entry under the same key.
    public func set(key: CacheKey, data: Data, statusCode: Int, ttl: TimeInterval, now: Date = Date()) {
        entries[key] = Entry(data: data, storedAt: now, ttl: ttl, statusCode: statusCode)
    }

    /// Removes every entry whose key matches `prefix`. Used after mutations
    /// that may have invalidated any number of read responses for a resource.
    public func evict(prefix: String) {
        entries = entries.filter { !$0.key.path.hasPrefix(prefix) }
    }

    /// Removes a single entry. Used when the caller knows the exact signature.
    public func evict(key: CacheKey) {
        entries.removeValue(forKey: key)
    }

    /// Wipes the entire cache. Test-only entry point.
    public func reset() {
        entries.removeAll()
    }
}

/// Stable identity for a cached response.
///
/// The current `AppEndpoint` set only uses path + query for GET identity
/// (no body, no header-driven variation), so a path-only key is sufficient.
/// If a future endpoint varies on a header, extend `CacheKey` rather than
/// inventing a new cache layer.
public struct CacheKey: Hashable, Sendable {
    public let method: String
    public let path: String

    public init(method: String, path: String) {
        self.method = method
        self.path = path
    }

    /// Builds a cache key from an endpoint. Path is the full path including
    /// any URL-encoded query string so `?page=0` and `?page=1` don't collide.
    public init(endpoint: Endpoint) {
        self.method = endpoint.method.rawValue
        var path = endpoint.path
        if let items = endpoint.queryItems, !items.isEmpty {
            var components = URLComponents()
            components.path = endpoint.path
            components.queryItems = items
            if let url = components.url, let query = url.query {
                path = endpoint.path + "?" + query
            }
        }
        self.path = path
    }
}

extension APICache {
    /// TTL policy per resource family. Values were chosen so that the
    /// fastest-changing data (focus stats, top-three for "today") refreshes
    /// within a minute while the slow-changing resources (goals, projects)
    /// stay warm across the entire session.
    public enum TTL {
        public static let goals: TimeInterval = 10 * 60
        public static let projects: TimeInterval = 10 * 60
        public static let projectTasks: TimeInterval = 60
        public static let activeTasks: TimeInterval = 60
        public static let topThree: TimeInterval = 60
        public static let focusSessions: TimeInterval = 30
        public static let activeFocusSession: TimeInterval = 10
    }
}
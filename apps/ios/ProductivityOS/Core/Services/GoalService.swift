import Foundation

/// Goal domain service backed by `GET /api/v1/goals`
/// and `GET /api/v1/goals/{id}`.
public struct GoalService: Sendable {
    private let apiClient: APIRequesting
    private let cache: APICache

    public init(apiClient: APIRequesting = APIClient.shared, cache: APICache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }

    public func listGoals() async throws -> [Goal] {
        let key = CacheKey(endpoint: AppEndpoint.listGoals)
        if let (data, status) = await cache.get(key: key) {
            return try Self.decode(data: data, status: status)
        }
        let (data, response) = try await apiClient.send(AppEndpoint.listGoals)
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.goals
        )
        return try Self.decode(data: data, status: response.statusCode)
    }

    public func getGoal(id: UUID) async throws -> Goal {
        let endpoint = AppEndpoint.getGoal(id: id)
        let key = CacheKey(endpoint: endpoint)
        if let (data, status) = await cache.get(key: key) {
            return try Self.decode(data: data, status: status)
        }
        let (data, response) = try await apiClient.send(endpoint)
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.goals
        )
        return try Self.decode(data: data, status: response.statusCode)
    }

    private static func decode<T: Decodable>(data: Data, status: Int) throws -> T {
        do {
            return try APIClient.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw APIError(statusCode: status, data: data)
        }
    }
}
import Foundation

/// Project domain service backed by `GET /api/v1/projects`
/// and `GET /api/v1/projects/{id}/tasks`.
public struct ProjectService: Sendable {
    private let apiClient: APIRequesting
    private let cache: APICache

    public init(apiClient: APIRequesting = APIClient.shared, cache: APICache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }

    public func listProjects() async throws -> [Project] {
        let key = CacheKey(endpoint: AppEndpoint.listProjects)
        if let (data, status) = await cache.get(key: key) {
            return try Self.decode(data: data, status: status)
        }
        let (data, response) = try await apiClient.send(AppEndpoint.listProjects)
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.projects
        )
        return try Self.decode(data: data, status: response.statusCode)
    }

    public func listTasks(projectId: UUID) async throws -> [TaskItem] {
        let endpoint = AppEndpoint.listProjectTasks(id: projectId)
        let key = CacheKey(endpoint: endpoint)
        if let (data, status) = await cache.get(key: key) {
            return try Self.decode(data: data, status: status)
        }
        let (data, response) = try await apiClient.send(endpoint)
        await cache.set(
            key: key,
            data: data,
            statusCode: response.statusCode,
            ttl: APICache.TTL.projectTasks
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

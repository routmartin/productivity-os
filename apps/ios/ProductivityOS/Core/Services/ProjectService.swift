import Foundation

/// Project domain service backed by `GET /api/v1/projects`
/// and `GET /api/v1/projects/{id}/tasks`.
public struct ProjectService: Sendable {
    private let apiClient: APIRequesting

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func listProjects() async throws -> [Project] {
        try await apiClient.request(AppEndpoint.listProjects)
    }

    public func listTasks(projectId: UUID) async throws -> [TaskItem] {
        try await apiClient.request(AppEndpoint.listProjectTasks(id: projectId))
    }
}

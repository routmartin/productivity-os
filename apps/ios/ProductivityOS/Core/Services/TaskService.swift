import Foundation

/// Task domain service backed by `GET /api/v1/tasks`.
/// V1 list endpoints return plain JSON arrays (no Page envelope).
public struct TaskService: Sendable {
    private let apiClient: APIRequesting

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func listActiveTasks(page: Int = 0, size: Int = 50) async throws -> [TaskItem] {
        try await apiClient.request(AppEndpoint.listTasks(page: page, size: size))
    }
}

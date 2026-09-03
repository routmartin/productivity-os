import Foundation

/// Goal domain service backed by `GET /api/v1/goals`
/// and `GET /api/v1/goals/{id}`.
public struct GoalService: Sendable {
    private let apiClient: APIRequesting

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func listGoals() async throws -> [Goal] {
        try await apiClient.request(AppEndpoint.listGoals)
    }

    public func getGoal(id: UUID) async throws -> Goal {
        try await apiClient.request(AppEndpoint.getGoal(id: id))
    }
}
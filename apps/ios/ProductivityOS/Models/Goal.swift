import Foundation

/// Goal status from the backend `GoalStatus` enum
/// (`DRAFT`, `ACTIVE`, `COMPLETED`, `ARCHIVED`).
public enum GoalStatus: String, Codable, CaseIterable, Sendable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case archived = "ARCHIVED"
}

/// Goal domain model matching backend `GoalResponse`
/// (apps/api `goal/dto/GoalResponse.kt`). The backend does not expose a
/// `progress` field — progress is derived client-side from the goal's
/// projects and their tasks.
public struct Goal: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String?
    public let status: GoalStatus
    public let deadline: Date?
    public let completedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        title: String,
        description: String? = nil,
        status: GoalStatus = .active,
        deadline: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.status = status
        self.deadline = deadline
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
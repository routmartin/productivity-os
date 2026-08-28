import Foundation

/// Project status from the backend `ProjectStatus` enum.
public enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case archived = "ARCHIVED"
}

/// Project domain model matching backend `ProjectResponse`.
public struct Project: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String?
    public let goalId: UUID?
    public let status: ProjectStatus
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        userId: UUID,
        title: String,
        description: String? = nil,
        goalId: UUID? = nil,
        status: ProjectStatus,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.goalId = goalId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

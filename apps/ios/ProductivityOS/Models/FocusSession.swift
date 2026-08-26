import Foundation

/// Focus session model matching backend FocusSessionResponse
public struct FocusSession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let taskId: UUID
    public let taskTitle: String?
    public let startedAt: Date
    public let endedAt: Date?
    public let durationSeconds: Int?
    public let configuredDurationSeconds: Int?
    public let note: String?
    public let isActive: Bool
    
    public init(
        id: UUID = UUID(),
        taskId: UUID,
        taskTitle: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        configuredDurationSeconds: Int? = nil,
        note: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.configuredDurationSeconds = configuredDurationSeconds
        self.note = note
        self.isActive = isActive
    }
}

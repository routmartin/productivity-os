import Foundation

/// Daily Top Three item model matching backend TopThreeResponse
public struct TopThreeItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let taskId: UUID?
    public let taskTitle: String?
    public let calendarDate: String
    public let position: Int
    public let isCompleted: Bool
    public let isDeleted: Bool
    public let isCancelled: Bool
    public let projectName: String?
    public let priority: TaskPriority?
    
    public init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        taskTitle: String? = nil,
        calendarDate: String = "2026-08-26",
        position: Int = 1,
        isCompleted: Bool = false,
        isDeleted: Bool = false,
        isCancelled: Bool = false,
        projectName: String? = "Productivity OS",
        priority: TaskPriority? = .medium
    ) {
        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.calendarDate = calendarDate
        self.position = position
        self.isCompleted = isCompleted
        self.isDeleted = isDeleted
        self.isCancelled = isCancelled
        self.projectName = projectName
        self.priority = priority
    }
}

import SwiftUI

/// Task Priority enum matching backend and design pills
public enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
    case none = "NONE"
    
    public var title: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .none: return "None"
        }
    }
    
    public var backgroundColor: Color {
        switch self {
        case .high: return AppColors.priorityHighBackground
        case .medium: return AppColors.priorityMediumBackground
        case .low: return AppColors.priorityLowBackground
        case .none: return AppColors.surfaceBorder
        }
    }
    
    public var foregroundColor: Color {
        switch self {
        case .high: return AppColors.priorityHighText
        case .medium: return AppColors.priorityMediumText
        case .low: return AppColors.priorityLowText
        case .none: return AppColors.textSecondary
        }
    }
}

/// Task Energy level enum
public enum TaskEnergy: String, Codable, CaseIterable, Sendable {
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
}

/// Task Status enum
public enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case inbox = "INBOX"
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"

    /// Resilient decode: unknown server-side statuses don't break the
    /// whole batch. We default to `.pending` so the task still renders and
    /// the rest of the list loads. Surface the unknown value in the OSLog
    /// so future drift is visible without crashing the screen.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if let known = TaskStatus(rawValue: raw) {
            self = known
        } else {
            print("[TaskStatus] unknown raw value '\(raw)' — defaulting to .pending")
            self = .pending
        }
    }
}

/// Task domain model matching backend TaskResponse
public struct TaskItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let ownerId: UUID?
    public let title: String
    public let description: String?
    public let dueDate: String?
    public let priority: TaskPriority?
    public let energy: TaskEnergy?
    public let estimatedDurationMinutes: Int?
    public let status: TaskStatus
    public let completedAt: Date?
    public let deletedAt: Date?
    public let projectId: UUID?
    public let projectName: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    
    public init(
        id: UUID = UUID(),
        ownerId: UUID? = nil,
        title: String,
        description: String? = nil,
        dueDate: String? = nil,
        priority: TaskPriority? = .medium,
        energy: TaskEnergy? = .medium,
        estimatedDurationMinutes: Int? = 30,
        status: TaskStatus = .pending,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        projectId: UUID? = nil,
        projectName: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.energy = energy
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.status = status
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.projectId = projectId
        self.projectName = projectName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var isCompleted: Bool {
        status == .completed || completedAt != nil
    }
    
    public var formattedDuration: String {
        guard let minutes = estimatedDurationMinutes else { return "30m" }
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

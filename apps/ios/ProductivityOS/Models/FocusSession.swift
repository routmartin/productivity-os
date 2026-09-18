import Foundation

/// Focus session model matching backend FocusSessionResponse.
///
/// Pause state (`isPaused`, `pausedAt`, `accumulatedPausedSeconds`) is decoded
/// leniently so older payloads and test fixtures without those keys still
/// decode (ADR-008).
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
    /// Active session is currently paused.
    public let isPaused: Bool
    /// Open pause start, nil when running or ended.
    public let pausedAt: Date?
    /// Total of closed pause intervals; excludes the currently open pause.
    public let accumulatedPausedSeconds: Int

    public init(
        id: UUID = UUID(),
        taskId: UUID,
        taskTitle: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        configuredDurationSeconds: Int? = nil,
        note: String? = nil,
        isActive: Bool = true,
        isPaused: Bool = false,
        pausedAt: Date? = nil,
        accumulatedPausedSeconds: Int = 0
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
        self.isPaused = isPaused
        self.pausedAt = pausedAt
        self.accumulatedPausedSeconds = accumulatedPausedSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case id, taskId, taskTitle, startedAt, endedAt, durationSeconds
        case configuredDurationSeconds, note, isActive, isPaused, pausedAt
        case accumulatedPausedSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        taskId = try container.decode(UUID.self, forKey: .taskId)
        taskTitle = try container.decodeIfPresent(String.self, forKey: .taskTitle)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        configuredDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .configuredDurationSeconds)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? (endedAt == nil)
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
        accumulatedPausedSeconds = try container.decodeIfPresent(Int.self, forKey: .accumulatedPausedSeconds) ?? 0
    }
}

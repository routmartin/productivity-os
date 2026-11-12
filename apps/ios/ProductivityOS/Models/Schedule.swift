import Foundation

/// Layout projections for the Daily Schedule Link-Map (Spec AC-001).
public enum ScheduleLayoutMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case spine
    case journey
    case matrix

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .spine: return "Spine"
        case .journey: return "Journey"
        case .matrix: return "Matrix"
        }
    }

    public var iconName: String {
        switch self {
        case .spine: return "point.topleft.down.to.point.bottomright.curvepath"
        case .journey: return "arrow.triangle.swap"
        case .matrix: return "square.grid.2x2"
        }
    }
}

public enum ScheduleNodeType: String, Codable, Sendable {
    case anchor
    case habit
    case task
    case recharge

    /// Alias for task/activity blocks
    public static var activity: ScheduleNodeType { .task }
}

public enum ScheduleEdgeType: String, Codable, Sendable {
    case sequential
    case prerequisite
    case phase
}

public enum SchedulePhaseId: String, CaseIterable, Identifiable, Codable, Sendable {
    case morning = "morning"
    case deepFocus = "deep-focus"
    case afternoon = "afternoon"
    case bedtime = "bedtime"

    public var id: String { rawValue }

    public var defaultTitle: String {
        switch self {
        case .morning: return "Morning Activation"
        case .deepFocus: return "Deep Focus Work"
        case .afternoon: return "Afternoon Momentum"
        case .bedtime: return "Bedtime Sanctuary"
        }
    }

    public var defaultSubtitle: String {
        switch self {
        case .morning: return "Rise, hydrate, move & set daily direction"
        case .deepFocus: return "Uninterrupted creative flow on Top 1 & Top 2"
        case .afternoon: return "Top 3, collaboration, shallow work & reset"
        case .bedtime: return "Digital curfew, reflection, reading & sleep recovery"
        }
    }

    public var defaultTimeRange: String {
        switch self {
        case .morning: return "06:30 – 09:00"
        case .deepFocus: return "09:00 – 12:30"
        case .afternoon: return "12:30 – 18:00"
        case .bedtime: return "21:00 – 22:30"
        }
    }

    public var tone: String {
        switch self {
        case .morning: return "warning"
        case .deepFocus: return "accent"
        case .afternoon: return "blue"
        case .bedtime: return "success"
        }
    }
}

public struct SchedulePhase: Identifiable, Codable, Sendable, Hashable {
    public let id: SchedulePhaseId
    public var title: String
    public var subtitle: String
    public var timeRange: String
    public var colorTone: String?

    public init(
        id: SchedulePhaseId,
        title: String,
        subtitle: String,
        timeRange: String,
        colorTone: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.timeRange = timeRange
        self.colorTone = colorTone
    }
}

public struct HabitStreakDay: Identifiable, Codable, Sendable, Hashable {
    public var id: String { date }
    public let date: String
    public var completed: Bool

    public init(date: String, completed: Bool) {
        self.date = date
        self.completed = completed
    }
}

public struct ScheduleNode: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public var type: ScheduleNodeType
    public var phase: SchedulePhaseId
    public var title: String
    public var subtitle: String?
    public var time: String?
    public var durationMinutes: Int?

    // Habit-specific
    public var habitId: String?
    public var icon: String?
    public var streak: Int?
    public var completed: Bool?
    public var frequency: String?
    public var history: [HabitStreakDay]?

    // Task / Activity-specific
    public var taskId: String?
    public var priority: String?
    public var inFocus: Bool?
    public var completedMinutes: Int?
    public var totalMinutes: Int?
    public var projectName: String?

    // Anchor-specific
    public var anchorKind: String? // "wake" | "bedtime"
    public var targetTime: String?
    public var projectedTime: String?
    public var overflowMinutes: Int?

    // Recharge-specific
    public var rechargeKind: String? // "break" | "nutrition" | "walk" | "winddown"

    // General
    public var notes: String?
    public var order: Int?

    public init(
        id: String,
        type: ScheduleNodeType,
        phase: SchedulePhaseId,
        title: String,
        subtitle: String? = nil,
        time: String? = nil,
        durationMinutes: Int? = nil,
        habitId: String? = nil,
        icon: String? = nil,
        streak: Int? = nil,
        completed: Bool? = nil,
        frequency: String? = nil,
        history: [HabitStreakDay]? = nil,
        taskId: String? = nil,
        priority: String? = nil,
        inFocus: Bool? = nil,
        completedMinutes: Int? = nil,
        totalMinutes: Int? = nil,
        projectName: String? = nil,
        anchorKind: String? = nil,
        targetTime: String? = nil,
        projectedTime: String? = nil,
        overflowMinutes: Int? = nil,
        rechargeKind: String? = nil,
        notes: String? = nil,
        order: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.phase = phase
        self.title = title
        self.subtitle = subtitle
        self.time = time
        self.durationMinutes = durationMinutes
        self.habitId = habitId
        self.icon = icon
        self.streak = streak
        self.completed = completed
        self.frequency = frequency
        self.history = history
        self.taskId = taskId
        self.priority = priority
        self.inFocus = inFocus
        self.completedMinutes = completedMinutes
        self.totalMinutes = totalMinutes
        self.projectName = projectName
        self.anchorKind = anchorKind
        self.targetTime = targetTime
        self.projectedTime = projectedTime
        self.overflowMinutes = overflowMinutes
        self.rechargeKind = rechargeKind
        self.notes = notes
        self.order = order
    }
}

public struct ScheduleEdge: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let fromNodeId: String
    public let toNodeId: String
    public var type: ScheduleEdgeType?
    public var active: Bool?
    public var label: String?

    public init(
        id: String,
        fromNodeId: String,
        toNodeId: String,
        type: ScheduleEdgeType? = .sequential,
        active: Bool? = false,
        label: String? = nil
    ) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.type = type
        self.active = active
        self.label = label
    }
}

public struct ScheduleGraph: Codable, Sendable, Hashable {
    public var date: String
    public var wakeTime: String
    public var targetBedtime: String
    public var projectedBedtime: String
    public var overflowMinutes: Int
    public var phases: [SchedulePhase]
    public var nodes: [ScheduleNode]
    public var edges: [ScheduleEdge]

    public init(
        date: String,
        wakeTime: String = "06:30",
        targetBedtime: String = "22:30",
        projectedBedtime: String = "22:30",
        overflowMinutes: Int = 0,
        phases: [SchedulePhase] = [],
        nodes: [ScheduleNode] = [],
        edges: [ScheduleEdge] = []
    ) {
        self.date = date
        self.wakeTime = wakeTime
        self.targetBedtime = targetBedtime
        self.projectedBedtime = projectedBedtime
        self.overflowMinutes = overflowMinutes
        self.phases = phases
        self.nodes = nodes
        self.edges = edges
    }
}

public struct AddStepPayload: Sendable {
    public let phaseId: SchedulePhaseId
    public let type: ScheduleNodeType
    public let title: String
    public let subtitle: String?
    public let totalMinutes: Int?
    public let timeSlot: String?
    public let iconName: String?

    public init(
        phaseId: SchedulePhaseId,
        type: ScheduleNodeType,
        title: String,
        subtitle: String? = nil,
        totalMinutes: Int? = nil,
        timeSlot: String? = nil,
        iconName: String? = nil
    ) {
        self.phaseId = phaseId
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.totalMinutes = totalMinutes
        self.timeSlot = timeSlot
        self.iconName = iconName
    }
}

public struct UpdateStepPayload: Sendable {
    public let title: String
    public let subtitle: String?
    public let phaseId: SchedulePhaseId?
    public let timeSlot: String?
    public let durationMinutes: Int?
    public let notes: String?
    public let iconName: String?
    public let date: String?

    public init(
        title: String,
        subtitle: String? = nil,
        phaseId: SchedulePhaseId? = nil,
        timeSlot: String? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        iconName: String? = nil,
        date: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.phaseId = phaseId
        self.timeSlot = timeSlot
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.iconName = iconName
        self.date = date
    }
}

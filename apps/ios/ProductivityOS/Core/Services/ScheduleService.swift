import Foundation

public protocol ScheduleServicing: Sendable {
    func loadSchedule(for date: Date) async throws -> ScheduleGraph
    func toggleHabit(habitId: UUID, for date: Date) async throws -> ToggleHabitResponse
    func addStep(_ payload: AddStepPayload, for date: Date) async throws -> ScheduleNode
    func updateStep(id: String, payload: UpdateStepPayload, for date: Date) async throws -> ScheduleNode
    func deleteStep(id: String) async throws
    func createDefaultBlueprint(for dateString: String) -> ScheduleGraph
}

public final class ScheduleService: ScheduleServicing {
    public static let shared = ScheduleService()

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private let apiClient: APIRequesting

    public init(apiClient: APIRequesting = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func loadSchedule(for date: Date) async throws -> ScheduleGraph {
        let dateString = Self.isoDateFormatter.string(from: date)

        do {
            let remoteGraph: ScheduleGraph = try await apiClient.request(AppEndpoint.getSchedule(date: dateString))
            return remoteGraph
        } catch let apiError as APIError {
            if case .unauthorized = apiError {
                throw apiError
            }
            return createDefaultBlueprint(for: dateString)
        } catch {
            return createDefaultBlueprint(for: dateString)
        }
    }

    public func toggleHabit(habitId: UUID, for date: Date) async throws -> ToggleHabitResponse {
        let dateString = Self.isoDateFormatter.string(from: date)
        let body = ToggleHabitRequestBody(date: dateString)
        let encoded = try APIClient.encodedBody(body)
        return try await apiClient.request(AppEndpoint.toggleHabit(id: habitId, body: encoded))
    }

    public func addStep(_ payload: AddStepPayload, for date: Date) async throws -> ScheduleNode {
        let dateString = Self.isoDateFormatter.string(from: date)
        let body = AddScheduleStepRequestBody(
            date: dateString,
            phase: payload.phaseId.rawValue,
            type: payload.type.rawValue,
            title: payload.title,
            subtitle: payload.subtitle,
            timeSlot: payload.timeSlot,
            durationMinutes: payload.totalMinutes,
            iconName: payload.iconName
        )
        let encoded = try APIClient.encodedBody(body)
        return try await apiClient.request(AppEndpoint.addScheduleStep(body: encoded))
    }

    public func updateStep(id: String, payload: UpdateStepPayload, for date: Date = Date()) async throws -> ScheduleNode {
        let dateString = payload.date ?? Self.isoDateFormatter.string(from: date)
        let body = UpdateScheduleStepRequestBody(
            title: payload.title,
            subtitle: payload.subtitle,
            phase: payload.phaseId?.rawValue,
            timeSlot: payload.timeSlot,
            durationMinutes: payload.durationMinutes,
            iconName: payload.iconName,
            notes: payload.notes,
            date: dateString
        )
        let encoded = try APIClient.encodedBody(body)
        return try await apiClient.request(AppEndpoint.updateScheduleStep(id: id, body: encoded))
    }

    public func deleteStep(id: String) async throws {
        _ = try await apiClient.send(AppEndpoint.deleteScheduleStep(id: id))
    }

    private static func generateHistory(streakDays: Int) -> [HabitStreakDay] {
        var days: [HabitStreakDay] = []
        let calendar = Calendar.current
        let today = Date()

        for i in (0..<14).reversed() {
            if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateStr = Self.isoDateFormatter.string(from: d)
                let completed = i < streakDays
                days.append(HabitStreakDay(date: dateStr, completed: completed))
            }
        }
        return days
    }

    public func createDefaultBlueprint(for dateString: String) -> ScheduleGraph {
        let phases: [SchedulePhase] = [
            SchedulePhase(
                id: .morning,
                title: SchedulePhaseId.morning.defaultTitle,
                subtitle: SchedulePhaseId.morning.defaultSubtitle,
                timeRange: SchedulePhaseId.morning.defaultTimeRange,
                colorTone: "warning"
            ),
            SchedulePhase(
                id: .deepFocus,
                title: SchedulePhaseId.deepFocus.defaultTitle,
                subtitle: SchedulePhaseId.deepFocus.defaultSubtitle,
                timeRange: SchedulePhaseId.deepFocus.defaultTimeRange,
                colorTone: "accent"
            ),
            SchedulePhase(
                id: .afternoon,
                title: SchedulePhaseId.afternoon.defaultTitle,
                subtitle: SchedulePhaseId.afternoon.defaultSubtitle,
                timeRange: SchedulePhaseId.afternoon.defaultTimeRange,
                colorTone: "blue"
            ),
            SchedulePhase(
                id: .bedtime,
                title: SchedulePhaseId.bedtime.defaultTitle,
                subtitle: SchedulePhaseId.bedtime.defaultSubtitle,
                timeRange: SchedulePhaseId.bedtime.defaultTimeRange,
                colorTone: "success"
            )
        ]

        let nodes: [ScheduleNode] = [
            // Morning Phase
            ScheduleNode(
                id: "anchor-wake",
                type: .anchor,
                phase: .morning,
                title: "Wake Up & Natural Sunlight",
                subtitle: "Anchor routine to reset circadian clock",
                time: "06:30",
                durationMinutes: 15,
                anchorKind: "wake",
                targetTime: "06:30",
                notes: "Get 10 minutes of direct sunlight outdoors within 30 minutes of waking.",
                order: 1
            ),
            ScheduleNode(
                id: "habit-hydration",
                type: .habit,
                phase: .morning,
                title: "500ml Mineral Water & Salts",
                subtitle: "Rehydrate brain and kickstart metabolism",
                time: "06:45",
                durationMinutes: 15,
                habitId: "habit-hydration",
                icon: "drop.fill",
                streak: 12,
                completed: true,
                frequency: "Daily · Morning Stack",
                history: Self.generateHistory(streakDays: 12),
                notes: "Filtered water with a pinch of Himalayan pink salt and lemon.",
                order: 2
            ),
            ScheduleNode(
                id: "habit-workout",
                type: .habit,
                phase: .morning,
                title: "Zone 2 Cardio & Mobility",
                subtitle: "Light jog or bodyweight mobility flow",
                time: "07:00",
                durationMinutes: 45,
                habitId: "habit-workout",
                icon: "figure.run",
                streak: 8,
                completed: true,
                frequency: "Daily · Morning Stack",
                history: Self.generateHistory(streakDays: 8),
                notes: "Elevate heart rate to 125-135 bpm for mitochondrial health.",
                order: 3
            ),
            ScheduleNode(
                id: "habit-cold-shower",
                type: .habit,
                phase: .morning,
                title: "Cold Rinse & Grooming",
                subtitle: "Dopamine surge and alertness spike",
                time: "07:45",
                durationMinutes: 15,
                habitId: "habit-cold-shower",
                icon: "shower.fill",
                streak: 5,
                completed: true,
                frequency: "Daily · Morning Stack",
                history: Self.generateHistory(streakDays: 5),
                notes: "2 minutes cold finish to boost norepinephrine.",
                order: 4
            ),
            ScheduleNode(
                id: "habit-planning",
                type: .habit,
                phase: .morning,
                title: "Daily Top 3 Planning & Intent",
                subtitle: "Review priorities and calibrate focus blocks",
                time: "08:15",
                durationMinutes: 30,
                habitId: "habit-planning",
                icon: "target",
                streak: 14,
                completed: true,
                frequency: "Daily · Morning Stack",
                history: Self.generateHistory(streakDays: 14),
                notes: "Lock in Daily Top 3 and silence notification channels.",
                order: 5
            ),

            // Deep Focus Phase
            ScheduleNode(
                id: "task-top1",
                type: .task,
                phase: .deepFocus,
                title: "Finish authentication architecture",
                subtitle: "Top 1 Priority · Core Security & JWT flow",
                time: "09:00",
                durationMinutes: 90,
                taskId: "task-01",
                priority: "HIGH",
                inFocus: false,
                completedMinutes: 0,
                totalMinutes: 90,
                projectName: "Productivity OS",
                notes: "Implement refresh tokens, user isolation tests, and session revocation.",
                order: 6
            ),
            ScheduleNode(
                id: "recharge-pause",
                type: .recharge,
                phase: .deepFocus,
                title: "Eye Rest & Hydration Walk",
                subtitle: "Disengage focus network and look at distance",
                time: "10:30",
                durationMinutes: 15,
                rechargeKind: "walk",
                notes: "Step away from screen. Look at horizon to relax ciliary eye muscles.",
                order: 7
            ),
            ScheduleNode(
                id: "task-top2",
                type: .task,
                phase: .deepFocus,
                title: "Build task dashboard layout",
                subtitle: "Top 2 Priority · Kanban & List hybrid",
                time: "10:45",
                durationMinutes: 75,
                taskId: "task-02",
                priority: "HIGH",
                inFocus: false,
                completedMinutes: 0,
                totalMinutes: 75,
                projectName: "Productivity OS",
                notes: "Desktop 1600px responsive grid with priority column drag-drop.",
                order: 8
            ),

            // Afternoon Phase
            ScheduleNode(
                id: "recharge-lunch",
                type: .recharge,
                phase: .afternoon,
                title: "Nutritious Lunch & Outdoor Walk",
                subtitle: "Balanced protein + low glycemic index carbs",
                time: "12:00",
                durationMinutes: 60,
                rechargeKind: "nutrition",
                notes: "Avoid heavy sugars to prevent post-lunch sluggishness.",
                order: 9
            ),
            ScheduleNode(
                id: "task-top3",
                type: .task,
                phase: .afternoon,
                title: "Review API implementation",
                subtitle: "Top 3 Priority · Verification & OpenAPI docs",
                time: "13:00",
                durationMinutes: 60,
                taskId: "task-03",
                priority: "MEDIUM",
                inFocus: false,
                completedMinutes: 0,
                totalMinutes: 60,
                projectName: "Productivity OS",
                notes: "Review error schemas, DTOs, and test coverage on PR #42.",
                order: 10
            ),
            ScheduleNode(
                id: "task-shallow",
                type: .task,
                phase: .afternoon,
                title: "Write documentation & Team Sync",
                subtitle: "Low cognitive load · Clean inbox & sync updates",
                time: "14:00",
                durationMinutes: 60,
                taskId: "task-05",
                priority: "LOW",
                inFocus: false,
                completedMinutes: 0,
                totalMinutes: 60,
                projectName: "Productivity OS",
                notes: "Update README architecture diagrams and respond to team RFC comments.",
                order: 11
            ),
            ScheduleNode(
                id: "habit-afternoon-walk",
                type: .habit,
                phase: .afternoon,
                title: "Afternoon Sunset Stride",
                subtitle: "Evening light cues to initiate melatonin onset",
                time: "16:00",
                durationMinutes: 30,
                habitId: "habit-afternoon-walk",
                icon: "figure.walk",
                streak: 4,
                completed: false,
                frequency: "Daily · Afternoon Stack",
                history: Self.generateHistory(streakDays: 4),
                notes: "20-30 min brisk walk outdoors during golden hour.",
                order: 12
            ),

            // Bedtime Sanctuary Phase
            ScheduleNode(
                id: "habit-curfew",
                type: .habit,
                phase: .bedtime,
                title: "Digital Screen Curfew",
                subtitle: "Turn off blue light displays and dock phone away from bed",
                time: "21:00",
                durationMinutes: 15,
                habitId: "habit-curfew",
                icon: "moon.fill",
                streak: 9,
                completed: false,
                frequency: "Daily · Bedtime Stack",
                history: Self.generateHistory(streakDays: 9),
                notes: "All screens off. Night lighting turned to warm amber dim mode.",
                order: 13
            ),
            ScheduleNode(
                id: "habit-journal",
                type: .habit,
                phase: .bedtime,
                title: "Evening Reflection & Fiction Reading",
                subtitle: "3 wins of the day, brain dump & analog paper book",
                time: "21:30",
                durationMinutes: 30,
                habitId: "habit-journal",
                icon: "book.fill",
                streak: 21,
                completed: false,
                frequency: "Daily · Bedtime Stack",
                history: Self.generateHistory(streakDays: 21),
                notes: "Write 3 wins in physical notebook, read 15-20 pages fiction.",
                order: 14
            ),
            ScheduleNode(
                id: "habit-winddown",
                type: .habit,
                phase: .bedtime,
                title: "Chamomile Tea & 4-7-8 Breathing",
                subtitle: "Down-regulate central nervous system",
                time: "22:00",
                durationMinutes: 15,
                habitId: "habit-winddown",
                icon: "cup.and.saucer.fill",
                streak: 11,
                completed: false,
                frequency: "Daily · Bedtime Stack",
                history: Self.generateHistory(streakDays: 11),
                notes: "Warm herbal tea, 5 minutes 4-7-8 parasympathetic breathing.",
                order: 15
            ),
            ScheduleNode(
                id: "anchor-bedtime",
                type: .anchor,
                phase: .bedtime,
                title: "Sleep Target & Bedtime Terminus",
                subtitle: "Target 22:30 · 8h Recovery Sleep Target",
                time: "22:30",
                durationMinutes: 480,
                anchorKind: "bedtime",
                targetTime: "22:30",
                projectedTime: "23:15",
                overflowMinutes: 45,
                notes: "Room temperature 18°C, total blackout, earplugs ready.",
                order: 16
            )
        ]

        let edges: [ScheduleEdge] = [
            // Morning Stack
            ScheduleEdge(id: "e-wake-hydro", fromNodeId: "anchor-wake", toNodeId: "habit-hydration", type: .sequential, active: true),
            ScheduleEdge(id: "e-hydro-workout", fromNodeId: "habit-hydration", toNodeId: "habit-workout", type: .prerequisite, active: true),
            ScheduleEdge(id: "e-workout-shower", fromNodeId: "habit-workout", toNodeId: "habit-cold-shower", type: .prerequisite, active: true),
            ScheduleEdge(id: "e-shower-plan", fromNodeId: "habit-cold-shower", toNodeId: "habit-planning", type: .prerequisite, active: true),
            ScheduleEdge(id: "e-plan-top1", fromNodeId: "habit-planning", toNodeId: "task-top1", type: .phase, active: true),

            // Deep Focus
            ScheduleEdge(id: "e-top1-pause", fromNodeId: "task-top1", toNodeId: "recharge-pause", type: .sequential, active: false),
            ScheduleEdge(id: "e-pause-top2", fromNodeId: "recharge-pause", toNodeId: "task-top2", type: .sequential, active: false),
            ScheduleEdge(id: "e-top2-lunch", fromNodeId: "task-top2", toNodeId: "recharge-lunch", type: .phase, active: false),

            // Afternoon Momentum
            ScheduleEdge(id: "e-lunch-top3", fromNodeId: "recharge-lunch", toNodeId: "task-top3", type: .sequential, active: false),
            ScheduleEdge(id: "e-top3-shallow", fromNodeId: "task-top3", toNodeId: "task-shallow", type: .sequential, active: false),
            ScheduleEdge(id: "e-shallow-walk", fromNodeId: "task-shallow", toNodeId: "habit-afternoon-walk", type: .prerequisite, active: false),
            ScheduleEdge(id: "e-walk-curfew", fromNodeId: "habit-afternoon-walk", toNodeId: "habit-curfew", type: .phase, active: false),

            // Bedtime Sanctuary
            ScheduleEdge(id: "e-curfew-journal", fromNodeId: "habit-curfew", toNodeId: "habit-journal", type: .prerequisite, active: false),
            ScheduleEdge(id: "e-journal-tea", fromNodeId: "habit-journal", toNodeId: "habit-winddown", type: .prerequisite, active: false),
            ScheduleEdge(id: "e-tea-bed", fromNodeId: "habit-winddown", toNodeId: "anchor-bedtime", type: .sequential, active: false)
        ]

        let initialCalc = BedtimeCalculator.calculate(targetBedtime: "22:30", nodes: nodes)

        return ScheduleGraph(
            date: dateString,
            wakeTime: "06:30",
            targetBedtime: "22:30",
            projectedBedtime: initialCalc.projectedBedtime,
            overflowMinutes: initialCalc.overflowMinutes,
            phases: phases,
            nodes: nodes,
            edges: edges
        )
    }
}

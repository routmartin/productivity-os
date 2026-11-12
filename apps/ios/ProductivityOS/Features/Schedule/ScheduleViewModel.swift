import Foundation
import Observation

@Observable
public final class ScheduleViewModel {
    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private static let storageKey = "productivity-os:schedule-layout"

    public private(set) var loadState: LoadState = .idle
    public private(set) var graph: ScheduleGraph?
    public private(set) var activeLayout: ScheduleLayoutMode = .spine
    public var selectedNodeId: String?
    public private(set) var activeTaskId: String?

    private let scheduleService: ScheduleServicing

    public init(
        scheduleService: ScheduleServicing = ScheduleService.shared,
        initialGraph: ScheduleGraph? = nil
    ) {
        self.scheduleService = scheduleService
        if let initialGraph {
            self.graph = initialGraph
            self.loadState = .loaded
        }
        self.activeLayout = Self.loadSavedLayout()
    }

    private static func loadSavedLayout() -> ScheduleLayoutMode {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let mode = ScheduleLayoutMode(rawValue: raw) {
            return mode
        }
        return .spine
    }

    // MARK: - Getters

    public var nodes: [ScheduleNode] {
        graph?.nodes ?? []
    }

    public var edges: [ScheduleEdge] {
        graph?.edges ?? []
    }

    public var phases: [SchedulePhase] {
        graph?.phases ?? []
    }

    public var selectedNode: ScheduleNode? {
        guard let id = selectedNodeId else { return nil }
        return nodes.first { $0.id == id }
    }

    public var habitNodes: [ScheduleNode] {
        nodes.filter { $0.type == .habit }
    }

    public var taskNodes: [ScheduleNode] {
        nodes.filter { $0.type == .task }
    }

    public var completedHabitsCount: Int {
        habitNodes.filter { $0.completed ?? false }.count
    }

    public var totalHabitsCount: Int {
        habitNodes.count
    }

    public var habitProgressPercent: Int {
        guard totalHabitsCount > 0 else { return 0 }
        return Int((Double(completedHabitsCount) / Double(totalHabitsCount)) * 100)
    }

    public var wakeAnchor: ScheduleNode? {
        nodes.first { $0.type == .anchor && $0.anchorKind == "wake" }
    }

    public var bedtimeAnchor: ScheduleNode? {
        nodes.first { $0.type == .anchor && $0.anchorKind == "bedtime" }
    }

    public var overflowMinutes: Int {
        graph?.overflowMinutes ?? 0
    }

    public var isOverflowing: Bool {
        overflowMinutes > 0
    }

    public var projectedBedtime: String {
        graph?.projectedBedtime ?? "22:30"
    }

    public var targetBedtime: String {
        graph?.targetBedtime ?? "22:30"
    }

    public var bedtimeStatusMessage: String {
        if isOverflowing {
            return "Schedule overflow: Bedtime shifts by \(overflowMinutes)m"
        }
        return "On track for \(targetBedtime) bedtime"
    }

    // MARK: - Actions

    public func loadData(date: Date = Date()) async {
        loadState = .loading
        do {
            let loadedGraph = try await scheduleService.loadSchedule(for: date)
            self.graph = loadedGraph
            self.loadState = .loaded
            recalculateBedtime()
        } catch {
            self.loadState = .failed(error.localizedDescription)
        }
    }

    public func setLayout(_ mode: ScheduleLayoutMode) {
        activeLayout = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
    }

    public func selectNode(_ nodeId: String?) {
        selectedNodeId = nodeId
    }

    // Spec AC-002 & AC-005: Habit Stacking and Edge Illumination
    public func toggleHabit(_ nodeIdOrHabitId: String) {
        guard var g = graph else { return }
        guard let index = g.nodes.firstIndex(where: {
            $0.id == nodeIdOrHabitId || $0.habitId == nodeIdOrHabitId
        }) else { return }

        guard g.nodes[index].type == .habit else { return }

        let nextCompleted = !(g.nodes[index].completed ?? false)
        g.nodes[index].completed = nextCompleted

        let currentStreak = g.nodes[index].streak ?? 0
        g.nodes[index].streak = nextCompleted ? currentStreak + 1 : max(0, currentStreak - 1)

        if var history = g.nodes[index].history, !history.isEmpty {
            history[history.count - 1].completed = nextCompleted
            g.nodes[index].history = history
        }

        let habitId = g.nodes[index].id
        for edgeIdx in 0..<g.edges.count {
            if g.edges[edgeIdx].fromNodeId == habitId {
                g.edges[edgeIdx].active = nextCompleted
            }
        }

        self.graph = g
        recalculateBedtime()
    }

    // Spec AC-003: Native Activity Execution State
    public func startFocus(_ nodeIdOrTaskId: String) {
        guard var g = graph else { return }
        for i in 0..<g.nodes.count {
            if g.nodes[i].type == .task {
                g.nodes[i].inFocus = (g.nodes[i].id == nodeIdOrTaskId || g.nodes[i].taskId == nodeIdOrTaskId)
            }
        }
        activeTaskId = nodeIdOrTaskId
        self.graph = g
    }

    public func stopFocus() {
        guard var g = graph else { return }
        for i in 0..<g.nodes.count {
            if g.nodes[i].type == .task {
                g.nodes[i].inFocus = false
            }
        }
        activeTaskId = nil
        self.graph = g
    }

    // Spec AC-007: In-Line Step Creation
    @discardableResult
    public func addStep(_ payload: AddStepPayload) -> ScheduleNode? {
        guard var g = graph else {
            let blueprint = scheduleService.createDefaultBlueprint(for: "today")
            self.graph = blueprint
            return addStep(payload)
        }

        let id = "node-\(Int(Date().timeIntervalSince1970 * 1000))"
        let duration = payload.totalMinutes ?? (payload.type == .habit ? 15 : payload.type == .recharge ? 15 : 60)

        var newNode = ScheduleNode(
            id: id,
            type: payload.type,
            phase: payload.phaseId,
            title: payload.title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: payload.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines),
            time: payload.timeSlot?.trimmingCharacters(in: .whitespacesAndNewlines),
            durationMinutes: duration,
            order: g.nodes.count + 1
        )

        if payload.type == .habit {
            newNode.habitId = id
            newNode.icon = payload.iconName ?? "drop.fill"
            newNode.streak = 1
            newNode.completed = false
            newNode.frequency = "Daily"
            newNode.history = [HabitStreakDay(date: "today", completed: false)]
        } else if payload.type == .task {
            newNode.taskId = "task-\(Int(Date().timeIntervalSince1970 * 1000))"
            newNode.priority = "MEDIUM"
            newNode.inFocus = false
            newNode.completedMinutes = 0
            newNode.totalMinutes = duration
            newNode.projectName = "Personal OS"
        } else if payload.type == .recharge {
            newNode.rechargeKind = "break"
        }

        var insertIndex = g.nodes.count
        if payload.phaseId == .bedtime {
            if let bedtimeIdx = g.nodes.firstIndex(where: { $0.type == .anchor && $0.anchorKind == "bedtime" }) {
                insertIndex = bedtimeIdx
            }
        } else {
            var lastPhaseIdx = -1
            for (idx, node) in g.nodes.enumerated() {
                if node.phase == payload.phaseId {
                    lastPhaseIdx = idx
                }
            }
            if lastPhaseIdx != -1 {
                insertIndex = lastPhaseIdx + 1
            } else {
                let phaseOrder: [SchedulePhaseId] = [.morning, .deepFocus, .afternoon, .bedtime]
                let currentTargetOrder = phaseOrder.firstIndex(of: payload.phaseId) ?? 0
                if let nextPhaseNodeIdx = g.nodes.firstIndex(where: {
                    (phaseOrder.firstIndex(of: $0.phase) ?? 0) > currentTargetOrder
                }) {
                    insertIndex = nextPhaseNodeIdx
                }
            }
        }

        let prevNode = insertIndex > 0 ? g.nodes[insertIndex - 1] : nil
        let nextNode = insertIndex < g.nodes.count ? g.nodes[insertIndex] : nil

        g.nodes.insert(newNode, at: insertIndex)

        // Re-wire edges cleanly
        if let prev = prevNode, let next = nextNode {
            if let existingIdx = g.edges.firstIndex(where: { $0.fromNodeId == prev.id && $0.toNodeId == next.id }) {
                let oldType = g.edges[existingIdx].type
                g.edges.remove(at: existingIdx)
                g.edges.append(ScheduleEdge(
                    id: "e-\(prev.id)-\(newNode.id)",
                    fromNodeId: prev.id,
                    toNodeId: newNode.id,
                    type: oldType,
                    active: prev.completed ?? false
                ))
                g.edges.append(ScheduleEdge(
                    id: "e-\(newNode.id)-\(next.id)",
                    fromNodeId: newNode.id,
                    toNodeId: next.id,
                    type: oldType,
                    active: false
                ))
            } else {
                g.edges.append(ScheduleEdge(
                    id: "e-\(prev.id)-\(newNode.id)",
                    fromNodeId: prev.id,
                    toNodeId: newNode.id,
                    type: .sequential,
                    active: prev.completed ?? false
                ))
                if next.type == .anchor && next.anchorKind == "bedtime" {
                    g.edges.append(ScheduleEdge(
                        id: "e-\(newNode.id)-\(next.id)",
                        fromNodeId: newNode.id,
                        toNodeId: next.id,
                        type: .sequential,
                        active: false
                    ))
                }
            }
        } else if let prev = prevNode {
            g.edges.append(ScheduleEdge(
                id: "e-\(prev.id)-\(newNode.id)",
                fromNodeId: prev.id,
                toNodeId: newNode.id,
                type: .sequential,
                active: prev.completed ?? false
            ))
        }

        self.graph = g
        recalculateBedtime()
        return newNode
    }

    // Spec AC-008: Node Deletion from Schedule
    public func deleteNode(_ nodeId: String) {
        guard var g = graph else { return }
        guard let nodeIndex = g.nodes.firstIndex(where: { $0.id == nodeId }) else { return }

        let nodeToDelete = g.nodes[nodeIndex]
        guard nodeToDelete.type != .anchor else { return } // Anchors are permanent

        let incomingEdges = g.edges.filter { $0.toNodeId == nodeId }
        let outgoingEdges = g.edges.filter { $0.fromNodeId == nodeId }

        g.edges.removeAll { $0.fromNodeId == nodeId || $0.toNodeId == nodeId }

        // Re-bridge edge if both incoming and outgoing exist
        if let firstIn = incomingEdges.first, let firstOut = outgoingEdges.first {
            let fromId = firstIn.fromNodeId
            let toId = firstOut.toNodeId
            let alreadyConnected = g.edges.contains { $0.fromNodeId == fromId && $0.toNodeId == toId }
            if fromId != toId && !alreadyConnected {
                let fromNode = g.nodes.first { $0.id == fromId }
                g.edges.append(ScheduleEdge(
                    id: "e-\(fromId)-\(toId)",
                    fromNodeId: fromId,
                    toNodeId: toId,
                    type: firstIn.type ?? .sequential,
                    active: fromNode?.completed ?? false
                ))
            }
        }

        g.nodes.remove(at: nodeIndex)

        if selectedNodeId == nodeId {
            selectedNodeId = nil
        }

        self.graph = g
        recalculateBedtime()
    }

    public func recalculateBedtime() {
        guard var g = graph else { return }
        let result = BedtimeCalculator.calculate(targetBedtime: g.targetBedtime, nodes: g.nodes)
        g.overflowMinutes = result.overflowMinutes
        g.projectedBedtime = result.projectedBedtime

        if let bedtimeIdx = g.nodes.firstIndex(where: { $0.type == .anchor && $0.anchorKind == "bedtime" }) {
            g.nodes[bedtimeIdx].overflowMinutes = result.overflowMinutes
            g.nodes[bedtimeIdx].projectedTime = result.projectedBedtime
        }

        self.graph = g
    }
}

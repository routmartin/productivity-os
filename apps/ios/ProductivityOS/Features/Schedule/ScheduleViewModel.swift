import Foundation
import Observation

@Observable
@MainActor
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
    public var errorMessage: String?
    public private(set) var currentDate: Date = Date()

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
        currentDate = date
        loadState = .loading
        errorMessage = nil
        do {
            let loadedGraph = try await scheduleService.loadSchedule(for: date)
            self.graph = loadedGraph
            self.loadState = .loaded
            recalculateBedtime()
        } catch {
            self.loadState = .failed(error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }

    public func setLayout(_ mode: ScheduleLayoutMode) {
        activeLayout = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
    }

    public func selectNode(_ nodeId: String?) {
        selectedNodeId = nodeId
    }

    // Spec AC-002 & AC-005: Habit Stacking and Edge Illumination (AC-C07: Optimistic update with server sync & rollback)
    public func toggleHabit(_ nodeIdOrHabitId: String) {
        guard var g = graph else { return }
        guard let index = g.nodes.firstIndex(where: {
            $0.id == nodeIdOrHabitId || $0.habitId == nodeIdOrHabitId
        }) else { return }

        guard g.nodes[index].type == .habit else { return }

        let snapshot = g
        errorMessage = nil

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

        let targetUUID = (g.nodes[index].habitId.flatMap { UUID(uuidString: $0) })
            ?? UUID(uuidString: g.nodes[index].id)
            ?? UUID(uuidString: nodeIdOrHabitId)

        if let uuid = targetUUID {
            Task { [weak self, currentDate] in
                guard let self else { return }
                do {
                    let response = try await self.scheduleService.toggleHabit(habitId: uuid, for: currentDate)
                    self.reconcileHabit(response)
                } catch {
                    self.graph = snapshot
                    self.recalculateBedtime()
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func reconcileHabit(_ response: ToggleHabitResponse) {
        guard var g = graph else { return }
        let uuidStr = response.habitId.uuidString.lowercased()
        guard let index = g.nodes.firstIndex(where: {
            $0.id.lowercased() == uuidStr || $0.habitId?.lowercased() == uuidStr
        }) else { return }

        g.nodes[index].completed = response.completed
        g.nodes[index].streak = response.streak
        g.nodes[index].history = response.history

        // Update edges from server
        for updatedEdge in response.updatedEdges {
            if let edgeIdx = g.edges.firstIndex(where: { $0.id == updatedEdge.id }) {
                g.edges[edgeIdx] = updatedEdge
            } else if let edgeIdx = g.edges.firstIndex(where: {
                $0.fromNodeId == updatedEdge.fromNodeId && $0.toNodeId == updatedEdge.toNodeId
            }) {
                g.edges[edgeIdx].active = updatedEdge.active
            }
        }

        g.projectedBedtime = response.projectedBedtime
        g.overflowMinutes = response.overflowMinutes

        if let bedtimeIdx = g.nodes.firstIndex(where: { $0.type == .anchor && $0.anchorKind == "bedtime" }) {
            g.nodes[bedtimeIdx].overflowMinutes = response.overflowMinutes
            g.nodes[bedtimeIdx].projectedTime = response.projectedBedtime
        }

        self.graph = g
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

    // Spec AC-007 / AC-C08: In-Line Step Creation
    @discardableResult
    public func addStep(_ payload: AddStepPayload) async -> ScheduleNode? {
        if graph == nil {
            let blueprint = scheduleService.createDefaultBlueprint(for: "today")
            self.graph = blueprint
        }
        do {
            let serverNode = try await scheduleService.addStep(payload, for: currentDate)
            return insertNodeAndRewire(serverNode, phaseId: payload.phaseId)
        } catch {
            errorMessage = error.localizedDescription
            let localNode = createLocalNode(for: payload)
            return insertNodeAndRewire(localNode, phaseId: payload.phaseId)
        }
    }

    @discardableResult
    public func addStepSync(_ payload: AddStepPayload) -> ScheduleNode? {
        if graph == nil {
            let blueprint = scheduleService.createDefaultBlueprint(for: "today")
            self.graph = blueprint
        }
        let localNode = createLocalNode(for: payload)
        let inserted = insertNodeAndRewire(localNode, phaseId: payload.phaseId)
        Task { [weak self, currentDate] in
            guard let self else { return }
            if let serverNode = try? await self.scheduleService.addStep(payload, for: currentDate) {
                self.reconcileCreatedNode(tempId: localNode.id, serverNode: serverNode)
            }
        }
        return inserted
    }

    @discardableResult
    public func addStep(_ payload: AddStepPayload) -> ScheduleNode? {
        addStepSync(payload)
    }

    private func reconcileCreatedNode(tempId: String, serverNode: ScheduleNode) {
        guard var g = graph else { return }
        guard let idx = g.nodes.firstIndex(where: { $0.id == tempId }) else { return }
        g.nodes[idx] = serverNode
        for i in 0..<g.edges.count {
            let edge = g.edges[i]
            let newFrom = edge.fromNodeId == tempId ? serverNode.id : edge.fromNodeId
            let newTo = edge.toNodeId == tempId ? serverNode.id : edge.toNodeId
            if newFrom != edge.fromNodeId || newTo != edge.toNodeId {
                g.edges[i] = ScheduleEdge(
                    id: "e-\(newFrom)-\(newTo)",
                    fromNodeId: newFrom,
                    toNodeId: newTo,
                    type: edge.type,
                    active: edge.active
                )
            }
        }
        self.graph = g
    }

    private func createLocalNode(for payload: AddStepPayload) -> ScheduleNode {
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
            order: (graph?.nodes.count ?? 0) + 1
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
        return newNode
    }

    @discardableResult
    private func insertNodeAndRewire(_ newNode: ScheduleNode, phaseId: SchedulePhaseId) -> ScheduleNode {
        guard var g = graph else {
            return newNode
        }

        var insertIndex = g.nodes.count
        if phaseId == .bedtime {
            if let bedtimeIdx = g.nodes.firstIndex(where: { $0.type == .anchor && $0.anchorKind == "bedtime" }) {
                insertIndex = bedtimeIdx
            }
        } else {
            var lastPhaseIdx = -1
            for (idx, node) in g.nodes.enumerated() {
                if node.phase == phaseId {
                    lastPhaseIdx = idx
                }
            }
            if lastPhaseIdx != -1 {
                insertIndex = lastPhaseIdx + 1
            } else {
                let phaseOrder: [SchedulePhaseId] = [.morning, .deepFocus, .afternoon, .bedtime]
                let currentTargetOrder = phaseOrder.firstIndex(of: phaseId) ?? 0
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

    // Spec AC-010, AC-011, AC-012: Step Details Update, Anchor Protection & Topological Rewiring
    @discardableResult
    public func updateStep(id: String, payload: UpdateStepPayload) async throws -> ScheduleNode {
        guard !id.hasPrefix("anchor-") else {
            let error = APIError.serverError(statusCode: 400, code: "ANCHOR_UPDATE_NOT_ALLOWED", message: "Anchor node update is not allowed")
            self.errorMessage = error.localizedDescription
            throw error
        }
        guard var g = graph else {
            let error = APIError.serverError(statusCode: 400, code: "NO_SCHEDULE", message: "No schedule loaded")
            self.errorMessage = error.localizedDescription
            throw error
        }
        guard let nodeIndex = g.nodes.firstIndex(where: { $0.id == id }) else {
            let error = APIError.notFound
            self.errorMessage = error.localizedDescription
            throw error
        }

        let existingNode = g.nodes[nodeIndex]
        guard existingNode.type != .anchor && existingNode.anchorKind == nil else {
            let error = APIError.serverError(statusCode: 400, code: "ANCHOR_UPDATE_NOT_ALLOWED", message: "Anchor node update is not allowed")
            self.errorMessage = error.localizedDescription
            throw error
        }

        let snapshot = g
        errorMessage = nil

        var updatedNode = existingNode
        updatedNode.title = payload.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let subtitle = payload.subtitle {
            updatedNode.subtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let timeSlot = payload.timeSlot {
            let trimmed = timeSlot.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedNode.time = trimmed
            if updatedNode.type == .habit {
                updatedNode.targetTime = trimmed
            }
        }
        if let duration = payload.durationMinutes {
            updatedNode.durationMinutes = duration
            if updatedNode.type == .task {
                updatedNode.totalMinutes = duration
            }
        }
        if let notes = payload.notes {
            updatedNode.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let icon = payload.iconName, updatedNode.type == .habit {
            updatedNode.icon = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let oldPhase = existingNode.phase
        let newPhase = payload.phaseId ?? oldPhase
        let phaseChanged = (newPhase != oldPhase)
        updatedNode.phase = newPhase

        g.nodes[nodeIndex] = updatedNode
        self.graph = g

        if phaseChanged {
            rewireEdges()
        } else {
            recalculateBedtime()
        }

        do {
            let serverNode = try await scheduleService.updateStep(id: id, payload: payload, for: currentDate)
            if var currentGraph = self.graph, let currentIdx = currentGraph.nodes.firstIndex(where: { $0.id == id }) {
                currentGraph.nodes[currentIdx].title = serverNode.title
                if let sub = serverNode.subtitle { currentGraph.nodes[currentIdx].subtitle = sub }
                if let tm = serverNode.time { currentGraph.nodes[currentIdx].time = tm }
                if let dur = serverNode.durationMinutes {
                    currentGraph.nodes[currentIdx].durationMinutes = dur
                    if currentGraph.nodes[currentIdx].type == .task {
                        currentGraph.nodes[currentIdx].totalMinutes = dur
                    }
                }
                if let n = serverNode.notes { currentGraph.nodes[currentIdx].notes = n }
                if let ic = serverNode.icon { currentGraph.nodes[currentIdx].icon = ic }
                self.graph = currentGraph
            }
            return serverNode
        } catch {
            self.graph = snapshot
            recalculateBedtime()
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    public func updateStepSync(id: String, payload: UpdateStepPayload) {
        Task {
            _ = try? await self.updateStep(id: id, payload: payload)
        }
    }

    public func rewireEdges() {
        guard var g = graph, g.nodes.count > 1 else { return }

        let phaseOrder: [SchedulePhaseId: Int] = [
            .morning: 0,
            .deepFocus: 1,
            .afternoon: 2,
            .bedtime: 3
        ]

        var sortedNodes: [ScheduleNode] = []
        let wakeAnchor = g.nodes.first { $0.type == .anchor && $0.anchorKind == "wake" }
        let bedtimeAnchor = g.nodes.first { $0.type == .anchor && $0.anchorKind == "bedtime" }

        if let wake = wakeAnchor {
            sortedNodes.append(wake)
        }

        let nonAnchors = g.nodes.filter { node in
            !(node.type == .anchor && (node.anchorKind == "wake" || node.anchorKind == "bedtime"))
        }

        let sortedNonAnchors = nonAnchors.sorted { a, b in
            let aPhaseOrder = phaseOrder[a.phase] ?? 0
            let bPhaseOrder = phaseOrder[b.phase] ?? 0
            if aPhaseOrder != bPhaseOrder {
                return aPhaseOrder < bPhaseOrder
            }
            return (a.order ?? 0) < (b.order ?? 0)
        }
        sortedNodes.append(contentsOf: sortedNonAnchors)

        if let bedtime = bedtimeAnchor {
            sortedNodes.append(bedtime)
        }

        for i in 0..<sortedNodes.count {
            sortedNodes[i].order = i + 1
        }

        var newEdges: [ScheduleEdge] = []
        for i in 0..<(sortedNodes.count - 1) {
            let from = sortedNodes[i]
            let to = sortedNodes[i + 1]
            let existingEdge = g.edges.first { $0.fromNodeId == from.id && $0.toNodeId == to.id }

            let edgeType: ScheduleEdgeType
            if from.phase != to.phase {
                edgeType = .phase
            } else if let existingType = existingEdge?.type {
                edgeType = existingType
            } else if from.type == .habit && to.type == .habit {
                edgeType = .prerequisite
            } else {
                edgeType = .sequential
            }

            let isActive = existingEdge?.active ?? (from.completed ?? false)

            newEdges.append(
                ScheduleEdge(
                    id: "e-\(from.id)-\(to.id)",
                    fromNodeId: from.id,
                    toNodeId: to.id,
                    type: edgeType,
                    active: isActive
                )
            )
        }

        g.nodes = sortedNodes
        g.edges = newEdges
        self.graph = g
        recalculateBedtime()
    }

    // Spec AC-008 / AC-C08: Node Deletion from Schedule with Anchor Protection & API Sync
    public func deleteNode(_ nodeId: String) {
        guard !nodeId.hasPrefix("anchor-") else { return }
        guard var g = graph else { return }
        guard let nodeIndex = g.nodes.firstIndex(where: { $0.id == nodeId }) else { return }

        let nodeToDelete = g.nodes[nodeIndex]
        guard nodeToDelete.type != .anchor, nodeToDelete.anchorKind == nil else { return } // Anchors are permanent

        let snapshot = g
        errorMessage = nil

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

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.scheduleService.deleteStep(id: nodeId)
            } catch {
                self.graph = snapshot
                self.recalculateBedtime()
                self.errorMessage = error.localizedDescription
            }
        }
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

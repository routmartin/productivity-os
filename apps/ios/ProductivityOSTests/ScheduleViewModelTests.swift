import Foundation
import XCTest
@testable import ProductivityOS

@MainActor
final class ScheduleViewModelTests: XCTestCase {
    private var mockAPIClient: MockAPIClient!
    private var scheduleService: ScheduleService!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "productivity-os:schedule-layout")
        mockAPIClient = MockAPIClient()
        // Default to network error so loadSchedule falls back gracefully to default blueprint
        mockAPIClient.defaultResponse = .failure(APIError.networkError("The Internet connection appears to be offline."))
        scheduleService = ScheduleService(apiClient: mockAPIClient)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "productivity-os:schedule-layout")
        super.tearDown()
    }

    private func makeViewModel(initialGraph: ScheduleGraph? = nil) -> ScheduleViewModel {
        ScheduleViewModel(scheduleService: scheduleService, initialGraph: initialGraph)
    }

    func testDailyBlueprintPrePopulation() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        XCTAssertEqual(viewModel.phases.count, 4)
        XCTAssertEqual(viewModel.nodes.count, 16)
        XCTAssertEqual(viewModel.edges.count, 15)

        // Circadian Anchors exist
        XCTAssertNotNil(viewModel.wakeAnchor)
        XCTAssertNotNil(viewModel.bedtimeAnchor)
        XCTAssertEqual(viewModel.wakeAnchor?.time, "06:30")
        XCTAssertEqual(viewModel.bedtimeAnchor?.targetTime, "22:30")
    }

    func testDefaultLayoutIsJourney() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.activeLayout, .journey)
    }

    func testLayoutSwitchingAndPersistence() {
        let viewModel = makeViewModel()

        viewModel.setLayout(.journey)
        XCTAssertEqual(viewModel.activeLayout, .journey)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "productivity-os:schedule-layout"), "journey")

        viewModel.setLayout(.matrix)
        XCTAssertEqual(viewModel.activeLayout, .matrix)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "productivity-os:schedule-layout"), "matrix")

        viewModel.setLayout(.spine)
        XCTAssertEqual(viewModel.activeLayout, .spine)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "productivity-os:schedule-layout"), "spine")
    }

    func testHabitToggleUpdatesStreakAndOutgoingEdges() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        // Find an incomplete habit: habit-afternoon-walk
        guard let habit = viewModel.nodes.first(where: { $0.id == "habit-afternoon-walk" }) else {
            XCTFail("Habit not found")
            return
        }

        XCTAssertFalse(habit.completed ?? false)
        let initialStreak = habit.streak ?? 0

        // Toggle to completed
        viewModel.toggleHabit("habit-afternoon-walk")

        let updatedHabit = viewModel.nodes.first(where: { $0.id == "habit-afternoon-walk" })
        XCTAssertTrue(updatedHabit?.completed ?? false)
        XCTAssertEqual(updatedHabit?.streak, initialStreak + 1)

        // Outgoing edge e-walk-curfew should be active
        let outgoingEdge = viewModel.edges.first(where: { $0.fromNodeId == "habit-afternoon-walk" })
        XCTAssertEqual(outgoingEdge?.active, true)

        // Toggle back to incomplete
        viewModel.toggleHabit("habit-afternoon-walk")
        let revertedHabit = viewModel.nodes.first(where: { $0.id == "habit-afternoon-walk" })
        XCTAssertFalse(revertedHabit?.completed ?? true)
        XCTAssertEqual(revertedHabit?.streak, initialStreak)
        let revertedEdge = viewModel.edges.first(where: { $0.fromNodeId == "habit-afternoon-walk" })
        XCTAssertEqual(revertedEdge?.active, false)
    }

    // MARK: - AC-C07: Optimistic Habit Toggle and Server Rollback

    func testOptimisticHabitToggleAndRollbackOnFailure() async throws {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.serverError(statusCode: 500, code: "INTERNAL_ERROR", message: "Database connection failed"))
        ]

        let habitUUID = UUID()
        let habitNode = ScheduleNode(
            id: habitUUID.uuidString,
            type: .habit,
            phase: .morning,
            title: "Hydration",
            streak: 5,
            completed: false,
            order: 2
        )
        let edge = ScheduleEdge(
            id: "e-h-next",
            fromNodeId: habitUUID.uuidString,
            toNodeId: "node-next",
            type: .sequential,
            active: false
        )
        let initialGraph = ScheduleGraph(
            date: "2026-11-12",
            targetBedtime: "22:30",
            phases: [SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: "")],
            nodes: [habitNode],
            edges: [edge]
        )

        let viewModel = makeViewModel(initialGraph: initialGraph)

        // Step 1: Trigger toggle
        viewModel.toggleHabit(habitUUID.uuidString)

        // Step 2: Verify immediate optimistic update (<16ms)
        let optHabit = viewModel.nodes.first { $0.id == habitUUID.uuidString }
        XCTAssertEqual(optHabit?.completed, true)
        XCTAssertEqual(optHabit?.streak, 6)
        XCTAssertEqual(viewModel.edges.first { $0.id == "e-h-next" }?.active, true)

        // Step 3: Wait for background sync Task to encounter simulated 500 error
        try await Task.sleep(nanoseconds: 100_000_000)

        // Step 4: Verify rollback to pre-mutation snapshot
        let rolledBackHabit = viewModel.nodes.first { $0.id == habitUUID.uuidString }
        XCTAssertEqual(rolledBackHabit?.completed, false)
        XCTAssertEqual(rolledBackHabit?.streak, 5)
        XCTAssertEqual(viewModel.edges.first { $0.id == "e-h-next" }?.active, false)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testHabitToggleReconcilesWithServerResponse() async throws {
        let habitUUID = UUID()
        let responseJSON = """
        {
            "habitId": "\(habitUUID.uuidString)",
            "completed": true,
            "streak": 25,
            "history": [
                { "date": "2026-11-12", "completed": true }
            ],
            "updatedEdges": [
                {
                    "id": "e-h-next",
                    "fromNodeId": "\(habitUUID.uuidString)",
                    "toNodeId": "node-next",
                    "type": "sequential",
                    "active": true
                }
            ],
            "projectedBedtime": "22:30",
            "overflowMinutes": 0
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(responseJSON.utf8), 200))
        ]

        let habitNode = ScheduleNode(
            id: habitUUID.uuidString,
            type: .habit,
            phase: .morning,
            title: "Hydration",
            streak: 5,
            completed: false,
            order: 2
        )
        let edge = ScheduleEdge(
            id: "e-h-next",
            fromNodeId: habitUUID.uuidString,
            toNodeId: "node-next",
            type: .sequential,
            active: false
        )
        let initialGraph = ScheduleGraph(
            date: "2026-11-12",
            targetBedtime: "22:30",
            phases: [SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: "")],
            nodes: [habitNode],
            edges: [edge]
        )

        let viewModel = makeViewModel(initialGraph: initialGraph)

        viewModel.toggleHabit(habitUUID.uuidString)

        // Wait for background reconciliation
        try await Task.sleep(nanoseconds: 100_000_000)

        let reconciled = viewModel.nodes.first { $0.id == habitUUID.uuidString }
        XCTAssertEqual(reconciled?.completed, true)
        XCTAssertEqual(reconciled?.streak, 25) // Server authoritative streak
        XCTAssertEqual(reconciled?.history?.count, 1)
        XCTAssertEqual(viewModel.edges.first { $0.id == "e-h-next" }?.active, true)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testNativeActivityFocusToggle() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        // Start focus on task-top1
        viewModel.startFocus("task-top1")
        XCTAssertEqual(viewModel.activeTaskId, "task-top1")
        let top1Node = viewModel.nodes.first(where: { $0.id == "task-top1" })
        XCTAssertTrue(top1Node?.inFocus ?? false)

        // Stop focus
        viewModel.stopFocus()
        XCTAssertNil(viewModel.activeTaskId)
        let stoppedNode = viewModel.nodes.first(where: { $0.id == "task-top1" })
        XCTAssertFalse(stoppedNode?.inFocus ?? true)
    }

    func testAddStepWiresEdgesAndUpdatesBedtime() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        let initialNodeCount = viewModel.nodes.count

        let payload = AddStepPayload(
            phaseId: .morning,
            type: .habit,
            title: "Morning Sunlight Reading",
            subtitle: "10 mins outdoor reading",
            totalMinutes: 15,
            iconName: "book.fill"
        )

        let createdNode = await viewModel.addStep(payload)
        XCTAssertNotNil(createdNode)
        XCTAssertEqual(viewModel.nodes.count, initialNodeCount + 1)
        XCTAssertEqual(createdNode?.title, "Morning Sunlight Reading")

        // Node is present in graph
        let found = viewModel.nodes.first(where: { $0.id == createdNode?.id })
        XCTAssertNotNil(found)
    }

    // MARK: - AC-C08: Anchor Protection & Deletion Tests

    func testAnchorNodesCannotBeDeleted() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        let initialCount = viewModel.nodes.count

        // Attempt to delete wake anchor
        viewModel.deleteNode("anchor-wake")
        XCTAssertEqual(viewModel.nodes.count, initialCount)
        XCTAssertNotNil(viewModel.nodes.first(where: { $0.id == "anchor-wake" }))

        // Attempt to delete bedtime anchor
        viewModel.deleteNode("anchor-bedtime")
        XCTAssertEqual(viewModel.nodes.count, initialCount)
        XCTAssertNotNil(viewModel.nodes.first(where: { $0.id == "anchor-bedtime" }))
    }

    func testDeleteNonAnchorNodeRemovesItAndBridgesEdges() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        let initialCount = viewModel.nodes.count

        // Delete habit-cold-shower
        viewModel.deleteNode("habit-cold-shower")
        XCTAssertEqual(viewModel.nodes.count, initialCount - 1)
        XCTAssertNil(viewModel.nodes.first(where: { $0.id == "habit-cold-shower" }))

        // Incoming to cold shower was workout; outgoing was planning.
        // A bridged edge e-habit-workout-habit-planning should now exist!
        let bridgedEdge = viewModel.edges.first(where: {
            $0.fromNodeId == "habit-workout" && $0.toNodeId == "habit-planning"
        })
        XCTAssertNotNil(bridgedEdge)
    }

    func testDeleteNodeRollbackOnServerFailure() async throws {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.serverError(statusCode: 500, code: "FAILED", message: "Failed to delete step"))
        ]

        let nodeUUID = UUID().uuidString
        let testNode = ScheduleNode(
            id: nodeUUID,
            type: .habit,
            phase: .morning,
            title: "Disposable Habit",
            order: 2
        )
        let edge = ScheduleEdge(id: "e-d", fromNodeId: nodeUUID, toNodeId: "anchor-bedtime", type: .sequential)
        let initialGraph = ScheduleGraph(
            date: "2026-11-12",
            phases: [SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: "")],
            nodes: [testNode],
            edges: [edge]
        )

        let viewModel = makeViewModel(initialGraph: initialGraph)

        // Delete node
        viewModel.deleteNode(nodeUUID)

        // Optimistically removed
        XCTAssertNil(viewModel.nodes.first { $0.id == nodeUUID })

        // Wait for background delete to fail
        try await Task.sleep(nanoseconds: 100_000_000)

        // Node and edge restored on rollback
        XCTAssertNotNil(viewModel.nodes.first { $0.id == nodeUUID })
        XCTAssertTrue(viewModel.edges.contains { $0.id == "e-d" })
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testAddStepReconcilesTemporaryIdWithServerUUID() async throws {
        let serverUUID = UUID().uuidString
        let serverNodeJSON = """
        {
            "id": "\(serverUUID)",
            "type": "habit",
            "phase": "morning",
            "title": "Morning Water",
            "habitId": "\(serverUUID)",
            "streak": 1,
            "completed": false,
            "order": 1
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(serverNodeJSON.utf8), 200))
        ]

        let initialGraph = ScheduleGraph(
            date: "2026-11-12",
            phases: [SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: "")],
            nodes: [],
            edges: []
        )
        let viewModel = makeViewModel(initialGraph: initialGraph)

        let payload = AddStepPayload(phaseId: .morning, type: .habit, title: "Morning Water")
        let localNode = viewModel.addStepSync(payload)
        XCTAssertNotNil(localNode)
        XCTAssertTrue(localNode?.id.hasPrefix("node-") ?? false)

        // Wait for background reconciliation
        try await Task.sleep(nanoseconds: 100_000_000)

        // The temporary node id should have been reconciled to the canonical server UUID
        XCTAssertNil(viewModel.nodes.first { $0.id == localNode?.id })
        let serverNode = viewModel.nodes.first { $0.id == serverUUID }
        XCTAssertNotNil(serverNode)
        XCTAssertEqual(serverNode?.title, "Morning Water")
    }

    func testAsyncAddStepReturnsServerNodeWithUUID() async throws {
        let serverUUID = UUID().uuidString
        let serverNodeJSON = """
        {
            "id": "\(serverUUID)",
            "type": "task",
            "phase": "deep-focus",
            "title": "Deep Work Sprint",
            "taskId": "\(serverUUID)",
            "completed": false,
            "order": 1
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(serverNodeJSON.utf8), 200))
        ]

        let initialGraph = ScheduleGraph(
            date: "2026-11-12",
            phases: [SchedulePhase(id: .deepFocus, title: "Deep Focus", subtitle: "", timeRange: "")],
            nodes: [],
            edges: []
        )
        let viewModel = makeViewModel(initialGraph: initialGraph)

        let payload = AddStepPayload(phaseId: .deepFocus, type: .task, title: "Deep Work Sprint")
        let resultNode = await viewModel.addStep(payload)

        XCTAssertNotNil(resultNode)
        XCTAssertEqual(resultNode?.id, serverUUID)
        XCTAssertEqual(viewModel.nodes.first?.id, serverUUID)
    }

    func testScheduleNodeTimeAndDurationProperties() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        // Verify wake anchor time
        let wakeNode = viewModel.nodes.first { $0.type == .anchor && $0.anchorKind == "wake" }
        XCTAssertNotNil(wakeNode)
        XCTAssertEqual(wakeNode?.time, "06:30")

        // Verify bedtime anchor target
        let bedtimeNode = viewModel.nodes.first { $0.type == .anchor && $0.anchorKind == "bedtime" }
        XCTAssertNotNil(bedtimeNode)
        XCTAssertEqual(bedtimeNode?.targetTime, "22:30")

        // Verify habit has duration and time
        let habitNode = viewModel.nodes.first { $0.type == .habit && $0.time != nil }
        XCTAssertNotNil(habitNode)
        XCTAssertNotNil(habitNode?.durationMinutes)
        XCTAssertGreaterThan(habitNode?.durationMinutes ?? 0, 0)

        // Verify activity block has duration and scheduled time
        let activityNode = viewModel.nodes.first { $0.type == .task }
        XCTAssertNotNil(activityNode)
        XCTAssertNotNil(activityNode?.durationMinutes)
        XCTAssertGreaterThan(activityNode?.durationMinutes ?? 0, 0)

        // Verify recharge block has duration
        let rechargeNode = viewModel.nodes.first { $0.type == .recharge }
        XCTAssertNotNil(rechargeNode)
        XCTAssertNotNil(rechargeNode?.durationMinutes)
        XCTAssertGreaterThan(rechargeNode?.durationMinutes ?? 0, 0)
    }

    // MARK: - AC-010, AC-011, AC-012: Step Update Tests

    func testUpdateStepOptimisticMutationAndBedtimeRecalculation() async throws {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        guard let initialNode = viewModel.nodes.first(where: { $0.id == "task-top1" }) else {
            XCTFail("Node task-top1 not found")
            return
        }

        XCTAssertEqual(initialNode.title, "Finish authentication architecture")
        XCTAssertEqual(initialNode.durationMinutes, 90)

        let serverResponseJSON = """
        {
            "id": "task-top1",
            "type": "task",
            "phase": "deep-focus",
            "title": "Deep Focus Architecture & System Design",
            "subtitle": "High cognitive load · Core DB schema",
            "time": "09:30",
            "durationMinutes": 120,
            "totalMinutes": 120,
            "notes": "Ensure all FK constraints and indexes are covered.",
            "order": 6
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(serverResponseJSON.utf8), 200))
        ]

        let payload = UpdateStepPayload(
            title: "Deep Focus Architecture & System Design",
            subtitle: "High cognitive load · Core DB schema",
            phaseId: .deepFocus,
            timeSlot: "09:30",
            durationMinutes: 120,
            notes: "Ensure all FK constraints and indexes are covered."
        )

        let updated = try await viewModel.updateStep(id: "task-top1", payload: payload)

        XCTAssertEqual(updated.title, "Deep Focus Architecture & System Design")
        XCTAssertEqual(updated.durationMinutes, 120)

        // Verify state in view model
        let nodeInVM = viewModel.nodes.first(where: { $0.id == "task-top1" })
        XCTAssertEqual(nodeInVM?.title, "Deep Focus Architecture & System Design")
        XCTAssertEqual(nodeInVM?.subtitle, "High cognitive load · Core DB schema")
        XCTAssertEqual(nodeInVM?.time, "09:30")
        XCTAssertEqual(nodeInVM?.durationMinutes, 120)
        XCTAssertEqual(nodeInVM?.totalMinutes, 120)
        XCTAssertEqual(nodeInVM?.notes, "Ensure all FK constraints and indexes are covered.")
        XCTAssertNotNil(viewModel.graph?.projectedBedtime)
    }

    func testUpdateStepPhaseChangeRewiresEdgesWithoutOrphanEdges() async throws {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        guard let task = viewModel.nodes.first(where: { $0.id == "task-top1" }) else {
            XCTFail("task-top1 not found")
            return
        }
        XCTAssertEqual(task.phase, .deepFocus)

        let serverResponseJSON = """
        {
            "id": "task-top1",
            "type": "task",
            "phase": "afternoon",
            "title": "Finish authentication architecture",
            "durationMinutes": 90,
            "totalMinutes": 90,
            "order": 9
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(serverResponseJSON.utf8), 200))
        ]

        let payload = UpdateStepPayload(
            title: task.title,
            phaseId: .afternoon
        )

        _ = try await viewModel.updateStep(id: "task-top1", payload: payload)

        let movedTask = viewModel.nodes.first(where: { $0.id == "task-top1" })
        XCTAssertEqual(movedTask?.phase, .afternoon)

        // Verify edges are cleanly rewired and no orphaned edges exist
        let allNodeIds = Set(viewModel.nodes.map(\.id))
        for edge in viewModel.edges {
            XCTAssertTrue(allNodeIds.contains(edge.fromNodeId), "Orphan edge from: \(edge.fromNodeId)")
            XCTAssertTrue(allNodeIds.contains(edge.toNodeId), "Orphan edge to: \(edge.toNodeId)")
        }

        // Verify that edges connecting different phases have type .phase
        for edge in viewModel.edges {
            let from = viewModel.nodes.first { $0.id == edge.fromNodeId }
            let to = viewModel.nodes.first { $0.id == edge.toNodeId }
            if let from, let to, from.phase != to.phase {
                XCTAssertEqual(edge.type, .phase)
            }
        }
    }

    func testUpdateStepProtectsAnchorNodesFromMutation() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        let initialWakeTitle = viewModel.wakeAnchor?.title

        let payload = UpdateStepPayload(
            title: "Changed Wake Title",
            durationMinutes: 45
        )

        do {
            _ = try await viewModel.updateStep(id: "anchor-wake", payload: payload)
            XCTFail("Expected anchor mutation to be rejected")
        } catch let error as APIError {
            XCTAssertEqual(error.errorCode, "ANCHOR_UPDATE_NOT_ALLOWED")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // State remains intact
        XCTAssertEqual(viewModel.wakeAnchor?.title, initialWakeTitle)
    }

    func testUpdateStepRollsBackOnServerFailure() async {
        let viewModel = makeViewModel()
        await viewModel.loadData()

        guard let initialNode = viewModel.nodes.first(where: { $0.id == "task-top1" }) else {
            XCTFail("Node task-top1 not found")
            return
        }

        let initialTitle = initialNode.title
        let initialDuration = initialNode.durationMinutes

        mockAPIClient.scriptedResponses = [
            .failure(APIError.serverError(statusCode: 500, code: "INTERNAL_ERROR", message: "Server error"))
        ]

        let payload = UpdateStepPayload(
            title: "Should Roll Back",
            durationMinutes: 300
        )

        do {
            _ = try await viewModel.updateStep(id: "task-top1", payload: payload)
            XCTFail("Expected updateStep to throw on server failure")
        } catch {
            // Expected
        }

        // Verify state is restored to pre-mutation snapshot
        let restoredNode = viewModel.nodes.first(where: { $0.id == "task-top1" })
        XCTAssertEqual(restoredNode?.title, initialTitle)
        XCTAssertEqual(restoredNode?.durationMinutes, initialDuration)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

import Foundation
import XCTest
@testable import ProductivityOS

@MainActor
final class ScheduleGraphRewiringTests: XCTestCase {
    func testInsertionBetweenNodesReplacesEdge() {
        let nodeA = ScheduleNode(id: "node-a", type: .habit, phase: .morning, title: "A", completed: true, order: 1)
        let nodeB = ScheduleNode(id: "node-b", type: .task, phase: .deepFocus, title: "B", completed: false, order: 2)
        let edgeAB = ScheduleEdge(id: "e-a-b", fromNodeId: "node-a", toNodeId: "node-b", type: .sequential, active: true)

        let initialGraph = ScheduleGraph(
            date: "2026-11-11",
            phases: [
                SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: ""),
                SchedulePhase(id: .deepFocus, title: "Deep Focus", subtitle: "", timeRange: "")
            ],
            nodes: [nodeA, nodeB],
            edges: [edgeAB]
        )

        let viewModel = ScheduleViewModel(initialGraph: initialGraph)

        let payload = AddStepPayload(
            phaseId: .morning,
            type: .habit,
            title: "C"
        )

        let createdNode = viewModel.addStep(payload)
        XCTAssertNotNil(createdNode)

        // Edge e-a-b should be replaced by e-node-a-node-c and e-node-c-node-b
        XCTAssertFalse(viewModel.edges.contains { $0.id == "e-a-b" })

        let edgeAC = viewModel.edges.first { $0.fromNodeId == "node-a" && $0.toNodeId == createdNode?.id }
        XCTAssertNotNil(edgeAC)
        XCTAssertEqual(edgeAC?.active, true) // Node A is completed

        let edgeCB = viewModel.edges.first { $0.fromNodeId == createdNode?.id && $0.toNodeId == "node-b" }
        XCTAssertNotNil(edgeCB)
        XCTAssertEqual(edgeCB?.active, false) // Node C is fresh/incomplete
    }

    func testDeletingMiddleNodeBridgesNeighbors() {
        let nodeA = ScheduleNode(id: "node-a", type: .habit, phase: .morning, title: "A", completed: true, order: 1)
        let nodeB = ScheduleNode(id: "node-b", type: .habit, phase: .morning, title: "B", completed: true, order: 2)
        let nodeC = ScheduleNode(id: "node-c", type: .habit, phase: .morning, title: "C", completed: false, order: 3)

        let edgeAB = ScheduleEdge(id: "e-a-b", fromNodeId: "node-a", toNodeId: "node-b", type: .sequential, active: true)
        let edgeBC = ScheduleEdge(id: "e-b-c", fromNodeId: "node-b", toNodeId: "node-c", type: .sequential, active: true)

        let initialGraph = ScheduleGraph(
            date: "2026-11-11",
            phases: [SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: "")],
            nodes: [nodeA, nodeB, nodeC],
            edges: [edgeAB, edgeBC]
        )

        let viewModel = ScheduleViewModel(initialGraph: initialGraph)

        // Delete middle node B
        viewModel.deleteNode("node-b")

        XCTAssertEqual(viewModel.nodes.count, 2)
        XCTAssertNil(viewModel.nodes.first { $0.id == "node-b" })

        // Edges mentioning B should be gone
        XCTAssertFalse(viewModel.edges.contains { $0.fromNodeId == "node-b" || $0.toNodeId == "node-b" })

        // Bridge edge A -> C should exist and be active since node-a is completed
        let bridgeEdge = viewModel.edges.first { $0.fromNodeId == "node-a" && $0.toNodeId == "node-c" }
        XCTAssertNotNil(bridgeEdge)
        XCTAssertEqual(bridgeEdge?.active, true)
    }

    func testPhaseReassignmentRewiresGraphCleanly() {
        let wake = ScheduleNode(id: "anchor-wake", type: .anchor, phase: .morning, title: "Wake", anchorKind: "wake", order: 1)
        let habit = ScheduleNode(id: "h1", type: .habit, phase: .morning, title: "Habit 1", completed: true, order: 2)
        let task = ScheduleNode(id: "t1", type: .task, phase: .deepFocus, title: "Task 1", completed: false, order: 3)
        let bedtime = ScheduleNode(id: "anchor-bedtime", type: .anchor, phase: .bedtime, title: "Bedtime", anchorKind: "bedtime", order: 4)

        let initialGraph = ScheduleGraph(
            date: "2026-11-12",
            phases: [
                SchedulePhase(id: .morning, title: "Morning", subtitle: "", timeRange: ""),
                SchedulePhase(id: .deepFocus, title: "Deep Focus", subtitle: "", timeRange: ""),
                SchedulePhase(id: .afternoon, title: "Afternoon", subtitle: "", timeRange: ""),
                SchedulePhase(id: .bedtime, title: "Bedtime", subtitle: "", timeRange: "")
            ],
            nodes: [wake, habit, task, bedtime],
            edges: [
                ScheduleEdge(id: "e-w-h", fromNodeId: "anchor-wake", toNodeId: "h1", type: .sequential, active: true),
                ScheduleEdge(id: "e-h-t", fromNodeId: "h1", toNodeId: "t1", type: .phase, active: true),
                ScheduleEdge(id: "e-t-b", fromNodeId: "t1", toNodeId: "anchor-bedtime", type: .phase, active: false)
            ]
        )

        let viewModel = ScheduleViewModel(initialGraph: initialGraph)

        // Simulate phase update on task
        if var g = viewModel.graph, let idx = g.nodes.firstIndex(where: { $0.id == "t1" }) {
            g.nodes[idx].phase = .afternoon
            // Set graph temporarily then rewire
            viewModel.updateStepSync(id: "t1", payload: UpdateStepPayload(title: "Task 1", phaseId: .afternoon))
        }

        // Verify wake is first, bedtime is last, and edges connect nodes sequentially
        XCTAssertEqual(viewModel.nodes.first?.id, "anchor-wake")
        XCTAssertEqual(viewModel.nodes.last?.id, "anchor-bedtime")
        XCTAssertEqual(viewModel.edges.count, 3)
        XCTAssertTrue(viewModel.edges.contains { $0.fromNodeId == "anchor-wake" && $0.toNodeId == "h1" })
        XCTAssertTrue(viewModel.edges.contains { $0.fromNodeId == "h1" && $0.toNodeId == "t1" && $0.type == .phase })
        XCTAssertTrue(viewModel.edges.contains { $0.fromNodeId == "t1" && $0.toNodeId == "anchor-bedtime" && $0.type == .phase })
    }
}

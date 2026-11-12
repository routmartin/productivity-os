import Foundation
import XCTest
@testable import ProductivityOS

@MainActor
final class ScheduleViewModelTests: XCTestCase {
    func testDailyBlueprintPrePopulation() async {
        let viewModel = ScheduleViewModel()
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

    func testLayoutSwitchingAndPersistence() {
        let viewModel = ScheduleViewModel()

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
        let viewModel = ScheduleViewModel()
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

    func testNativeActivityFocusToggle() async {
        let viewModel = ScheduleViewModel()
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
        let viewModel = ScheduleViewModel()
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

        let createdNode = viewModel.addStep(payload)
        XCTAssertNotNil(createdNode)
        XCTAssertEqual(viewModel.nodes.count, initialNodeCount + 1)
        XCTAssertEqual(createdNode?.title, "Morning Sunlight Reading")

        // Node is present in graph
        let found = viewModel.nodes.first(where: { $0.id == createdNode?.id })
        XCTAssertNotNil(found)
    }

    func testAnchorNodesCannotBeDeleted() async {
        let viewModel = ScheduleViewModel()
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
        let viewModel = ScheduleViewModel()
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
}

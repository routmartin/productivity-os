import Foundation
import XCTest
@testable import ProductivityOS

final class BedtimeCalculatorTests: XCTestCase {
    func testAllCompletedYieldsNoOverflow() {
        let nodes: [ScheduleNode] = [
            ScheduleNode(id: "h1", type: .habit, phase: .morning, title: "Water", completed: true),
            ScheduleNode(id: "t1", type: .task, phase: .deepFocus, title: "Coding", completedMinutes: 60, totalMinutes: 60)
        ]

        let result = BedtimeCalculator.calculate(targetBedtime: "22:30", nodes: nodes)

        XCTAssertEqual(result.overflowMinutes, 0)
        XCTAssertEqual(result.projectedBedtime, "22:30")
        XCTAssertFalse(result.isOverflowing)
        XCTAssertEqual(result.statusMessage, "On track for 22:30 bedtime")
    }

    func testSinglePendingItemShiftsBedtimeBy15Minutes() {
        let nodes: [ScheduleNode] = [
            ScheduleNode(id: "h1", type: .habit, phase: .morning, title: "Water", completed: false)
        ]

        let result = BedtimeCalculator.calculate(targetBedtime: "22:30", nodes: nodes)

        XCTAssertEqual(result.overflowMinutes, 15)
        XCTAssertEqual(result.projectedBedtime, "22:45")
        XCTAssertTrue(result.isOverflowing)
        XCTAssertEqual(result.statusMessage, "Schedule overflow: Bedtime shifts by 15m")
    }

    func testMultiplePendingItemsCapsOverflowAt45Minutes() {
        let nodes: [ScheduleNode] = [
            ScheduleNode(id: "h1", type: .habit, phase: .morning, title: "Habit 1", completed: false),
            ScheduleNode(id: "h2", type: .habit, phase: .morning, title: "Habit 2", completed: false),
            ScheduleNode(id: "t1", type: .task, phase: .deepFocus, title: "Task 1", completedMinutes: 0, totalMinutes: 60),
            ScheduleNode(id: "t2", type: .task, phase: .afternoon, title: "Task 2", completedMinutes: 0, totalMinutes: 60)
        ]

        // 4 pending items * 15m = 60m, but capped at 45m per spec AC-004
        let result = BedtimeCalculator.calculate(targetBedtime: "22:30", nodes: nodes)

        XCTAssertEqual(result.overflowMinutes, 45)
        XCTAssertEqual(result.projectedBedtime, "23:15")
        XCTAssertTrue(result.isOverflowing)
    }

    func testMidnightCrossingProjection() {
        let nodes: [ScheduleNode] = [
            ScheduleNode(id: "h1", type: .habit, phase: .bedtime, title: "Late Habit", completed: false),
            ScheduleNode(id: "t1", type: .task, phase: .bedtime, title: "Late Task", completedMinutes: 0, totalMinutes: 60)
        ]

        // 2 items * 15m = 30m overflow. Target 23:45 + 30m = 00:15
        let result = BedtimeCalculator.calculate(targetBedtime: "23:45", nodes: nodes)

        XCTAssertEqual(result.overflowMinutes, 30)
        XCTAssertEqual(result.projectedBedtime, "00:15")
        XCTAssertTrue(result.isOverflowing)
    }
}

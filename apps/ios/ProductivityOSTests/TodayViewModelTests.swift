import Foundation
import XCTest
@testable import ProductivityOS

final class TodayViewModelTests: XCTestCase {
    func testStatsDerivedFromSessions() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.date(byAdding: .hour, value: -1, to: now)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let sessions = [
            FocusSession(taskId: UUID(), startedAt: today, endedAt: today.addingTimeInterval(1500), durationSeconds: 1500, isActive: false),
            FocusSession(taskId: UUID(), startedAt: yesterday, endedAt: yesterday.addingTimeInterval(2700), durationSeconds: 2700, isActive: false),
            FocusSession(taskId: UUID(), startedAt: twoDaysAgo, endedAt: twoDaysAgo.addingTimeInterval(3600), durationSeconds: 3600, isActive: false),
        ]

        let viewModel = TodayViewModel(preloadSessions: sessions)

        XCTAssertEqual(viewModel.completedSessionsCount, 1)
        XCTAssertEqual(viewModel.todayFocusedSeconds, 1500, accuracy: 60)
        XCTAssertEqual(viewModel.dayStreak, 3)
        XCTAssertEqual(
            viewModel.weeklyFocusFormatted,
            TodayViewModel.formatFocusTime(1500 + 2700 + 3600)
        )
        // Ring progress is today's share of the week's focus.
        XCTAssertEqual(viewModel.todayFocusProgress, Double(1500) / Double(1500 + 2700 + 3600), accuracy: 0.01)
    }

    func testStreakBreaksOnMissingDay() {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!

        let sessions = [
            FocusSession(taskId: UUID(), startedAt: yesterday, endedAt: yesterday, durationSeconds: 600, isActive: false),
            FocusSession(taskId: UUID(), startedAt: threeDaysAgo, endedAt: threeDaysAgo, durationSeconds: 600, isActive: false),
        ]

        XCTAssertEqual(TodayViewModel.computeStreak(sessions: sessions, calendar: calendar, reference: now), 1)
    }

    func testStreakZeroWithoutSessions() {
        XCTAssertEqual(TodayViewModel.computeStreak(sessions: [], calendar: .current, reference: Date()), 0)
    }

    func testTopThreeItemMapsToRealTaskWhenPresent() {
        let realID = UUID()
        let realTask = TaskItem(id: realID, title: "Real", priority: .high, status: .pending, projectName: nil)
        let item = TopThreeItem(taskId: realID, taskTitle: "Real", position: 2)

        let mapped = TodayViewModel.taskItem(from: item, in: [realTask])
        XCTAssertEqual(mapped.id, realID)
        XCTAssertEqual(mapped.title, "Real")
        XCTAssertEqual(mapped.priority, .high)
    }

    func testTopThreeItemFallsBackToItemDataWhenTaskMissing() {
        let orphanID = UUID()
        let item = TopThreeItem(
            taskId: orphanID,
            taskTitle: "Deleted from list",
            position: 1,
            priority: .low
        )

        let mapped = TodayViewModel.taskItem(from: item, in: [])
        XCTAssertEqual(mapped.id, orphanID)
        XCTAssertEqual(mapped.title, "Deleted from list")
        XCTAssertEqual(mapped.priority, .low)
    }
}

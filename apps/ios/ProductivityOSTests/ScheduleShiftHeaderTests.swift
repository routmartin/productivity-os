import XCTest
import SwiftUI
@testable import ProductivityOS

final class ScheduleShiftHeaderTests: XCTestCase {

    func testMorningShiftTheme() {
        let theme = ScheduleShiftTheme.theme(for: .morning)
        XCTAssertEqual(theme.icon, "sun.max.fill")
        XCTAssertEqual(theme.accentHex, "EA580C")
        XCTAssertEqual(theme.backgroundHex, "FFF7ED")
        XCTAssertEqual(theme.borderHex, "FDBA74")
        XCTAssertEqual(SchedulePhaseId.morning.shiftTheme, theme)
    }

    func testAfternoonShiftTheme() {
        let theme = ScheduleShiftTheme.theme(for: .afternoon)
        XCTAssertEqual(theme.icon, "bolt.fill")
        XCTAssertEqual(theme.accentHex, "2563EB")
        XCTAssertEqual(theme.backgroundHex, "EFF6FF")
        XCTAssertEqual(theme.borderHex, "93C5FD")
        XCTAssertEqual(SchedulePhaseId.afternoon.shiftTheme, theme)
    }

    func testBedtimeShiftTheme() {
        let theme = ScheduleShiftTheme.theme(for: .bedtime)
        XCTAssertEqual(theme.icon, "moon.stars.fill")
        XCTAssertEqual(theme.accentHex, "6366F1")
        XCTAssertEqual(theme.backgroundHex, "EEF2FF")
        XCTAssertEqual(theme.borderHex, "C7D2FE")
        XCTAssertEqual(SchedulePhaseId.bedtime.shiftTheme, theme)
    }

    func testDeepFocusShiftTheme() {
        let theme = ScheduleShiftTheme.theme(for: .deepFocus)
        XCTAssertEqual(theme.icon, "brain.head.profile")
        XCTAssertEqual(theme.accentHex, "7C3AED")
        XCTAssertEqual(theme.backgroundHex, "F5F3FF")
        XCTAssertEqual(theme.borderHex, "DDD6FE")
        XCTAssertEqual(SchedulePhaseId.deepFocus.shiftTheme, theme)
    }

    func testNumberedShiftKickerFormatting() {
        let morningHeader = ScheduleShiftHeaderView(
            phaseId: .morning,
            title: "Morning Activation",
            subtitle: "Rise & shine",
            timeRange: "06:30 – 09:00",
            shiftNumber: 1,
            completedCount: 2,
            totalCount: 3,
            onAddStep: {}
        )
        XCTAssertEqual(morningHeader.kickerText, "SHIFT 01 · 06:30 – 09:00")

        let afternoonHeader = ScheduleShiftHeaderView(
            phaseId: .afternoon,
            title: "Afternoon Momentum",
            subtitle: "Keep moving",
            timeRange: "12:30 – 18:00",
            shiftNumber: 2,
            completedCount: 1,
            totalCount: 4,
            onAddStep: {}
        )
        XCTAssertEqual(afternoonHeader.kickerText, "SHIFT 02 · 12:30 – 18:00")

        let bedtimeHeader = ScheduleShiftHeaderView(
            phaseId: .bedtime,
            title: "Bedtime Sanctuary",
            subtitle: "Wind down",
            timeRange: "21:00 – 22:30",
            shiftNumber: 3,
            completedCount: 3,
            totalCount: 3,
            onAddStep: {}
        )
        XCTAssertEqual(bedtimeHeader.kickerText, "SHIFT 03 · 21:00 – 22:30")
    }

    func testDeepFocusKickerFormatting() {
        let deepFocusHeader = ScheduleShiftHeaderView(
            phaseId: .deepFocus,
            title: "Deep Focus Work",
            subtitle: "Uninterrupted flow",
            timeRange: "09:00 – 12:30",
            shiftNumber: nil,
            completedCount: 0,
            totalCount: 2,
            onAddStep: {}
        )
        XCTAssertEqual(deepFocusHeader.kickerText, "DEEP FOCUS · 09:00 – 12:30")
    }

    func testEmptyTimeRangeKicker() {
        let numberedHeader = ScheduleShiftHeaderView(
            phaseId: .morning,
            title: "Morning Activation",
            subtitle: "",
            timeRange: "",
            shiftNumber: 1,
            onAddStep: {}
        )
        XCTAssertEqual(numberedHeader.kickerText, "SHIFT 01")

        let deepFocusHeader = ScheduleShiftHeaderView(
            phaseId: .deepFocus,
            title: "Deep Focus Work",
            subtitle: "",
            timeRange: "",
            shiftNumber: nil,
            onAddStep: {}
        )
        XCTAssertEqual(deepFocusHeader.kickerText, "DEEP FOCUS")
    }

    func testConvenienceInitFromSchedulePhase() {
        let phase = SchedulePhase(
            id: .morning,
            title: "Morning Activation",
            subtitle: "Hydrate and plan",
            timeRange: "06:30 – 09:00"
        )
        let header = ScheduleShiftHeaderView(
            phase: phase,
            shiftNumber: 1,
            completedCount: 2,
            totalCount: 3,
            onAddStep: {}
        )
        XCTAssertEqual(header.phaseId, .morning)
        XCTAssertEqual(header.title, "Morning Activation")
        XCTAssertEqual(header.subtitle, "Hydrate and plan")
        XCTAssertEqual(header.timeRange, "06:30 – 09:00")
        XCTAssertEqual(header.shiftNumber, 1)
        XCTAssertEqual(header.completedCount, 2)
        XCTAssertEqual(header.totalCount, 3)
    }

    func testCompletionBadgeThresholds() {
        let inProgressHeader = ScheduleShiftHeaderView(
            phaseId: .morning,
            title: "Morning Activation",
            subtitle: "Routine",
            timeRange: "06:30 – 09:00",
            shiftNumber: 1,
            completedCount: 2,
            totalCount: 3,
            onAddStep: {}
        )
        XCTAssertEqual(inProgressHeader.completedCount, 2)
        XCTAssertEqual(inProgressHeader.totalCount, 3)

        let completedHeader = ScheduleShiftHeaderView(
            phaseId: .bedtime,
            title: "Bedtime Sanctuary",
            subtitle: "Rest",
            timeRange: "21:00 – 22:30",
            shiftNumber: 3,
            completedCount: 3,
            totalCount: 3,
            onAddStep: {}
        )
        XCTAssertEqual(completedHeader.completedCount, 3)
        XCTAssertEqual(completedHeader.totalCount, 3)
    }
}

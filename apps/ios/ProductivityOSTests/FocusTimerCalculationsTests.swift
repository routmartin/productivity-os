import XCTest
@testable import ProductivityOS

final class FocusTimerCalculationsTests: XCTestCase {
    
    func testBackgroundingResilience() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 10000)
        state.start(task: SampleData.taskAuth, duration: FocusDuration(totalSeconds: 1500), at: start)

        // Simulate app going to background and user returning 18 minutes (1080 sec) later
        let returnDate = Date(timeIntervalSince1970: 10000 + 1080)

        // 1080 seconds elapsed out of 1500 seconds (25 min)
        XCTAssertEqual(state.elapsedSeconds(at: returnDate), 1080)
        XCTAssertEqual(state.remainingSeconds(at: returnDate), 420) // 7 min remaining
        XCTAssertEqual(state.formattedTimer(at: returnDate), "07:00")

        // Progress should be 1080 / 1500 = 0.72
        XCTAssertEqual(state.progress(at: returnDate), 0.72, accuracy: 0.001)
    }

    func testUnlimitedDurationFormatting() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: .unlimited, at: start)

        // After 42 minutes and 18 seconds (2538 seconds)
        let checkDate = Date(timeIntervalSince1970: 1000 + 2538)

        XCTAssertNil(state.remainingSeconds(at: checkDate))
        XCTAssertEqual(state.elapsedSeconds(at: checkDate), 2538)
        XCTAssertEqual(state.formattedTimer(at: checkDate), "42:18")
    }

    func testOvertimeClamping() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: FocusDuration(totalSeconds: 1500), at: start)

        // 30 minutes later (over 25 min limit)
        let overDate = Date(timeIntervalSince1970: 1000 + 1800)

        XCTAssertEqual(state.remainingSeconds(at: overDate), 0)
        XCTAssertEqual(state.progress(at: overDate), 1.0)
        XCTAssertEqual(state.formattedTimer(at: overDate), "00:00")
    }

    func testSessionDurationExtension() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: FocusDuration(totalSeconds: 1500), at: start)

        // 10 minutes elapsed (600s), 15 minutes left (900s)
        let checkDate = Date(timeIntervalSince1970: 1000 + 600)
        XCTAssertEqual(state.remainingSeconds(at: checkDate), 900)

        // User hits +5m bump (300 seconds)
        state.extend(by: 300)

        // Configured duration should now be 1800s (30m)
        XCTAssertEqual(state.configuredDuration.totalSeconds, 1800)
        // Remaining seconds should now be 1200s (20m)
        XCTAssertEqual(state.remainingSeconds(at: checkDate), 1200)
        XCTAssertEqual(state.formattedTimer(at: checkDate), "20:00")
    }

    func testUnlimitedSessionDurationExtension() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: .unlimited, at: start)

        // 10 minutes elapsed (600s)
        let checkDate = Date(timeIntervalSince1970: 1000 + 600)
        XCTAssertNil(state.remainingSeconds(at: checkDate))

        // +5m bump converts unlimited into targeted countdown (600 + 300 = 900s total)
        state.extend(by: 300, at: checkDate)
        XCTAssertEqual(state.configuredDuration.totalSeconds, 900)
        XCTAssertEqual(state.remainingSeconds(at: checkDate), 300)
        XCTAssertEqual(state.formattedTimer(at: checkDate), "05:00")
    }

    func testMooasTimerParser() {
        // Standard countdown (MM:SS)
        let standard = MooasTimerComponents.parse("25:00")
        XCTAssertEqual(standard.leftValue, "25")
        XCTAssertEqual(standard.rightValue, "00")
        XCTAssertEqual(standard.leftSublabel, "MIN")
        XCTAssertEqual(standard.rightSublabel, "SEC")

        // Single digit minute remaining ("04:15")
        let singleMin = MooasTimerComponents.parse("04:15")
        XCTAssertEqual(singleMin.leftValue, "04")
        XCTAssertEqual(singleMin.rightValue, "15")

        // Over an hour (HH:MM:SS -> "01:25:30")
        let longSession = MooasTimerComponents.parse("01:25:30")
        XCTAssertEqual(longSession.leftValue, "01")
        XCTAssertEqual(longSession.rightValue, "25")
        XCTAssertEqual(longSession.leftSublabel, "HR")
        XCTAssertEqual(longSession.rightSublabel, "MIN")

        // TodayView focused time format ("2h 18m")
        let todayStats = MooasTimerComponents.parse("2h 18m")
        XCTAssertEqual(todayStats.leftValue, "02")
        XCTAssertEqual(todayStats.rightValue, "18")
        XCTAssertEqual(todayStats.leftSublabel, "HR")
        XCTAssertEqual(todayStats.rightSublabel, "MIN")

        // Sub-hour TodayView stats ("45m")
        let subHourStats = MooasTimerComponents.parse("45m")
        XCTAssertEqual(subHourStats.leftValue, "45")
        XCTAssertEqual(subHourStats.rightValue, "00")
        XCTAssertEqual(subHourStats.leftSublabel, "MIN")
        XCTAssertEqual(subHourStats.rightSublabel, "SEC")
    }

    func testMooasFlipFlapViewAnimatableData() {
        var flap = MooasFlipFlapView(
            progress: 0.25,
            oldDigit: "25",
            newDigit: "24",
            sublabel: "MIN",
            width: 124,
            height: 136,
            halfHeight: 67.25,
            seamHeight: 1.5,
            cornerRadius: 7.0,
            theme: .naturalBeech,
            isMini: false
        )
        XCTAssertEqual(flap.animatableData, 0.25, accuracy: 0.0001)

        flap.animatableData = 0.75
        XCTAssertEqual(flap.progress, 0.75, accuracy: 0.0001)
    }

    @MainActor
    func testViewModelAddMinutes() {
        let mock = MockAPIClient()
        let vm = FocusSessionViewModel(apiClient: mock)
        vm.selectedTask = SampleData.taskAuth
        vm.sessionState.start(task: vm.selectedTask, duration: FocusDuration(totalSeconds: 1500))

        XCTAssertEqual(vm.sessionState.configuredDuration.totalSeconds, 1500)
        vm.addMinutes(5)
        XCTAssertEqual(vm.sessionState.configuredDuration.totalSeconds, 1800)
    }
}

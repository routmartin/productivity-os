import XCTest
@testable import ProductivityOS

final class FocusTimerCalculationsTests: XCTestCase {
    
    func testBackgroundingResilience() {
        var state = FocusSessionState()
        let start = Date(timeIntervalSince1970: 10000)
        state.start(task: SampleData.taskAuth, duration: .pomodoro25, at: start)
        
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
        state.start(task: SampleData.taskAuth, duration: .pomodoro25, at: start)
        
        // 30 minutes later (over 25 min limit)
        let overDate = Date(timeIntervalSince1970: 1000 + 1800)
        
        XCTAssertEqual(state.remainingSeconds(at: overDate), 0)
        XCTAssertEqual(state.progress(at: overDate), 1.0)
        XCTAssertEqual(state.formattedTimer(at: overDate), "00:00")
    }
}

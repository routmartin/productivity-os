import XCTest
@testable import ProductivityOS

final class FocusSessionStateTests: XCTestCase {
    
    func testInitialStateIsPreparing() {
        let state = FocusSessionState()
        XCTAssertEqual(state.state, .preparing)
        XCTAssertNil(state.startTime)
        XCTAssertNil(state.pauseStartTime)
        XCTAssertEqual(state.totalPausedSeconds, 0)
    }
    
    func testStartSession() {
        var state = FocusSessionState()
        let startDate = Date(timeIntervalSince1970: 1000000)
        let task = SampleData.taskAuth
        
        state.start(task: task, duration: .pomodoro25, at: startDate)
        
        XCTAssertEqual(state.state, .running)
        XCTAssertEqual(state.startTime, startDate)
        XCTAssertEqual(state.configuredDuration, .pomodoro25)
        XCTAssertEqual(state.selectedTask?.id, task.id)
    }
    
    func testPauseAndResumeCalculations() {
        var state = FocusSessionState()
        let startDate = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: .pomodoro25, at: startDate)
        
        // 500 seconds running
        let pauseDate = Date(timeIntervalSince1970: 1500)
        state.pause(at: pauseDate)
        
        XCTAssertEqual(state.state, .paused)
        XCTAssertEqual(state.pauseStartTime, pauseDate)
        XCTAssertEqual(state.elapsedSeconds(at: Date(timeIntervalSince1970: 1600)), 500)
        
        // Resume after 200 seconds paused
        let resumeDate = Date(timeIntervalSince1970: 1700)
        state.resume(at: resumeDate)
        
        XCTAssertEqual(state.state, .running)
        XCTAssertNil(state.pauseStartTime)
        XCTAssertEqual(state.totalPausedSeconds, 200)
        
        // Check elapsed after another 300 seconds running (at t = 2000)
        let checkDate = Date(timeIntervalSince1970: 2000)
        // Total time = 1000s, paused = 200s => active = 800s
        XCTAssertEqual(state.elapsedSeconds(at: checkDate), 800)
    }
    
    func testCompleteSession() {
        var state = FocusSessionState()
        let startDate = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: .pomodoro25, at: startDate)
        
        let completeDate = Date(timeIntervalSince1970: 2500)
        state.complete(at: completeDate)
        
        XCTAssertEqual(state.state, .completed)
        XCTAssertEqual(state.endTime, completeDate)
        XCTAssertEqual(state.elapsedSeconds(), 1500)
    }
    
    func testCancelSession() {
        var state = FocusSessionState()
        let startDate = Date(timeIntervalSince1970: 1000)
        state.start(task: SampleData.taskAuth, duration: .deepWork45, at: startDate)
        
        let cancelDate = Date(timeIntervalSince1970: 1600)
        state.cancel(at: cancelDate)
        
        XCTAssertEqual(state.state, .cancelled)
        XCTAssertEqual(state.endTime, cancelDate)
        XCTAssertEqual(state.elapsedSeconds(), 600)
    }
}

import XCTest
@testable import ProductivityOS

final class AppTabTests: XCTestCase {
    func testAppTabCasesCountAndOrder() {
        let tabs = AppTab.allCases
        XCTAssertEqual(tabs.count, 4, "Expected exactly 4 primary tabs")
        XCTAssertEqual(tabs, [.schedule, .goals, .tasks, .me])
    }

    func testAppTabIconNamesAreValid() {
        for tab in AppTab.allCases {
            XCTAssertFalse(tab.iconName.isEmpty, "Tab \(tab) should have a valid iconName")
            XCTAssertFalse(tab.id.isEmpty, "Tab \(tab) should have a valid id")
            XCTAssertFalse(tab.rawValue.isEmpty, "Tab \(tab) should have a valid rawValue")
        }
    }

    func testScheduleTabCases() {
        let tabs = ScheduleTab.allCases
        XCTAssertEqual(tabs.count, 2, "Expected exactly 2 schedule tabs")
        XCTAssertEqual(tabs, [.routine, .deepWork])
        XCTAssertEqual(ScheduleTab.routine.rawValue, "Routine")
        XCTAssertEqual(ScheduleTab.deepWork.rawValue, "Deep Work")
        XCTAssertEqual(ScheduleTab.routine.id, "Routine")
        XCTAssertEqual(ScheduleTab.deepWork.id, "Deep Work")
    }
}

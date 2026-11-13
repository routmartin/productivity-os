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
}

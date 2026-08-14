import XCTest

final class NukeUnitTrackerUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Nuke Unit Tracker"].waitForExistence(timeout: 3) || app.buttons["Home"].exists)
    }
}


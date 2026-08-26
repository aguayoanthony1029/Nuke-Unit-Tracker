import XCTest

final class NukeUnitTrackerUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()

        let onboardingLoaded = app.buttons["START TRACKING"].waitForExistence(timeout: 12)
        let commandCenterLoaded = app.buttons["Home"].exists

        XCTAssertTrue(onboardingLoaded || commandCenterLoaded)
    }
}


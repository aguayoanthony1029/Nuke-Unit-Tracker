import XCTest

final class NukeUnitTrackerUITests: XCTestCase {
    func testLaunches() {
        let app = makeFreshApp()
        app.launch()

        let onboardingLoaded = app.buttons["START TRACKING"].waitForExistence(timeout: 12)
        let commandCenterLoaded = app.buttons["Home"].exists

        XCTAssertTrue(onboardingLoaded || commandCenterLoaded)
    }

    func testOnboardingAndSavingABet() {
        let app = makeFreshApp()
        app.launch()

        completeOnboarding(in: app)
        app.buttons["Log a bet"].tap()

        let titleField = app.textFields["Matchup or selection"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Lakers -3.5")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Lakers -3.5"].waitForExistence(timeout: 5))
        app.buttons["Bets"].tap()
        XCTAssertTrue(app.staticTexts["Lakers -3.5"].waitForExistence(timeout: 5))
        app.buttons["Stats"].tap()
        XCTAssertTrue(app.navigationBars["Stats"].waitForExistence(timeout: 5))
    }

    func testReviewDisclosuresAndPrivacyControlsAreReachable() {
        let app = makeFreshApp()
        app.launch()
        completeOnboarding(in: app)

        let communityButton = app.buttons["Join the Nuke Sports Bets Community"]
        XCTAssertTrue(communityButton.waitForExistence(timeout: 5))
        communityButton.tap()

        XCTAssertTrue(app.staticTexts["Membership is separate from the tracker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["community-separation-disclosure"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["community-membership-link"].exists)
        app.buttons["Close community invitation"].tap()

        app.buttons["You"].tap()
        XCTAssertTrue(app.navigationBars["You"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["delete-all-data-button"].exists)

        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["privacy-policy-link"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["support-link"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["responsible-use-link"].exists)
    }

    func testUnitValueEditorCanBeDismissed() {
        let app = makeFreshApp()
        app.launch()
        completeOnboarding(in: app)

        app.buttons["You"].tap()
        let editUnitValue = app.descendants(matching: .any)["edit-unit-value-button"]
        XCTAssertTrue(editUnitValue.waitForExistence(timeout: 5))
        editUnitValue.tap()

        let unitInput = app.textFields["unit-value-input"]
        XCTAssertTrue(unitInput.waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertFalse(unitInput.exists)

        editUnitValue.tap()
        XCTAssertTrue(unitInput.waitForExistence(timeout: 5))
        app.buttons["Save"].tap()
        XCTAssertFalse(unitInput.exists)
    }

    func testSlipScannerIsAvailableWhenAddingABet() {
        let app = makeFreshApp()
        app.launch()
        completeOnboarding(in: app)

        app.buttons["Log a bet"].tap()
        XCTAssertTrue(app.textFields["Matchup or selection"].waitForExistence(timeout: 5))
        app.swipeUp()

        let scanButton = app.descendants(matching: .any)["scan-slip-button"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 5))
    }

    func testDeleteAllDataReturnsToOnboarding() {
        let app = makeFreshApp()
        app.launch()
        completeOnboarding(in: app)

        app.buttons["You"].tap()
        let deleteButton = app.descendants(matching: .any)["delete-all-data-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let confirmButton = app.buttons["Delete Everything"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertTrue(app.buttons["START TRACKING"].waitForExistence(timeout: 5))
    }

    private func completeOnboarding(in app: XCUIApplication) {
        let startButton = app.buttons["START TRACKING"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12))
        startButton.tap()
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
    }

    private func makeFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        return app
    }
}

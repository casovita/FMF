import XCTest

@MainActor
final class SessionFormUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRestControlShowsValueAndUpdates() throws {
        let app = XCUIApplication()
        app.launchArguments.append("ui-test-session-form")
        app.launch()

        let restValue = app.staticTexts["sessionForm.rest.value"]
        XCTAssertTrue(restValue.waitForExistence(timeout: 5))
        XCTAssertEqual(restValue.label, "45 sec")

        // Tap tile to open wheel picker
        let restTile = app.buttons["sessionForm.rest.tile"]
        XCTAssertTrue(restTile.exists)
        restTile.tap()

        // Adjust wheel picker to 46 sec
        let pickerWheel = app.pickerWheels.firstMatch
        XCTAssertTrue(pickerWheel.waitForExistence(timeout: 3))
        pickerWheel.adjust(toPickerWheelValue: "46 sec")

        // Commit
        app.buttons["Done"].tap()

        XCTAssertEqual(restValue.label, "46 sec")
    }

    func testIncreasingSetsAddsAnotherDurationRow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("ui-test-session-form")
        app.launch()

        XCTAssertTrue(app.staticTexts["sessionForm.durationSet3.label"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["sessionForm.durationSet4.label"].exists)

        // Tap sets tile to open wheel picker
        let setsTile = app.buttons["sessionForm.sets.tile"]
        XCTAssertTrue(setsTile.exists)
        setsTile.tap()

        // Adjust wheel picker to 4 sets
        let pickerWheel = app.pickerWheels.firstMatch
        XCTAssertTrue(pickerWheel.waitForExistence(timeout: 3))
        pickerWheel.adjust(toPickerWheelValue: "4")

        // Commit
        app.buttons["Done"].tap()

        let set4Label = app.staticTexts["sessionForm.durationSet4.label"]
        XCTAssertTrue(set4Label.waitForExistence(timeout: 5))
        XCTAssertEqual(set4Label.label, "Set 4")
    }
}

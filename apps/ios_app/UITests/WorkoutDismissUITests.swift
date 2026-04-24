import XCTest

@MainActor
final class WorkoutDismissUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testBackButtonDismissesWorkoutScreen() throws {
        let app = XCUIApplication()
        app.launchArguments.append("ui-test-workout-back")
        app.launch()

        let backButton = app.buttons["workout.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()

        let dismissedMarker = app.staticTexts["workout.dismissedMarker"]
        XCTAssertTrue(dismissedMarker.waitForExistence(timeout: 5))
    }

    func testBackButtonDismissesCameraTrackingScreen() throws {
        let app = XCUIApplication()
        app.launchArguments.append("ui-test-workout-back")
        app.launch()

        let smartModeButton = app.buttons["workout.mode.smart"]
        XCTAssertTrue(smartModeButton.waitForExistence(timeout: 5))
        smartModeButton.tap()

        let cameraStatus = app.staticTexts["workout.camera.status"]
        XCTAssertTrue(cameraStatus.waitForExistence(timeout: 5))

        let backButton = app.buttons["workout.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()

        let dismissedMarker = app.staticTexts["workout.dismissedMarker"]
        XCTAssertTrue(dismissedMarker.waitForExistence(timeout: 5))
    }
}

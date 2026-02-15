import XCTest

final class AppStoreScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Helpers

    private func launch(appearance: String = "Light") {
        app.launchArguments += ["-UIUserInterfaceStyle", appearance]
        app.launch()
    }

    private func saveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tap(_ labels: String...) {
        for label in labels {
            app.buttons[label].tap()
        }
    }

    private func tap(_ offset: CGVector) {
        app.coordinate(withNormalizedOffset: offset).tap()
    }

    // MARK: - Screenshots

    func testGetScreenshots() {
        let topMiddle = CGVector(dx: 0.5, dy: 0.1)

        launch()

        tap("settings")
        tap("format", "Inches")
        tap("theme", "Light")
        tap(topMiddle)
        tap("1", "3", "slash", "1", "6", "plus", "1", "space", "1", "slash", "4", "plus", "1", ".", "5", "'")
        saveScreenshot(named: "01-number-formats")

        tap("equal")
        saveScreenshot(named: "02-basic-results")

        tap("settings", "format", "Feet and Inches", "format")
        saveScreenshot(named: "03-result-format")

        tap(topMiddle)
        tap(topMiddle)
        tap("metric")
        saveScreenshot(named: "04-metric-results")

        tap("clear/backspace")
        tap("(", "3", "2", "\"", "minus", "4", "metric", "cm", ")", "divide", "2")
        saveScreenshot(named: "05-mixed-input")

        tap("settings")
        tap("format", "Inches")
        tap(topMiddle)
        tap("equal")
        tap("roundingError")
        saveScreenshot(named: "06-rounding-error")

        tap(topMiddle)
        tap("history")
        saveScreenshot(named: "07-history")

        tap(topMiddle)
        tap("1", "'", "space", "3", "space", "3", "slash", "1", "6", "\"", "multiply", "1", "0", "\"")
        tap("equal")
        saveScreenshot(named: "08-square-inch-result")

        tap("settings")
        // We don't care about the format but it's required to be able to locate the theme selector
        // for some reason -- perhaps because interacting with the sheet using an element that's
        // already in the viewport causes the other elements in the sheet to be registered?
        tap("format", "Inches")
        tap("theme", "Dark")
        tap(topMiddle)
        saveScreenshot(named: "09-dark-mode")
    }
}

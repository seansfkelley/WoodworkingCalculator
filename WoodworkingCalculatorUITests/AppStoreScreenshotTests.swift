import XCTest

final class AppStoreScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    private func saveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tap(_ label: String) {
        app.buttons[label].tap()
    }

    private func tapImage(_ systemName: String) {
        app.buttons[systemName].tap()
    }

    // MARK: - Screenshots

    func testScreenshot_01_basicResult() {
        tap("1")
        tapImage("plus")
        tap("1")
        tapImage("equal")
        saveScreenshot(named: "01_basic_result")
    }
}

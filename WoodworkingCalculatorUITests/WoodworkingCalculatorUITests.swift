import XCTest

final class WoodworkingCalculatorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBasicArithmetic() throws {
        let app = XCUIApplication()
        app.launch()
        
        app/*@START_MENU_TOKEN@*/.buttons["3"]/*[[".groups.buttons[\"3\"]",".buttons[\"3\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["⁄"]/*[[".groups.buttons[\"⁄\"]",".buttons[\"⁄\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["8"]/*[[".groups.buttons[\"8\"]",".buttons[\"8\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["multiply"]/*[[".groups.buttons[\"multiply\"]",".buttons[\"multiply\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["7"]/*[[".groups.buttons[\"7\"]",".buttons[\"7\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["equal"]/*[[".groups.buttons[\"equal\"]",".buttons[\"equal\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        XCTAssertEqual(app.staticTexts["readout"].label, "2 ⁵⁄₈\"")
    }
}

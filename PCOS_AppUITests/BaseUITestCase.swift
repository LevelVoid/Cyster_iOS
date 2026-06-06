import XCTest

class BaseUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()

        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func tapTab(label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(label)' not found")
        tab.tap()
    }
}

//
//  BaseUITestCase.swift
//  PCOS_AppUITests
//
//  Base class for all UI tests. Handles safe app launch with the
//  -UITestMode flag so Core Data uses an ephemeral in-memory database,
//  guaranteeing tests never touch the user's real data.
//

import XCTest

class BaseUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        // Tell the app it is running under UI tests.
        // AppDelegate detects this flag and switches Core Data to /dev/null.
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Waits for an element to exist before interacting with it.
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Taps a tab bar item by its label.
    func tapTab(label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(label)' not found")
        tab.tap()
    }
}

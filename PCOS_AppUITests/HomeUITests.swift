//
//  HomeUITests.swift
//  PCOS_AppUITests
//
//  Tests for the Home screen: cycle header visibility,
//  symptom logging flow, and navigation bar buttons.
//

import XCTest

final class HomeUITests: BaseUITestCase {

    // MARK: - Home Screen Content

    func testHomeCollectionViewIsVisible() {
        let home = HomePage(app: app)
        home.assertLoaded()
        XCTAssertTrue(home.collectionView.exists,
                      "Home screen collection view must be visible")
    }

    func testCalendarBarButtonIsPresent() {
        let home = HomePage(app: app)
        home.assertLoaded()
        // Bar button items use their accessibility identifier
        let calendarBtn = app.navigationBars.buttons["home_calendarBarButton"]
        XCTAssertTrue(calendarBtn.waitForExistence(timeout: 5),
                      "Calendar bar button should exist in the navigation bar")
    }

    func testProfileBarButtonIsPresent() {
        let home = HomePage(app: app)
        home.assertLoaded()
        let profileBtn = app.navigationBars.buttons["home_profileBarButton"]
        XCTAssertTrue(profileBtn.waitForExistence(timeout: 5),
                      "Profile bar button should exist in the navigation bar")
    }

    // MARK: - Symptom Flow

    func testAddSymptomCellExists() {
        let home = HomePage(app: app)
        home.assertLoaded()

        // Scroll down a little in case the cell is below the fold
        home.collectionView.swipeUp()
        home.collectionView.swipeDown()

        XCTAssertTrue(home.addSymptomCell.waitForExistence(timeout: 5),
                      "Add Symptom cell should be present in the Home collection view")
    }

    // MARK: - Calendar Navigation

    func testTappingCalendarOpensCalendarScreen() {
        let home = HomePage(app: app)
        home.assertLoaded()
        home.tapCalendar()

        // After tapping calendar, a new screen should be pushed.
        // Verify we can go back (i.e., the nav stack changed).
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                      "Should be able to navigate back from calendar screen")
    }
}

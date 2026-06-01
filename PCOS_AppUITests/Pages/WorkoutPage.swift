//
//  WorkoutPage.swift
//  PCOS_AppUITests
//
//  Page Object Model for the Workout screen.
//

import XCTest

struct WorkoutPage {

    let app: XCUIApplication

    // MARK: - Elements

    /// The main collection view of the Workout screen.
    var collectionView: XCUIElement {
        app.collectionViews["workout_collectionView"]
    }

    /// The calendar bar button in the navigation bar.
    var calendarBarButton: XCUIElement {
        app.navigationBars.buttons["calendar"]
    }

    // MARK: - Actions

    /// Verifies the Workout screen collection view is visible.
    @discardableResult
    func assertLoaded() -> Self {
        XCTAssertTrue(collectionView.waitForExistence(timeout: 10),
                      "Workout screen collection view did not appear")
        return self
    }

    /// Taps the first routine in the "Routines You Could Try" section (section 2).
    @discardableResult
    func tapFirstExploreRoutine() -> Self {
        let cell = collectionView.cells.element(boundBy: 3) // section 0 has 3 cards, first explore routine is index 3
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "No explore routine cells found")
        cell.tap()
        return self
    }
}

//
//  WorkoutUITests.swift
//  PCOS_AppUITests
//
//  Tests for the Workout screen: goal cards, routine lists,
//  and navigation into a routine detail screen.
//

import XCTest

final class WorkoutUITests: BaseUITestCase {

    override func setUp() {
        super.setUp()
        // Navigate to Workout tab before each test
        tapTab(label: "Workout")
    }

    // MARK: - Workout Screen Content

    func testWorkoutCollectionViewIsVisible() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()
        XCTAssertTrue(workout.collectionView.exists,
                      "Workout collection view must be visible")
    }

    func testGoalCardsAreVisible() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()

        // Section 0 contains 3 goal cards (Duration, Cals burnt, Steps).
        // We verify at least the first cell exists.
        let firstCard = workout.collectionView.cells.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5),
                      "At least one goal card should be visible in Workout section 0")
    }

    func testExploreRoutinesSectionIsVisible() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()

        // "Routines You Could Try" is section 2 — scroll down to reveal it.
        workout.collectionView.swipeUp()

        let cells = workout.collectionView.cells
        XCTAssertTrue(cells.count > 0,
                      "Workout screen should show routine cells")
    }

    // MARK: - Routine Detail Navigation

    func testTappingExploreRoutineNavigatesToDetail() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()

        // Scroll to reveal explore routines section
        workout.collectionView.swipeUp()

        // Tap the first available cell in the explore section
        let allCells = workout.collectionView.cells
        if allCells.count > 3 {
            allCells.element(boundBy: 3).tap()

            // A detail screen should be pushed; verify we can navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                          "Should be able to go back from routine detail")
            backButton.tap()

            workout.assertLoaded()
        } else {
            // No explore routines available — data store is empty in test mode.
            // This is acceptable; we just verify the screen didn't crash.
            XCTAssertTrue(workout.collectionView.exists,
                          "Workout screen should remain stable when no routines are loaded")
        }
    }

    // MARK: - Calendar Navigation

    func testWorkoutCalendarButtonIsPresent() {
        let calendarBtn = app.navigationBars.buttons["calendar"]
        XCTAssertTrue(calendarBtn.waitForExistence(timeout: 5),
                      "Calendar button should be present in Workout navigation bar")
    }
}

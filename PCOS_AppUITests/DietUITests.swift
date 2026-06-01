//
//  DietUITests.swift
//  PCOS_AppUITests
//
//  Tests for the Diet screen: macro header visibility,
//  Add Meal button, and navigation into the meal logging flow.
//

import XCTest

final class DietUITests: BaseUITestCase {

    override func setUp() {
        super.setUp()
        // Navigate to Diet tab before each test
        tapTab(label: "Diet")
    }

    // MARK: - Diet Screen Content

    func testDietCollectionViewIsVisible() {
        let diet = DietPage(app: app)
        diet.assertLoaded()
        XCTAssertTrue(diet.collectionView.exists,
                      "Diet collection view must be visible")
    }

    func testAddMealButtonIsVisible() {
        let diet = DietPage(app: app)
        diet.assertLoaded()
        XCTAssertTrue(diet.addMealButton.waitForExistence(timeout: 5),
                      "Add Meal (+) button must be visible on the Diet screen")
    }

    // MARK: - Add Meal Flow

    func testTappingAddMealNavigatesToMealScreen() {
        let diet = DietPage(app: app)
        diet.assertLoaded()
        diet.tapAddMeal()

        // After tapping Add Meal, the AddMealViewController should be pushed.
        // Verify we land on a new screen (navigation title or back button appears).
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5),
                      "Should navigate to Add Meal screen after tapping the + button")

        // Verify we can go back to Diet
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist to return to Diet")
        backButton.tap()

        // Should be back on Diet screen
        diet.assertLoaded()
    }

    // MARK: - Calendar Navigation

    func testDietCalendarButtonIsPresent() {
        let calendarBtn = app.navigationBars.buttons["calendar"]
        XCTAssertTrue(calendarBtn.waitForExistence(timeout: 5),
                      "Calendar button should be present in Diet navigation bar")
    }
}

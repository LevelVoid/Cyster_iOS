import XCTest

final class DietUITests: BaseUITestCase {

    override func setUp() {
        super.setUp()

        tapTab(label: "Diet")
    }

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

    func testTappingAddMealNavigatesToMealScreen() {
        let diet = DietPage(app: app)
        diet.assertLoaded()
        diet.tapAddMeal()

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5),
                      "Should navigate to Add Meal screen after tapping the + button")

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist to return to Diet")
        backButton.tap()

        diet.assertLoaded()
    }

    func testDietCalendarButtonIsPresent() {
        let calendarBtn = app.navigationBars.buttons["calendar"]
        XCTAssertTrue(calendarBtn.waitForExistence(timeout: 5),
                      "Calendar button should be present in Diet navigation bar")
    }
}

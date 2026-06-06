import XCTest

struct DietPage {

    let app: XCUIApplication

    var collectionView: XCUIElement {
        app.collectionViews["diet_collectionView"]
    }

    var addMealButton: XCUIElement {
        app.buttons["diet_addMealButton"]
    }

    @discardableResult
    func assertLoaded() -> Self {
        XCTAssertTrue(collectionView.waitForExistence(timeout: 10),
                      "Diet screen collection view did not appear")
        return self
    }

    @discardableResult
    func tapAddMeal() -> Self {
        XCTAssertTrue(addMealButton.waitForExistence(timeout: 5),
                      "Add Meal button not found on Diet screen")
        addMealButton.tap()
        return self
    }
}

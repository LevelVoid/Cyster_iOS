//
//  DietPage.swift
//  PCOS_AppUITests
//
//  Page Object Model for the Diet screen.
//

import XCTest

struct DietPage {

    let app: XCUIApplication

    // MARK: - Elements

    /// The main collection view of the Diet screen.
    var collectionView: XCUIElement {
        app.collectionViews["diet_collectionView"]
    }

    /// The "+" Add Meal floating button.
    var addMealButton: XCUIElement {
        app.buttons["diet_addMealButton"]
    }

    // MARK: - Actions

    /// Verifies the Diet screen collection view is visible.
    @discardableResult
    func assertLoaded() -> Self {
        XCTAssertTrue(collectionView.waitForExistence(timeout: 10),
                      "Diet screen collection view did not appear")
        return self
    }

    /// Taps the Add Meal button and returns self for chaining.
    @discardableResult
    func tapAddMeal() -> Self {
        XCTAssertTrue(addMealButton.waitForExistence(timeout: 5),
                      "Add Meal button not found on Diet screen")
        addMealButton.tap()
        return self
    }
}

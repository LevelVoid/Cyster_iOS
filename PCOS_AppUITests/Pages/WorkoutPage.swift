import XCTest

struct WorkoutPage {

    let app: XCUIApplication

    var collectionView: XCUIElement {
        app.collectionViews["workout_collectionView"]
    }

    var calendarBarButton: XCUIElement {
        app.navigationBars.buttons["calendar"]
    }

    @discardableResult
    func assertLoaded() -> Self {
        XCTAssertTrue(collectionView.waitForExistence(timeout: 10),
                      "Workout screen collection view did not appear")
        return self
    }

    @discardableResult
    func tapFirstExploreRoutine() -> Self {
        let cell = collectionView.cells.element(boundBy: 3) 
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "No explore routine cells found")
        cell.tap()
        return self
    }
}

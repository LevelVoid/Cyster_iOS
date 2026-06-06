import XCTest

final class HomeUITests: BaseUITestCase {

    func testHomeCollectionViewIsVisible() {
        let home = HomePage(app: app)
        home.assertLoaded()
        XCTAssertTrue(home.collectionView.exists,
                      "Home screen collection view must be visible")
    }

    func testCalendarBarButtonIsPresent() {
        let home = HomePage(app: app)
        home.assertLoaded()

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

    func testAddSymptomCellExists() {
        let home = HomePage(app: app)
        home.assertLoaded()

        home.collectionView.swipeUp()
        home.collectionView.swipeDown()

        XCTAssertTrue(home.addSymptomCell.waitForExistence(timeout: 5),
                      "Add Symptom cell should be present in the Home collection view")
    }

    func testTappingCalendarOpensCalendarScreen() {
        let home = HomePage(app: app)
        home.assertLoaded()
        home.tapCalendar()

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                      "Should be able to navigate back from calendar screen")
    }
}

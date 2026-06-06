import XCTest

struct HomePage {

    let app: XCUIApplication

    var collectionView: XCUIElement {
        app.collectionViews["home_collectionView"]
    }

    var calendarBarButton: XCUIElement {
        app.navigationBars.buttons["home_calendarBarButton"]
    }

    var profileBarButton: XCUIElement {
        app.navigationBars.buttons["home_profileBarButton"]
    }

    var chatbotButton: XCUIElement {
        app.buttons["home_chatbotButton"]
    }

    var addSymptomCell: XCUIElement {
        collectionView.cells["AddSymptomCollectionViewCell"]
    }

    @discardableResult
    func assertLoaded() -> Self {
        XCTAssertTrue(collectionView.waitForExistence(timeout: 10),
                      "Home screen collection view did not appear")
        return self
    }

    @discardableResult
    func tapAddSymptom() -> Self {
        XCTAssertTrue(addSymptomCell.waitForExistence(timeout: 5),
                      "Add Symptom cell not found")
        addSymptomCell.tap()
        return self
    }

    @discardableResult
    func tapCalendar() -> Self {
        XCTAssertTrue(calendarBarButton.waitForExistence(timeout: 5),
                      "Calendar bar button not found")
        calendarBarButton.tap()
        return self
    }
}

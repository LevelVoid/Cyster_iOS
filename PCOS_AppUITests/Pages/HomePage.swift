//
//  HomePage.swift
//  PCOS_AppUITests
//
//  Page Object Model for the Home screen.
//  Encapsulates all element queries so tests stay readable.
//

import XCTest

struct HomePage {

    let app: XCUIApplication

    // MARK: - Elements

    /// The main collection view of the Home screen.
    var collectionView: XCUIElement {
        app.collectionViews["home_collectionView"]
    }

    /// The calendar bar button in the navigation bar.
    var calendarBarButton: XCUIElement {
        app.navigationBars.buttons["home_calendarBarButton"]
    }

    /// The profile bar button in the navigation bar.
    var profileBarButton: XCUIElement {
        app.navigationBars.buttons["home_profileBarButton"]
    }

    /// The chatbot floating action button.
    var chatbotButton: XCUIElement {
        app.buttons["home_chatbotButton"]
    }

    /// The "Log Symptom" / "Add Symptom" cell in the collection view.
    var addSymptomCell: XCUIElement {
        collectionView.cells["AddSymptomCollectionViewCell"]
    }

    // MARK: - Actions

    /// Verifies the Home screen collection view is visible.
    @discardableResult
    func assertLoaded() -> Self {
        XCTAssertTrue(collectionView.waitForExistence(timeout: 10),
                      "Home screen collection view did not appear")
        return self
    }

    /// Taps the Add Symptom cell and returns self for chaining.
    @discardableResult
    func tapAddSymptom() -> Self {
        XCTAssertTrue(addSymptomCell.waitForExistence(timeout: 5),
                      "Add Symptom cell not found")
        addSymptomCell.tap()
        return self
    }

    /// Taps the Calendar bar button.
    @discardableResult
    func tapCalendar() -> Self {
        XCTAssertTrue(calendarBarButton.waitForExistence(timeout: 5),
                      "Calendar bar button not found")
        calendarBarButton.tap()
        return self
    }
}

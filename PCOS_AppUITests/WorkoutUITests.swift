import XCTest

final class WorkoutUITests: BaseUITestCase {

    override func setUp() {
        super.setUp()

        tapTab(label: "Workout")
    }

    func testWorkoutCollectionViewIsVisible() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()
        XCTAssertTrue(workout.collectionView.exists,
                      "Workout collection view must be visible")
    }

    func testGoalCardsAreVisible() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()

        let firstCard = workout.collectionView.cells.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5),
                      "At least one goal card should be visible in Workout section 0")
    }

    func testExploreRoutinesSectionIsVisible() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()

        workout.collectionView.swipeUp()

        let cells = workout.collectionView.cells
        XCTAssertTrue(cells.count > 0,
                      "Workout screen should show routine cells")
    }

    func testTappingExploreRoutineNavigatesToDetail() {
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()

        workout.collectionView.swipeUp()

        let allCells = workout.collectionView.cells
        if allCells.count > 3 {
            allCells.element(boundBy: 3).tap()

            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                          "Should be able to go back from routine detail")
            backButton.tap()

            workout.assertLoaded()
        } else {

            XCTAssertTrue(workout.collectionView.exists,
                          "Workout screen should remain stable when no routines are loaded")
        }
    }

    func testWorkoutCalendarButtonIsPresent() {
        let calendarBtn = app.navigationBars.buttons["calendar"]
        XCTAssertTrue(calendarBtn.waitForExistence(timeout: 5),
                      "Calendar button should be present in Workout navigation bar")
    }
}

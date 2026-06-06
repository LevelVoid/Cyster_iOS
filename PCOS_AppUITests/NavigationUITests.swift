import XCTest

final class NavigationUITests: BaseUITestCase {

    func testAppLaunchesSuccessfully() {

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10),
                      "Tab bar should be visible after launch")
    }

    func testHomeTabLoads() {
        let home = HomePage(app: app)
        home.assertLoaded()
    }

    func testDietTabLoads() {
        tapTab(label: "Diet")
        let diet = DietPage(app: app)
        diet.assertLoaded()
    }

    func testWorkoutTabLoads() {
        tapTab(label: "Workout")
        let workout = WorkoutPage(app: app)
        workout.assertLoaded()
    }

    func testNavigatingBetweenAllTabs() {

        let home    = HomePage(app: app)
        let diet    = DietPage(app: app)
        let workout = WorkoutPage(app: app)

        home.assertLoaded()

        tapTab(label: "Diet")
        diet.assertLoaded()

        tapTab(label: "Workout")
        workout.assertLoaded()

        tapTab(label: "Today")
        home.assertLoaded()
    }
}

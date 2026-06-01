//
//  NavigationUITests.swift
//  PCOS_AppUITests
//
//  Tests that verify the main bottom tab bar works and all root screens load.
//

import XCTest

final class NavigationUITests: BaseUITestCase {

    // MARK: - App Launch

    func testAppLaunchesSuccessfully() {
        // The very fact that setUp() completed means the app launched.
        // We additionally verify a tab bar is present.
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10),
                      "Tab bar should be visible after launch")
    }

    // MARK: - Tab Navigation

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
        // Home → Diet → Workout → Home
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

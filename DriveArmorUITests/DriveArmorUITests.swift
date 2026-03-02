// DriveArmorUITests.swift
// DriveArmorUITests
//
// Basic UI test to verify the app launches and the login screen appears.

import XCTest

final class DriveArmorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchShowsLoginScreen() throws {
        let app = XCUIApplication()
        app.launch()

        // The login screen should display the app title
        let title = app.staticTexts["DriveArmor"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "Login screen should show the DriveArmor title")

        // Email and password fields should be present
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }

    func testNavigateToSignUp() throws {
        let app = XCUIApplication()
        app.launch()

        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 5))
        signUpButton.tap()

        // Sign-up form should appear
        let createButton = app.buttons["Create Account"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
    }
}

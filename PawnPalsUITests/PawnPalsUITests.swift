//
//  PawnPalsUITests.swift
//  PawnPalsUITests
//
//  Created by Christopher Gillin on 11/25/26.
//

import XCTest

final class PawnPalsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Launches the app and checks the welcome title from PawnPalsCore is on screen.
    @MainActor
    func testWelcomeScreenShowsTitle() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["Hello Chess ♞"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "The welcome title should appear after launch."
        )
    }
}

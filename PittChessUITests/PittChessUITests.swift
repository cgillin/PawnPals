//
//  PittChessUITests.swift
//  PittChessUITests
//
//  Created by Christopher Gillin on 11/25/26.
//

import XCTest

final class PittChessUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Launches the app, starts a friend game from the home screen, plays 1. e4 by
    /// tapping, checks it shows in the move list, then takes it back with Undo.
    @MainActor
    func testPlayingAndUndoingTheFirstMove() throws {
        let app = XCUIApplication()
        app.launch()

        let playFriend = app.buttons["play-friend-button"]
        XCTAssertTrue(
            playFriend.waitForExistence(timeout: 5),
            "The home screen should appear after launch."
        )
        playFriend.tap()

        let turnLabel = app.staticTexts["turn-label"]
        XCTAssertTrue(turnLabel.waitForExistence(timeout: 5), "The game should open.")
        XCTAssertEqual(turnLabel.label, "White to move")

        // Tap the e2 pawn, then the e4 square.
        app.buttons["square-e2"].tap()
        app.buttons["square-e4"].tap()

        XCTAssertEqual(app.buttons["square-e4"].label, "e4, white pawn")
        XCTAssertEqual(app.buttons["square-e2"].label, "e2, empty")
        XCTAssertEqual(turnLabel.label, "Black to move")
        XCTAssertEqual(app.buttons["move-0"].label, "Move 1, White: e4")

        // Take the move back.
        app.buttons["undo-button"].tap()

        XCTAssertEqual(app.buttons["square-e2"].label, "e2, white pawn")
        XCTAssertEqual(turnLabel.label, "White to move")
        XCTAssertFalse(app.buttons["undo-button"].isEnabled)
    }
}

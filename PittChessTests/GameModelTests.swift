import PittChessCore
import Testing

@testable import PittChess

// Tests for tapping the board (selecting, moving, deselecting) and for the
// controls around it (undo, flip each turn, new game).
// `@MainActor` because the app's code runs on the main thread by default.

@MainActor
struct GameModelTests {
    @Test func tappingYourOwnPieceSelectsItAndShowsItsMoves() throws {
        let model = GameModel()
        model.tap(try square("e2"))

        #expect(model.selectedSquare == (try square("e2")))
        #expect(model.highlightedSquares == [try square("e3"), try square("e4")])
    }

    @Test func tappingAHighlightedSquareMovesThePiece() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("e4"))

        #expect(model.game.piece(at: try square("e4")) == ChessPiece(.pawn, .white))
        #expect(model.game.sideToMove == .black)
        #expect(model.selectedSquare == nil)
        #expect(model.highlightedSquares.isEmpty)
    }

    @Test func tappingTheOpponentsPieceDoesNotSelectIt() throws {
        let model = GameModel()
        model.tap(try square("e7"))

        #expect(model.selectedSquare == nil)
    }

    @Test func tappingTheSelectedPieceAgainDeselectsIt() throws {
        let model = GameModel()
        model.tap(try square("g1"))
        model.tap(try square("g1"))

        #expect(model.selectedSquare == nil)
    }

    @Test func tappingAnotherOfYourPiecesSwitchesTheSelection() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("g1"))

        #expect(model.selectedSquare == (try square("g1")))
        #expect(model.highlightedSquares == [try square("f3"), try square("h3")])
    }

    @Test func tappingASquareThePieceCantReachDeselectsWithoutMoving() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("e5"))

        #expect(model.selectedSquare == nil)
        #expect(model.game.piece(at: try square("e2")) == ChessPiece(.pawn, .white))
        #expect(model.game.sideToMove == .white)
    }

    @Test func undoTakesBackTheMoveAndClearsTheSelection() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("e4"))
        model.tap(try square("e7"))  // Black selects a pawn, then White's move is undone.

        model.undo()

        #expect(model.game.piece(at: try square("e2")) == ChessPiece(.pawn, .white))
        #expect(model.game.sideToMove == .white)
        #expect(model.selectedSquare == nil)
    }

    @Test func withFlipEachTurnOffWhiteStaysAtTheBottom() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("e4"))

        #expect(model.game.sideToMove == .black)
        #expect(model.isBoardFlipped == false)
    }

    @Test func withFlipEachTurnOnTheBoardFacesWhoeverMoves() throws {
        let model = GameModel()
        model.flipsEachTurn = true
        #expect(model.isBoardFlipped == false)  // White to move

        model.tap(try square("e2"))
        model.tap(try square("e4"))
        #expect(model.isBoardFlipped == true)  // Black to move

        model.tap(try square("e7"))
        model.tap(try square("e5"))
        #expect(model.isBoardFlipped == false)  // White to move again
    }

    @Test func turningFlipEachTurnOnDuringBlacksTurnFacesBlackRightAway() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("e4"))

        model.flipsEachTurn = true
        #expect(model.isBoardFlipped == true)

        model.flipsEachTurn = false
        #expect(model.isBoardFlipped == false)
    }

    @Test func undoTurnsTheBoardBackToThePlayerWhoseMoveItIsAgain() throws {
        let model = GameModel()
        model.flipsEachTurn = true
        model.tap(try square("e2"))
        model.tap(try square("e4"))

        model.undo()
        #expect(model.isBoardFlipped == false)
    }

    @Test func newGameSetsUpThePiecesAndKeepsFlipEachTurnOn() throws {
        let model = GameModel()
        model.flipsEachTurn = true
        model.tap(try square("e2"))
        model.tap(try square("e4"))

        model.startNewGame()

        #expect(model.game.moveHistory.isEmpty)
        #expect(model.game.piece(at: try square("e2")) == ChessPiece(.pawn, .white))
        #expect(model.flipsEachTurn == true)
        #expect(model.isBoardFlipped == false)  // A new game starts with White to move.
    }

    // MARK: - Looking back at earlier moves

    @Test func tappingAnEarlierMoveShowsTheBoardAfterThatMove() throws {
        let model = try modelAfter(["e2", "e4", "e7", "e5", "g1", "f3"])

        model.viewMove(at: 0)

        #expect(model.isViewingEarlierMove)
        #expect(model.highlightedMoveIndex == 0)
        #expect(model.displayedGame.piece(at: try square("e5")) == nil)  // Black hasn't replied.
        #expect(model.displayedGame.piece(at: try square("g1")) == ChessPiece(.knight, .white))
        // The real game is untouched.
        #expect(model.game.piece(at: try square("f3")) == ChessPiece(.knight, .white))
    }

    @Test func boardTapsDoNothingWhileLookingBack() throws {
        let model = try modelAfter(["e2", "e4", "e7", "e5"])
        model.viewMove(at: 0)

        model.tap(try square("g1"))
        model.tap(try square("f3"))

        #expect(model.selectedSquare == nil)
        #expect(model.game.moveHistory == ["e4", "e5"])
    }

    @Test func undoIsOffWhileLookingBack() throws {
        let model = try modelAfter(["e2", "e4", "e7", "e5"])
        model.viewMove(at: 0)

        #expect(model.canUndo == false)
        model.undo()
        #expect(model.game.moveHistory == ["e4", "e5"])
    }

    @Test func backToGameShowsTheCurrentPositionAgain() throws {
        let model = try modelAfter(["e2", "e4", "e7", "e5"])
        model.viewMove(at: 0)

        model.returnToCurrentMove()

        #expect(model.isViewingEarlierMove == false)
        #expect(model.highlightedMoveIndex == 1)
        #expect(model.displayedGame.piece(at: try square("e5")) == ChessPiece(.pawn, .black))
    }

    @Test func tappingTheLatestMoveIsTheSameAsBackToGame() throws {
        let model = try modelAfter(["e2", "e4", "e7", "e5"])
        model.viewMove(at: 0)

        model.viewMove(at: 1)

        #expect(model.isViewingEarlierMove == false)
    }

    @Test func newGameStopsLookingBack() throws {
        let model = try modelAfter(["e2", "e4", "e7", "e5"])
        model.viewMove(at: 0)

        model.startNewGame()

        #expect(model.isViewingEarlierMove == false)
        #expect(model.highlightedMoveIndex == nil)
    }

    /// A new game with the given squares tapped in order.
    private func modelAfter(_ taps: [String]) throws -> GameModel {
        let model = GameModel()
        for name in taps {
            model.tap(try square(name))
        }
        return model
    }

    private func square(_ name: String) throws -> BoardSquare {
        try #require(BoardSquare(name: name))
    }
}

import PawnPalsCore
import Testing

@testable import PawnPals

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

    private func square(_ name: String) throws -> BoardSquare {
        try #require(BoardSquare(name: name))
    }
}

import PawnPalsCore
import Testing

@testable import PawnPals

// Tests for tapping the board (selecting, moving, deselecting) and for the
// buttons around it (undo, flip, new game).
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

    @Test func flipBoardTurnsTheBoardAroundAndBack() {
        let model = GameModel()
        #expect(model.isBoardFlipped == false)

        model.flipBoard()
        #expect(model.isBoardFlipped == true)

        model.flipBoard()
        #expect(model.isBoardFlipped == false)
    }

    @Test func newGameSetsUpThePiecesButKeepsTheBoardFlipped() throws {
        let model = GameModel()
        model.tap(try square("e2"))
        model.tap(try square("e4"))
        model.flipBoard()

        model.startNewGame()

        #expect(model.game.moveHistory.isEmpty)
        #expect(model.game.piece(at: try square("e2")) == ChessPiece(.pawn, .white))
        #expect(model.isBoardFlipped == true)
    }

    private func square(_ name: String) throws -> BoardSquare {
        try #require(BoardSquare(name: name))
    }
}

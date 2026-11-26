import PawnPalsCore
import Testing

@testable import PawnPals

// Tests for tapping the board: selecting, moving, and deselecting.
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

    private func square(_ name: String) throws -> BoardSquare {
        try #require(BoardSquare(name: name))
    }
}

import Observation
import PawnPalsCore

/// The game on screen, plus which square the player has tapped
/// and which way round the board is drawn.
///
/// `@Observable` means SwiftUI redraws any view that reads these properties
/// whenever they change, so the board updates by itself after every tap.
@Observable
final class GameModel {
    private(set) var game: ChessGame
    private(set) var selectedSquare: BoardSquare?
    /// When true, the board is drawn with Black at the bottom.
    private(set) var isBoardFlipped = false

    init(game: ChessGame = ChessGame()) {
        self.game = game
    }

    /// Where the selected piece can move. These squares get a dot.
    var highlightedSquares: Set<BoardSquare> {
        guard let selectedSquare else { return [] }
        return game.legalDestinations(from: selectedSquare)
    }

    /// Handles a tap on a square.
    ///
    /// - Tap one of your pieces to select it and see where it can go.
    /// - Tap a dotted square to move the selected piece there.
    /// - Tap the selected piece again, or anywhere else, to deselect.
    func tap(_ square: BoardSquare) {
        if let selectedSquare, highlightedSquares.contains(square) {
            game.move(from: selectedSquare, to: square)
            self.selectedSquare = nil
        } else if square != selectedSquare, game.piece(at: square)?.side == game.sideToMove {
            selectedSquare = square
        } else {
            selectedSquare = nil
        }
    }

    /// Takes back the last move.
    func undo() {
        game.undo()
        // The selected piece may belong to the wrong player now, so start fresh.
        selectedSquare = nil
    }

    /// Turns the board around, so the other player sees it from their side.
    func flipBoard() {
        isBoardFlipped.toggle()
    }

    /// Throws away this game and sets up the pieces again.
    /// The board stays the way round it was.
    func startNewGame() {
        game = ChessGame()
        selectedSquare = nil
    }
}

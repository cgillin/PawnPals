import Observation
import PawnPalsCore

/// The game on screen, plus which square the player has tapped
/// and whether the board turns to face whoever's move it is.
///
/// `@Observable` means SwiftUI redraws any view that reads these properties
/// whenever they change, so the board updates by itself after every tap.
@Observable
final class GameModel {
    private(set) var game: ChessGame
    private(set) var selectedSquare: BoardSquare?
    /// When on, the board turns after every move so whoever's turn it is sees it
    /// from their side. When off, White is always at the bottom.
    var flipsEachTurn = false

    /// True when the board is drawn with Black at the bottom.
    ///
    /// This is worked out each time rather than stored, so it's always right:
    /// after a move, after undo, after a new game, or when the setting is switched
    /// on halfway through a game.
    var isBoardFlipped: Bool {
        flipsEachTurn && game.sideToMove == .black
    }

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

    /// Throws away this game and sets up the pieces again.
    /// The flip-each-turn setting stays as it was.
    func startNewGame() {
        game = ChessGame()
        selectedSquare = nil
    }
}

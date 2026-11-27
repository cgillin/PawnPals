import Observation
import PawnPalsCore

/// The game on screen, plus which square the player has tapped, whether the
/// board turns to face whoever's move it is, and whether we're looking back at
/// an earlier move.
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
    /// The move being looked back at (0 is the first move), or nil when the board
    /// shows the game as it is now. Looking back never changes the real game.
    private(set) var viewedMoveIndex: Int?

    /// True while the board shows an earlier move instead of the game as it is now.
    var isViewingEarlierMove: Bool {
        viewedMoveIndex != nil
    }

    /// The game the board should draw: the real game, or a copy of it as it was
    /// right after the move being looked back at.
    var displayedGame: ChessGame {
        guard let viewedMoveIndex, let earlier = game.game(afterMoveAt: viewedMoveIndex) else {
            return game
        }
        return earlier
    }

    /// The move that's highlighted in the move list: the one being looked back at,
    /// or the latest move when looking at the game as it is now.
    var highlightedMoveIndex: Int? {
        viewedMoveIndex ?? (game.moveHistory.isEmpty ? nil : game.moveHistory.count - 1)
    }

    /// Undo only makes sense on the game as it is now, not while looking back.
    var canUndo: Bool {
        game.canUndo && !isViewingEarlierMove
    }

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
    /// - While looking back at an earlier move, taps do nothing, so the real
    ///   game can't change by accident.
    func tap(_ square: BoardSquare) {
        guard !isViewingEarlierMove else { return }
        if let selectedSquare, highlightedSquares.contains(square) {
            game.move(from: selectedSquare, to: square)
            self.selectedSquare = nil
        } else if square != selectedSquare, game.piece(at: square)?.side == game.sideToMove {
            selectedSquare = square
        } else {
            selectedSquare = nil
        }
    }

    /// Shows the board as it was right after the move at `index`.
    /// Picking the latest move goes back to the game as it is now.
    func viewMove(at index: Int) {
        guard game.game(afterMoveAt: index) != nil else { return }
        let isLatestMove = index == game.moveHistory.count - 1
        viewedMoveIndex = isLatestMove ? nil : index
        selectedSquare = nil
    }

    /// Stops looking back and shows the game as it is now.
    func returnToCurrentMove() {
        viewedMoveIndex = nil
    }

    /// Takes back the last move.
    func undo() {
        guard canUndo else { return }
        game.undo()
        // The selected piece may belong to the wrong player now, so start fresh.
        selectedSquare = nil
    }

    /// Throws away this game and sets up the pieces again.
    /// The flip-each-turn setting stays as it was.
    func startNewGame() {
        game = ChessGame()
        selectedSquare = nil
        viewedMoveIndex = nil
    }
}

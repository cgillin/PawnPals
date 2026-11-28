import Observation
import PittChessCore

/// The game on screen, plus who's playing it, which square the player has tapped,
/// whether the board turns to face whoever's move it is, and whether we're looking
/// back at an earlier move.
///
/// `@Observable` means SwiftUI redraws any view that reads these properties
/// whenever they change, so the board updates by itself after every tap.
@Observable
final class GameModel {
    private(set) var game: ChessGame
    private(set) var selectedSquare: BoardSquare?
    /// Two players on one phone, or one against a bot.
    private(set) var setup: GameSetup
    /// True if the bot couldn't choose a move, even after trying twice (for example
    /// because Stockfish didn't start). Cleared by Try Again, undo, or a new game.
    private(set) var botFailed = false
    /// Changes with every new game and every Try Again, so the view knows to ask the
    /// bot for a move even when the position looks the same as before.
    private(set) var botTurnID = 0
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
    /// Against a bot, there has to be one of your own moves to take back.
    var canUndo: Bool {
        guard !isViewingEarlierMove, game.canUndo else { return false }
        guard let botSide = setup.botSide else { return true }
        // Every game starts with White to move, so White's moves are 1st, 3rd, 5th…
        let movesPlayed = game.moveHistory.count
        let humanMovesPlayed = botSide == .black ? (movesPlayed + 1) / 2 : movesPlayed / 2
        return humanMovesPlayed > 0
    }

    /// True while it's the bot's move and it hasn't made it yet.
    var isBotsTurn: Bool {
        setup.botSide == game.sideToMove && game.outcome == nil
    }

    /// True while the game can be resigned.
    var canResign: Bool {
        game.outcome == nil
    }

    /// True before anyone has moved. Until then you can leave with the back button;
    /// after that, the way out is to finish or resign.
    var canLeaveWithoutResigning: Bool {
        game.moveHistory.isEmpty
    }

    /// True when the board is drawn with Black at the bottom.
    ///
    /// This is worked out each time rather than stored, so it's always right:
    /// after a move, after undo, after a new game, or when the setting is switched
    /// on halfway through a game. Against a bot, your side is always at the bottom.
    var isBoardFlipped: Bool {
        if case .bot(_, let humanSide) = setup { return humanSide == .black }
        return flipsEachTurn && game.sideToMove == .black
    }

    /// Builds the bot for a rating. The app hands in one that uses
    /// Stockfish; previews and tests use a pretend one that moves instantly.
    private let makeOpponent: (Int) -> any Opponent
    private var opponent: (any Opponent)?

    /// The shortest time a bot takes to move. Stockfish often answers in a fraction of
    /// a second, and a reply that appears instantly feels abrupt, as if the bot didn't
    /// look at your move. Tests set this to zero.
    private let botThinkingTime: Duration

    init(
        game: ChessGame = ChessGame(), setup: GameSetup = .passAndPlay,
        botThinkingTime: Duration = .milliseconds(800),
        makeOpponent: @escaping (Int) -> any Opponent = { FirstLegalMoveOpponent(rating: $0) }
    ) {
        self.game = game
        self.setup = setup
        self.botThinkingTime = botThinkingTime
        self.makeOpponent = makeOpponent
        opponent = Self.opponent(for: setup, using: makeOpponent)
    }

    private static func opponent(
        for setup: GameSetup, using makeOpponent: (Int) -> any Opponent
    ) -> (any Opponent)? {
        if case .bot(let level, _) = setup { makeOpponent(level.rating) } else { nil }
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
        guard !isViewingEarlierMove, !isBotsTurn else { return }
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

    /// Takes back the last move. Against a bot, takes back its reply too,
    /// so it's your move again.
    func undo() {
        guard canUndo else { return }
        game.undo()
        if let botSide = setup.botSide, game.sideToMove == botSide {
            game.undo()
        }
        // The selected piece may belong to the wrong player now, so start fresh.
        selectedSquare = nil
        botFailed = false
    }

    /// Gives up the game. Against a bot, you resign; with two players on one phone,
    /// the player whose turn it is resigns.
    func resign() {
        let resigningSide = setup.botSide?.opponent ?? game.sideToMove
        game.resign(resigningSide)
        selectedSquare = nil
        viewedMoveIndex = nil
    }

    /// How many times the bot tries to move before giving up and showing Try Again.
    static let botAttempts = 2

    /// Lets the bot make its move, if it's the bot's turn.
    ///
    /// The view calls this whenever the position changes. If the position changes again
    /// while the bot is thinking (say, the player pressed undo), SwiftUI cancels
    /// this, and the bot's answer for the old position is thrown away.
    ///
    /// If the bot can't come up with a legal move, it tries once more (a search can
    /// fail now and then, for example when Stockfish's answer gets lost). If that
    /// fails too, `botFailed` turns on and the screen offers Try Again or Quit.
    func playBotMove() async {
        guard isBotsTurn, let opponent, !botFailed else { return }
        let position = game
        // The pause runs while the bot thinks, so a slow answer doesn't wait any longer.
        let earliestMove = ContinuousClock.now + botThinkingTime
        for _ in 1...Self.botAttempts {
            do {
                let move = try await opponent.chooseMove(in: position)
                try await Task.sleep(until: earliestMove, clock: .continuous)
                // Make sure it's still the position the bot was thinking about, and
                // nobody resigned meanwhile.
                guard isStillBotsTurn(at: position) else { return }
                if game.move(engineMove: move) { return }
            } catch is CancellationError {
                // The position changed while it was thinking. Nothing to do.
                return
            } catch {
                // Couldn't choose a move this time. Try again, if there are tries left.
            }
        }
        guard isStillBotsTurn(at: position) else { return }
        botFailed = true
    }

    /// Asks the bot to try again after it couldn't move.
    func retryBotMove() {
        guard botFailed else { return }
        botFailed = false
        // A new ID makes the view call `playBotMove` again.
        botTurnID += 1
    }

    private func isStillBotsTurn(at position: ChessGame) -> Bool {
        !Task.isCancelled && isBotsTurn && game.fen == position.fen
    }

    /// Throws away this game and sets up the pieces again, with the same players.
    /// The flip-each-turn setting stays as it was.
    func startNewGame() {
        startNewGame(setup)
    }

    /// Starts a new game with different players.
    func startNewGame(_ newSetup: GameSetup) {
        if newSetup != setup {
            setup = newSetup
            opponent = Self.opponent(for: newSetup, using: makeOpponent)
        }
        game = ChessGame()
        selectedSquare = nil
        viewedMoveIndex = nil
        botFailed = false
        botTurnID += 1
    }
}

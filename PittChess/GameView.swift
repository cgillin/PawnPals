import PittChessCore
import SwiftUI

/// The game: board, eval bar, move list, and controls.
struct GameView: View {
    let model: GameModel
    /// The engine's opinion of the board, shared from `PittChessApp`.
    @Environment(AnalysisModel.self) private var analysis
    /// Closes this screen, going back to the home screen.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // The banner and the turn line share one spot. The minimum height fits
            // the banner, so the board doesn't jump when switching between them.
            Group {
                if let viewedMove {
                    ViewingEarlierMoveBanner(moveNumber: viewedMove.number, san: viewedMove.san) {
                        model.returnToCurrentMove()
                    }
                } else {
                    Text(statusText)
                        .font(.headline)
                        .accessibilityIdentifier("turn-label")
                }
            }
            .frame(minHeight: 36)

            // The engine's score and the material count sit just above the board.
            VStack(spacing: 8) {
                EvaluationHeaderView(
                    evaluation: analysis.evaluation,
                    materialBalance: model.displayedGame.materialBalance,
                    isFlipped: model.isBoardFlipped, isUnavailable: analysis.isUnavailable,
                    isStale: !analysis.isCurrent(for: model.displayedGame.fen))
                BoardView(model: model)
            }
            // Runs whenever the position on screen changes, and cancels the
            // previous request first, so the bar always matches the board.
            .task(id: model.displayedGame.fen) {
                await analysis.update(for: model.displayedGame)
            }
            // Whenever the real game's position changes (or a new game starts, or the
            // player taps Try Again), give the bot its turn. Undo or a new game cancels
            // a move in progress.
            .task(id: "\(model.botTurnID) \(model.game.fen)") {
                await model.playBotMove()
            }

            // The moves, with the small undo, resign, and flip buttons tucked in at the right.
            HStack {
                MoveListView(
                    rows: model.game.moveListRows,
                    highlightedMoveIndex: model.highlightedMoveIndex,
                    selectMove: model.viewMove(at:))
                GameControlsView(model: model)
            }

            // Hidden while looking back, so the card doesn't cover up the past.
            if let outcome = model.game.outcome, !model.isViewingEarlierMove {
                GameOverView(
                    outcome: outcome, returnHome: { dismiss() },
                    startNewGame: { model.startNewGame() })
            } else if model.botFailed {
                BotFailedView(quit: { dismiss() }, tryAgain: { model.retryBotMove() })
            }

            // Pushes everything up, so the board stays put when the game-over card appears.
            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        // The back button (and the swipe from the edge) only works before the first
        // move. After that you leave by finishing or resigning, then tapping Return.
        .navigationBarBackButtonHidden(!model.canLeaveWithoutResigning)
    }

    private var title: String {
        if case .bot(let level, _) = model.setup { return "\(level.name) Bot" }
        return "Friend Game"
    }

    /// The move being looked back at, split into its number ("2." for White,
    /// "2…" for Black) and its notation, or nil when the board shows the game as it is now.
    private var viewedMove: (number: String, san: String)? {
        guard let index = model.viewedMoveIndex else { return nil }
        for row in model.game.moveListRows {
            if let white = row.white, white.index == index { return ("\(row.number).", white.san) }
            if let black = row.black, black.index == index { return ("\(row.number)…", black.san) }
        }
        return nil
    }

    /// Whose turn it is, or "Game over".
    private var statusText: String {
        if model.game.outcome != nil { return "Game over" }
        if case .bot = model.setup {
            if model.botFailed { return "The bot couldn't move" }
            return model.isBotsTurn ? "Bot is thinking…" : "Your move"
        }
        return model.game.sideToMove == .white ? "White to move" : "Black to move"
    }
}

#Preview("Friend game") {
    NavigationStack {
        GameView(model: GameModel())
    }
    .environment(AnalysisModel.preview(showing: .centipawns(20)))
}

#Preview("Against a bot") {
    // The pretend bot answers instantly with the first legal move it finds.
    NavigationStack {
        GameView(model: GameModel(setup: .bot(level: .advanced, humanSide: .black)))
    }
    .environment(AnalysisModel.preview(showing: .centipawns(30)))
}

#Preview("Checkmate") {
    NavigationStack {
        GameView(model: foolsMateModel())
    }
    .environment(AnalysisModel.preview(showing: .mate(winner: .black, moves: 0)))
}

/// The fastest checkmate there is: 1. f3 e5 2. g4 Qh4#
private func foolsMateModel() -> GameModel {
    let model = GameModel()
    for name in ["f2", "f3", "e7", "e5", "g2", "g4", "d8", "h4"] {
        if let square = BoardSquare(name: name) {
            model.tap(square)
        }
    }
    return model
}

//
//  ContentView.swift
//  PawnPals
//
//  Created by Christopher Gillin on 11/25/26.
//

import PawnPalsCore
import SwiftUI

struct ContentView: View {
    /// `@State` keeps the same game alive while the screen redraws.
    @State private var model: GameModel

    /// Previews pass in a game that's already under way; the app starts a new one.
    init(model: GameModel = GameModel()) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.tint)
                    // Decorative only, so VoiceOver skips it and reads the title.
                    .accessibilityHidden(true)
                Text(Greeting.title)
            }
            .font(.title)

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

            BoardView(model: model)

            // The moves, with the small undo and flip buttons tucked in at the right.
            HStack {
                MoveListView(
                    rows: model.game.moveListRows,
                    highlightedMoveIndex: model.highlightedMoveIndex,
                    selectMove: model.viewMove(at:))
                GameControlsView(model: model)
            }

            // Hidden while looking back, so the card doesn't cover up the past.
            if let outcome = model.game.outcome, !model.isViewingEarlierMove {
                GameOverView(outcome: outcome) {
                    model.startNewGame()
                }
            }

            // Pushes everything up, so the board stays put when the game-over card appears.
            Spacer(minLength: 0)
        }
        .padding()
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
        return model.game.sideToMove == .white ? "White to move" : "Black to move"
    }
}

#Preview("New game") {
    ContentView()
}

#Preview("Checkmate") {
    ContentView(model: foolsMateModel())
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

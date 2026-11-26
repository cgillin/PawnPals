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

            Text(statusText)
                .font(.headline)
                .accessibilityIdentifier("turn-label")

            BoardView(model: model)

            // The moves, with the small undo and flip buttons tucked in at the right.
            HStack {
                MoveListView(rows: model.game.moveListRows)
                GameControlsView(model: model)
            }

            if let outcome = model.game.outcome {
                GameOverView(outcome: outcome) {
                    model.startNewGame()
                }
            }

            // Pushes everything up, so the board stays put when the game-over card appears.
            Spacer(minLength: 0)
        }
        .padding()
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

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
    @State private var model = GameModel()

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
        }
        .padding()
    }

    /// Whose turn it is, or how the game ended.
    private var statusText: String {
        switch model.game.outcome {
        case .checkmate(winner: .white): "Checkmate! White wins"
        case .checkmate(winner: .black): "Checkmate! Black wins"
        case .draw: "It's a draw"
        case nil: model.game.sideToMove == .white ? "White to move" : "Black to move"
        }
    }
}

#Preview {
    ContentView()
}

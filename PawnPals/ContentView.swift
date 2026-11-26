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

            Text(model.game.sideToMove == .white ? "White to move" : "Black to move")
                .font(.headline)
                .accessibilityIdentifier("turn-label")

            BoardView(model: model)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

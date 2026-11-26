import PawnPalsCore
import SwiftUI

/// The buttons under the board: take back a move and turn the board around.
struct GameControlsView: View {
    let model: GameModel

    var body: some View {
        HStack(spacing: 24) {
            Button("Undo", systemImage: "arrow.uturn.backward") {
                model.undo()
            }
            .disabled(!model.game.canUndo)
            .accessibilityIdentifier("undo-button")

            Button("Flip Board", systemImage: "arrow.up.arrow.down") {
                model.flipBoard()
            }
            .accessibilityIdentifier("flip-button")
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    GameControlsView(model: GameModel())
}

import PawnPalsCore
import SwiftUI

/// The small icon buttons under the board: take back a move, and a switch that
/// turns the board to face whoever's turn it is.
struct GameControlsView: View {
    /// `@Bindable` lets this view hand out a two-way connection (`$model.flipsEachTurn`)
    /// to a property of an `@Observable` model, so the toggle can switch it on and off.
    @Bindable var model: GameModel

    var body: some View {
        HStack(spacing: 8) {
            Button("Undo", systemImage: "arrow.uturn.backward") {
                model.undo()
            }
            .tint(.secondary)
            .disabled(!model.game.canUndo)
            .accessibilityIdentifier("undo-button")

            // `.button` style draws the toggle as a button that's tinted while it's on.
            Toggle("Flip Each Turn", systemImage: "arrow.up.arrow.down", isOn: $model.flipsEachTurn)
                .toggleStyle(.button)
                // Grey while off, blue while on, so you can see at a glance that it's on.
                .tint(model.flipsEachTurn ? .accentColor : .secondary)
                .accessibilityIdentifier("flip-toggle")
        }
        // Icons only on screen. The text is still there for VoiceOver,
        // which reads "Undo" and "Flip Each Turn".
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

#Preview("Flip each turn off") {
    GameControlsView(model: GameModel())
}

#Preview("Flip each turn on") {
    let model = GameModel()
    model.flipsEachTurn = true
    return GameControlsView(model: model)
}

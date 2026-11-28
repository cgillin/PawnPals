import PittChessCore
import SwiftUI

/// The small icon buttons beside the move list: take back a move, resign, and (when
/// two people share the phone) a switch that turns the board to face whoever's turn it is.
struct GameControlsView: View {
    /// `@Bindable` lets this view hand out a two-way connection (`$model.flipsEachTurn`)
    /// to a property of an `@Observable` model, so the toggle can switch it on and off.
    @Bindable var model: GameModel
    /// True while asking "Resign this game?".
    @State private var isConfirmingResign = false

    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.undo()
            } label: {
                // Dark when you can undo, faint when you can't, so the difference is clear.
                IconButtonLabel(
                    systemImage: "arrow.uturn.backward",
                    color: model.canUndo ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary),
                    background: .fill.tertiary)
            }
            .disabled(!model.canUndo)
            .accessibilityLabel("Undo")
            .accessibilityIdentifier("undo-button")

            Button {
                isConfirmingResign = true
            } label: {
                IconButtonLabel(
                    systemImage: "flag.fill",
                    color: model.canResign ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary),
                    background: .fill.tertiary)
            }
            .disabled(!model.canResign)
            .accessibilityLabel("Resign")
            .accessibilityIdentifier("resign-button")
            .confirmationDialog(
                "Resign this game?", isPresented: $isConfirmingResign, titleVisibility: .visible
            ) {
                Button("Resign", role: .destructive) { model.resign() }
            }

            // Against a bot, your side always stays at the bottom.
            if model.setup == .passAndPlay {
                flipToggle
            }
        }
        // We draw our own look, so the button style shouldn't add another.
        .buttonStyle(.plain)
    }

    private var flipToggle: some View {
        Toggle(isOn: $model.flipsEachTurn) {
            // Blue while on, grey while off, so you can see at a glance that it's on.
            IconButtonLabel(
                systemImage: "arrow.up.arrow.down",
                color: model.flipsEachTurn
                    ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary),
                background: model.flipsEachTurn
                    ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                    : AnyShapeStyle(.fill.tertiary))
        }
        .toggleStyle(.button)
        .accessibilityLabel("Flip Each Turn")
        .accessibilityIdentifier("flip-toggle")
    }
}

/// An icon on a small circle, inside a larger invisible square that catches taps.
///
/// Apple recommends tap targets of at least 44 points. The circle is drawn smaller
/// so the buttons stay quiet, but a tap anywhere in the 44-point square counts.
private struct IconButtonLabel<Background: ShapeStyle>: View {
    let systemImage: String
    let color: AnyShapeStyle
    let background: Background

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            // The circle is a fixed size, so stop the icon growing past it at the
            // largest text sizes. VoiceOver still reads the button's name.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(background, in: .circle)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
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

#Preview("Against a bot") {
    GameControlsView(model: GameModel(setup: .bot(level: .advanced, humanSide: .white)))
}

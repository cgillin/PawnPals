import PawnPalsCore
import SwiftUI

/// The 8×8 board. Rank 8 is at the top and rank 1 at the bottom,
/// so White plays up the screen.
struct BoardView: View {
    let model: GameModel

    var body: some View {
        // Work out the selected piece's moves once per redraw, not once per square.
        let highlighted = model.highlightedSquares

        VStack(spacing: 0) {
            ForEach((0..<8).reversed(), id: \.self) { rank in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { file in
                        if let square = BoardSquare(file: file, rank: rank) {
                            squareButton(for: square, isHighlighted: highlighted.contains(square))
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func squareButton(for square: BoardSquare, isHighlighted: Bool) -> some View {
        let piece = model.game.piece(at: square)
        let isSelected = model.selectedSquare == square

        return Button {
            model.tap(square)
        } label: {
            SquareView(
                square: square, piece: piece, isSelected: isSelected, isHighlighted: isHighlighted)
        }
        .buttonStyle(.plain)
        // VoiceOver reads e.g. "e2, white pawn, selected".
        .accessibilityLabel("\(square.name), \(piece?.spokenName ?? "empty")")
        .accessibilityValue(isSelected ? "selected" : isHighlighted ? "can move here" : "")
        .accessibilityIdentifier("square-\(square.name)")
    }
}

#Preview("Start of the game") {
    BoardView(model: GameModel())
        .padding()
}

#Preview("Knight selected") {
    BoardView(model: knightSelectedModel())
        .padding()
}

/// A game after 1. e4 e5 with White's g1 knight selected, to preview the highlights.
private func knightSelectedModel() -> GameModel {
    let model = GameModel()
    let taps = ["e2", "e4", "e7", "e5", "g1"]
    for name in taps {
        if let square = BoardSquare(name: name) {
            model.tap(square)
        }
    }
    return model
}

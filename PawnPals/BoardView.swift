import PawnPalsCore
import SwiftUI

/// The 8×8 board. Normally rank 8 is at the top and rank 1 at the bottom,
/// so White plays up the screen. Flipped, it's the other way round and Black plays up.
struct BoardView: View {
    let model: GameModel

    var body: some View {
        // Work out the selected piece's moves once per redraw, not once per square.
        let highlighted = model.highlightedSquares
        // Top row first, left column first. Flipping reverses both, like turning the board around.
        let ranks: [Int] = model.isBoardFlipped ? Array(0..<8) : Array((0..<8).reversed())
        let files: [Int] = model.isBoardFlipped ? Array((0..<8).reversed()) : Array(0..<8)

        VStack(spacing: 0) {
            ForEach(ranks, id: \.self) { rank in
                HStack(spacing: 0) {
                    ForEach(files, id: \.self) { file in
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

#Preview("Flip each turn, Black to move") {
    BoardView(model: flippedModel())
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

/// Flip each turn is on and White has played 1. e4, so the board faces Black.
private func flippedModel() -> GameModel {
    let model = GameModel()
    model.flipsEachTurn = true
    for name in ["e2", "e4"] {
        if let square = BoardSquare(name: name) {
            model.tap(square)
        }
    }
    return model
}

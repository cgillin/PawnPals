import PawnPalsCore
import SwiftUI

/// Draws one square: its color, the piece on it, and any highlight.
struct SquareView: View {
    let square: BoardSquare
    let piece: ChessPiece?
    let isSelected: Bool
    /// True when the selected piece can move here.
    let isHighlighted: Bool
    /// True when the last move started or ended here.
    var isLastMove = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            ZStack {
                Rectangle()
                    .fill(square.isLight ? Self.lightSquare : Self.darkSquare)

                if isLastMove {
                    // A softer tint than "selected", so you can tell them apart.
                    Rectangle().fill(.yellow.opacity(0.25))
                }

                if isSelected {
                    Rectangle().fill(.yellow.opacity(0.45))
                }

                if let piece {
                    Text(piece.symbol)
                        .font(.system(size: size * 0.8))
                        .foregroundStyle(piece.side == .white ? .white : .black)
                        // An outline so white pieces show up on light squares.
                        .shadow(color: piece.side == .white ? .black : .clear, radius: 1)
                }

                if isHighlighted {
                    if piece == nil {
                        // A dot on an empty square you can move to.
                        Circle()
                            .fill(.black.opacity(0.25))
                            .frame(width: size * 0.3, height: size * 0.3)
                    } else {
                        // A ring around a piece you can capture.
                        Circle()
                            .stroke(.black.opacity(0.3), lineWidth: size * 0.08)
                            .padding(size * 0.04)
                    }
                }
            }
        }
    }

    private static let lightSquare = Color(red: 0.93, green: 0.85, blue: 0.73)
    private static let darkSquare = Color(red: 0.71, green: 0.53, blue: 0.39)
}

#Preview("Square states") {
    HStack(spacing: 0) {
        if let e4 = BoardSquare(name: "e4"), let d4 = BoardSquare(name: "d4") {
            SquareView(
                square: e4, piece: ChessPiece(.knight, .white), isSelected: false,
                isHighlighted: false)
            SquareView(
                square: d4, piece: ChessPiece(.knight, .black), isSelected: true,
                isHighlighted: false)
            SquareView(square: e4, piece: nil, isSelected: false, isHighlighted: true)
            SquareView(
                square: d4, piece: ChessPiece(.queen, .black), isSelected: false,
                isHighlighted: true)
        }
    }
    .frame(width: 320, height: 80)
}

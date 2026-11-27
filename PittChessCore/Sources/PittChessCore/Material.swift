extension ChessPiece.Kind {
    /// The usual beginner's count of what a piece is worth, in pawns.
    /// Kings can't be captured, so they count 0.
    public var materialValue: Int {
        switch self {
        case .pawn: 1
        case .knight, .bishop: 3
        case .rook: 5
        case .queen: 9
        case .king: 0
        }
    }
}

extension ChessGame {
    /// Who has more pieces, by value: White's total minus Black's, in pawns.
    ///
    /// +3 means White is up a knight's worth; -1 means Black is up a pawn.
    /// This is simple counting, not the engine's opinion: being up material
    /// doesn't always mean winning.
    public var materialBalance: Int {
        var balance = 0
        for rank in 0..<8 {
            for file in 0..<8 {
                guard let square = BoardSquare(file: file, rank: rank),
                    let piece = piece(at: square)
                else { continue }
                let value = piece.kind.materialValue
                balance += piece.side == .white ? value : -value
            }
        }
        return balance
    }
}

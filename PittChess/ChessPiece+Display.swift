import PittChessCore

/// How pieces look and sound in the app. This is presentation, so it lives in
/// the app target, not in PittChessCore.
extension ChessPiece {
    /// The chess symbol to draw, like ♞.
    ///
    /// Both sides use the solid symbols; the view colors them white or black.
    /// The invisible "\u{FE0E}" asks iOS to draw a plain symbol, not an emoji
    /// (without it, ♟ shows up as a colored emoji).
    var symbol: String {
        let base =
            switch kind {
            case .pawn: "♟"
            case .knight: "♞"
            case .bishop: "♝"
            case .rook: "♜"
            case .queen: "♛"
            case .king: "♚"
            }
        return base + "\u{FE0E}"
    }

    /// What VoiceOver says, like "white knight".
    var spokenName: String {
        let sideName = side == .white ? "white" : "black"
        let kindName =
            switch kind {
            case .pawn: "pawn"
            case .knight: "knight"
            case .bishop: "bishop"
            case .rook: "rook"
            case .queen: "queen"
            case .king: "king"
            }
        return "\(sideName) \(kindName)"
    }
}

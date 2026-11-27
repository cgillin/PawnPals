import PawnPalsCore

/// How moves are written on screen. Presentation, so it lives in the app target;
/// PawnPalsCore keeps standard notation (SAN), which engines and saved games need.
enum MoveNotation {
    /// One piece of a move as shown on screen: a piece picture, or plain text.
    /// Keeping them apart lets the view draw pictures larger than the letters.
    enum Part: Equatable {
        case picture(String)
        case text(String)
    }

    /// Standard notation split into piece pictures and text, like
    /// "Nxe5" → [♞, "xe5"], "e4" → [♟, "e4"], or "a8=Q+" → [♟, "a8=", ♛, "+"].
    /// A beginner may not know that N means knight, but they know the horse shape.
    ///
    /// - Piece moves start with a capital letter (K Q R B N), which becomes its picture.
    /// - Pawn moves have no letter: they start with the column, a small letter a–h.
    ///   They get a pawn picture in front.
    /// - Castling ("O-O") stays as it is.
    static func parts(of san: String) -> [Part] {
        var parts: [Part] = []
        if let first = san.first, columnLetters.contains(first) {
            parts.append(.picture(symbol(for: .pawn)))
        }
        var text = ""
        for character in san {
            if let kind = pieceKinds[character] {
                if !text.isEmpty { parts.append(.text(text)) }
                text = ""
                parts.append(.picture(symbol(for: kind)))
            } else {
                text.append(character)
            }
        }
        if !text.isEmpty { parts.append(.text(text)) }
        return parts
    }

    /// The solid picture for both sides, like the board uses.
    private static func symbol(for kind: ChessPiece.Kind) -> String {
        ChessPiece(kind, .white).symbol
    }

    private static let pieceKinds: [Character: ChessPiece.Kind] = [
        "K": .king, "Q": .queen, "R": .rook, "B": .bishop, "N": .knight,
    ]

    private static let columnLetters: Set<Character> = ["a", "b", "c", "d", "e", "f", "g", "h"]
}

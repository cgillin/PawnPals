/// One numbered row of the move list, like "1. e4 e5".
///
/// `white` is nil when the game started with Black to move (written "1. … e5"),
/// and `black` is nil while Black hasn't replied yet.
public struct MoveListRow: Equatable, Sendable {
    public let number: Int
    public let white: Entry?
    public let black: Entry?

    /// One move in the list: its notation, and where it comes in the game,
    /// so tapping it can show the board as it was right after that move.
    public struct Entry: Equatable, Sendable {
        /// 0 for the first move of the game, 1 for the second, and so on.
        public let index: Int
        /// The move in standard chess notation, like "Nf3".
        public let san: String

        public init(index: Int, san: String) {
            self.index = index
            self.san = san
        }
    }

    public init(number: Int, white: Entry?, black: Entry?) {
        self.number = number
        self.white = white
        self.black = black
    }
}

/// The two squares a move went between, used to tint them on the board.
/// For castling, these are the king's squares.
public struct MoveSquares: Equatable, Sendable {
    public let from: BoardSquare
    public let to: BoardSquare

    public init(from: BoardSquare, to: BoardSquare) {
        self.from = from
        self.to = to
    }
}

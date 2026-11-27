/// Which player: white or black.
///
/// Named `Side` rather than `Color` so it never gets mixed up with SwiftUI's `Color`.
public enum Side: Sendable {
    case white
    case black

    /// The other player.
    public var opponent: Side {
        self == .white ? .black : .white
    }
}

/// How a finished game ended.
public enum GameOutcome: Equatable, Sendable {
    /// One side checkmated the other.
    case checkmate(winner: Side)
    /// Nobody won, for the given reason.
    case draw(DrawReason)

    /// Why a game ended in a draw.
    public enum DrawReason: Sendable {
        /// The player to move isn't in check but has no legal move.
        case stalemate
        /// Neither side has enough pieces left to checkmate, like king against king.
        case insufficientMaterial
        /// Fifty moves each with no capture and no pawn move.
        case fiftyMoveRule
        /// The same position came up three times.
        case repetition
        /// Both players agreed to a draw.
        case agreement
    }
}

/// A chess piece: what kind it is and whose it is.
public struct ChessPiece: Hashable, Sendable {
    public enum Kind: Sendable, CaseIterable {
        case pawn
        case knight
        case bishop
        case rook
        case queen
        case king
    }

    public let kind: Kind
    public let side: Side

    public init(_ kind: Kind, _ side: Side) {
        self.kind = kind
        self.side = side
    }
}

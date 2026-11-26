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

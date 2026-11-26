import ChessKit

/// A game of chess between two players: the pieces, whose turn it is, and the rules.
///
/// ChessKit is the referee for how pieces move, including check and pins.
/// ChessGame adds the one rule ChessKit leaves to us: you can only move your own
/// pieces, and only on your turn. The rest of the app talks to ChessGame using our
/// own simple types (`BoardSquare`, `ChessPiece`, `Side`), never ChessKit's.
public struct ChessGame: Sendable {
    private var board: Board

    /// A new game from the standard starting position.
    public init() {
        board = Board(position: .standard)
    }

    /// A game starting from a FEN position, or nil if the FEN isn't valid.
    ///
    /// FEN is the standard one-line way to write down a chess position,
    /// e.g. "4k3/8/8/8/8/8/8/4K3 w - - 0 1" is just two kings with white to move.
    public init?(fen: String) {
        guard let position = Position(fen: fen) else { return nil }
        board = Board(position: position)
    }

    /// The player whose turn it is.
    public var sideToMove: Side {
        Self.side(from: board.position.sideToMove)
    }

    /// How the game ended, or nil while it's still being played.
    public var outcome: GameOutcome? {
        switch board.state {
        case .checkmate(let loser): .checkmate(winner: Self.side(from: loser).opponent)
        case .draw: .draw
        case .active, .check, .promotion: nil
        }
    }

    /// The piece on a square, or nil if it's empty.
    public func piece(at square: BoardSquare) -> ChessPiece? {
        board.position.piece(at: Self.chessKitSquare(square)).map(Self.piece(from:))
    }

    /// The squares the piece on `square` can legally move to right now.
    ///
    /// Empty if the game is over, the square is empty, the piece belongs to the
    /// player who isn't on move, or the piece has no legal moves (for example, it's pinned).
    public func legalDestinations(from square: BoardSquare) -> Set<BoardSquare> {
        guard outcome == nil, let piece = piece(at: square), piece.side == sideToMove else {
            return []
        }
        let destinations = board.legalMoves(forPieceAt: Self.chessKitSquare(square))
        return Set(destinations.compactMap { BoardSquare(name: $0.notation) })
    }

    /// Moves a piece if the move is legal and it's that player's turn.
    ///
    /// A pawn reaching the last rank always becomes a queen for now;
    /// choosing a different piece comes in a later step.
    ///
    /// - returns: `true` if the move was made, `false` if it was rejected
    ///   (in which case nothing changes).
    @discardableResult
    public mutating func move(from start: BoardSquare, to end: BoardSquare) -> Bool {
        guard legalDestinations(from: start).contains(end),
            board.move(pieceAt: Self.chessKitSquare(start), to: Self.chessKitSquare(end)) != nil
        else { return false }

        if case .promotion(let promotionMove) = board.state {
            board.completePromotion(of: promotionMove, to: .queen)
        }
        return true
    }

    // MARK: - Translating between our types and ChessKit's

    private static func chessKitSquare(_ square: BoardSquare) -> Square {
        Square(square.name)
    }

    private static func side(from color: Piece.Color) -> Side {
        color == .white ? .white : .black
    }

    private static func piece(from piece: Piece) -> ChessPiece {
        let kind: ChessPiece.Kind =
            switch piece.kind {
            case .pawn: .pawn
            case .knight: .knight
            case .bishop: .bishop
            case .rook: .rook
            case .queen: .queen
            case .king: .king
            }
        return ChessPiece(kind, side(from: piece.color))
    }
}

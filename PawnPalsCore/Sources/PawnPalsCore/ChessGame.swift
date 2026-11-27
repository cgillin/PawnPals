import ChessKit

/// A game of chess between two players: the pieces, whose turn it is, and the rules.
///
/// ChessKit is the referee for how pieces move, including check and pins.
/// ChessGame adds the one rule ChessKit leaves to us: you can only move your own
/// pieces, and only on your turn. The rest of the app talks to ChessGame using our
/// own simple types (`BoardSquare`, `ChessPiece`, `Side`), never ChessKit's.
public struct ChessGame: Sendable {
    private var board: Board

    /// Every move played so far, oldest first.
    private var history: [PlayedMove] = []

    /// One move, written down, plus a copy of the board from just before it.
    ///
    /// Keeping the whole earlier board (not just the move) makes undo simple and exact:
    /// it brings back castling rights, en passant chances, and repetition counts too.
    /// `Board` is a struct, so each copy is independent.
    private struct PlayedMove: Sendable {
        let boardBefore: Board
        let san: String
        let squares: MoveSquares
    }

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

    /// The current position written as FEN, the format chess engines read.
    public var fen: String {
        board.position.fen
    }

    /// How the game ended, or nil while it's still being played.
    public var outcome: GameOutcome? {
        switch board.state {
        case .checkmate(let loser): .checkmate(winner: Self.side(from: loser).opponent)
        case .draw(let reason): .draw(Self.drawReason(from: reason))
        case .active, .check, .promotion: nil
        }
    }

    /// The moves played so far, oldest first, in standard chess notation (SAN),
    /// like `["e4", "e5", "Nf3"]`.
    public var moveHistory: [String] {
        history.map(\.san)
    }

    /// The moves grouped into numbered rows for the move list: "1. e4 e5", "2. Nf3 …".
    public var moveListRows: [MoveListRow] {
        var rows: [MoveListRow] = []
        for (index, played) in history.enumerated() {
            let number = played.boardBefore.position.clock.fullmoves
            let entry = MoveListRow.Entry(index: index, san: played.san)
            if played.boardBefore.position.sideToMove == .white {
                rows.append(MoveListRow(number: number, white: entry, black: nil))
            } else if let last = rows.last, last.number == number, last.black == nil {
                rows[rows.count - 1] = MoveListRow(number: number, white: last.white, black: entry)
            } else {
                // Black moved first, so this row has no White move.
                rows.append(MoveListRow(number: number, white: nil, black: entry))
            }
        }
        return rows
    }

    /// The squares the most recent move went between, or nil before the first move.
    public var lastMove: MoveSquares? {
        history.last?.squares
    }

    /// The game as it stood right after the move at `index` (0 is the first move),
    /// or nil if there's no such move.
    ///
    /// This is a separate copy for looking back at: the real game isn't changed.
    public func game(afterMoveAt index: Int) -> ChessGame? {
        guard history.indices.contains(index) else { return nil }
        var earlier = self
        earlier.history = Array(history.prefix(index + 1))
        // The board right after this move is the board saved before the next one.
        // For the latest move, it's the current board.
        if history.indices.contains(index + 1) {
            earlier.board = history[index + 1].boardBefore
        }
        return earlier
    }

    /// True when there's a move to take back.
    public var canUndo: Bool {
        !history.isEmpty
    }

    /// Takes back the last move, putting the board exactly as it was before it.
    ///
    /// - returns: `true` if a move was taken back, `false` if there were no moves.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let last = history.popLast() else { return false }
        board = last.boardBefore
        return true
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
        let boardBefore = board
        guard legalDestinations(from: start).contains(end),
            var chessKitMove = board.move(
                pieceAt: Self.chessKitSquare(start), to: Self.chessKitSquare(end))
        else { return false }

        if case .promotion(let promotionMove) = board.state {
            chessKitMove = board.completePromotion(of: promotionMove, to: .queen)
        }
        history.append(
            PlayedMove(
                boardBefore: boardBefore, san: chessKitMove.san,
                squares: MoveSquares(from: start, to: end)))
        return true
    }

    // MARK: - Translating between our types and ChessKit's

    private static func chessKitSquare(_ square: BoardSquare) -> Square {
        Square(square.name)
    }

    private static func side(from color: Piece.Color) -> Side {
        color == .white ? .white : .black
    }

    private static func drawReason(from reason: Board.State.DrawReason) -> GameOutcome.DrawReason {
        switch reason {
        case .stalemate: .stalemate
        case .insufficientMaterial: .insufficientMaterial
        case .fiftyMoves: .fiftyMoveRule
        case .repetition: .repetition
        case .agreement: .agreement
        }
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

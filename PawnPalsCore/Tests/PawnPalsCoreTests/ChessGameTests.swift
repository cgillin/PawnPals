import PawnPalsCore
import Testing

// Tests for ChessGame: the board, whose turn it is, and the rules.
// Each test is named after the chess idea it checks.

@Test func newGameStartsWithWhiteToMove() {
    let game = ChessGame()
    #expect(game.sideToMove == .white)
}

@Test func newGameHasPiecesOnTheirStartingSquares() throws {
    let game = ChessGame()
    #expect(game.piece(at: try #require(BoardSquare(name: "e1"))) == ChessPiece(.king, .white))
    #expect(game.piece(at: try #require(BoardSquare(name: "d8"))) == ChessPiece(.queen, .black))
    #expect(game.piece(at: try #require(BoardSquare(name: "e4"))) == nil)
}

@Test func pawnOnStartingSquareCanMoveOneOrTwoSquares() throws {
    let game = ChessGame()
    let destinations = game.legalDestinations(from: try #require(BoardSquare(name: "e2")))
    #expect(destinations == squares("e3", "e4"))
}

@Test func knightCanJumpOverPawnsAtTheStart() throws {
    let game = ChessGame()
    let destinations = game.legalDestinations(from: try #require(BoardSquare(name: "b1")))
    #expect(destinations == squares("a3", "c3"))
}

@Test func blackPiecesCannotMoveOnWhitesTurn() throws {
    var game = ChessGame()
    let e7 = try #require(BoardSquare(name: "e7"))
    let e5 = try #require(BoardSquare(name: "e5"))

    #expect(game.legalDestinations(from: e7).isEmpty)
    #expect(game.move(from: e7, to: e5) == false)
    #expect(game.piece(at: e7) == ChessPiece(.pawn, .black))
}

@Test func illegalMoveIsRejectedAndNothingChanges() throws {
    var game = ChessGame()
    let e2 = try #require(BoardSquare(name: "e2"))
    let e5 = try #require(BoardSquare(name: "e5"))

    #expect(game.move(from: e2, to: e5) == false)
    #expect(game.piece(at: e2) == ChessPiece(.pawn, .white))
    #expect(game.piece(at: e5) == nil)
    #expect(game.sideToMove == .white)
}

@Test func legalMoveMovesThePieceAndPassesTheTurn() throws {
    var game = ChessGame()
    let e2 = try #require(BoardSquare(name: "e2"))
    let e4 = try #require(BoardSquare(name: "e4"))

    #expect(game.move(from: e2, to: e4) == true)
    #expect(game.piece(at: e4) == ChessPiece(.pawn, .white))
    #expect(game.piece(at: e2) == nil)
    #expect(game.sideToMove == .black)
}

@Test func pinnedKnightCannotMove() throws {
    // The white knight on e2 is pinned: the black rook on e7 would capture the king on e1.
    let game = try #require(ChessGame(fen: "4k3/4r3/8/8/8/8/4N3/4K3 w - - 0 1"))
    #expect(game.legalDestinations(from: try #require(BoardSquare(name: "e2"))).isEmpty)
}

@Test func pawnReachingTheLastRankBecomesAQueen() throws {
    var game = try #require(ChessGame(fen: "4k3/P7/8/8/8/8/8/4K3 w - - 0 1"))
    let a7 = try #require(BoardSquare(name: "a7"))
    let a8 = try #require(BoardSquare(name: "a8"))

    #expect(game.move(from: a7, to: a8) == true)
    #expect(game.piece(at: a8) == ChessPiece(.queen, .white))
    #expect(game.sideToMove == .black)
}

@Test func kingCanCastleAndTheRookJumpsOver() throws {
    var game = try #require(ChessGame(fen: "4k3/8/8/8/8/8/8/4K2R w K - 0 1"))
    let e1 = try #require(BoardSquare(name: "e1"))
    let g1 = try #require(BoardSquare(name: "g1"))

    #expect(game.legalDestinations(from: e1).contains(g1))
    #expect(game.move(from: e1, to: g1) == true)
    #expect(game.piece(at: g1) == ChessPiece(.king, .white))
    #expect(game.piece(at: try #require(BoardSquare(name: "f1"))) == ChessPiece(.rook, .white))
    #expect(game.piece(at: try #require(BoardSquare(name: "h1"))) == nil)
}

@Test func pawnCanCaptureEnPassant() throws {
    // White pawn on e5. Black pushes d7-d5 right past it, so White may capture
    // "in passing" by moving to d6, and the black pawn on d5 disappears.
    var game = try #require(ChessGame(fen: "4k3/3p4/8/4P3/8/8/8/4K3 b - - 0 1"))
    let d5 = try #require(BoardSquare(name: "d5"))
    let d6 = try #require(BoardSquare(name: "d6"))
    let e5 = try #require(BoardSquare(name: "e5"))

    #expect(game.move(from: try #require(BoardSquare(name: "d7")), to: d5) == true)
    #expect(game.legalDestinations(from: e5).contains(d6))
    #expect(game.move(from: e5, to: d6) == true)
    #expect(game.piece(at: d6) == ChessPiece(.pawn, .white))
    #expect(game.piece(at: d5) == nil)
}

@Test func checkmateEndsTheGame() throws {
    // Fool's mate: the fastest checkmate there is. 1. f3 e5 2. g4 Qh4#
    var game = ChessGame()
    let moves = [("f2", "f3"), ("e7", "e5"), ("g2", "g4"), ("d8", "h4")]
    for (from, to) in moves {
        let moved = game.move(
            from: try #require(BoardSquare(name: from)), to: try #require(BoardSquare(name: to)))
        #expect(moved == true)
    }

    #expect(game.outcome == .checkmate(winner: .black))
    #expect(game.legalDestinations(from: try #require(BoardSquare(name: "a2"))).isEmpty)
}

@Test func drawnGameAllowsNoMoreMoves() throws {
    // Just two kings: neither side can ever checkmate, so the game is a draw.
    let game = try #require(ChessGame(fen: "8/8/8/4k3/8/8/8/4K3 w - - 0 1"))

    #expect(game.outcome == .draw)
    #expect(game.legalDestinations(from: try #require(BoardSquare(name: "e1"))).isEmpty)
}

@Test func gameInProgressHasNoOutcome() {
    #expect(ChessGame().outcome == nil)
}

@Test func invalidFENIsRejected() {
    #expect(ChessGame(fen: "not a chess position") == nil)
}

@Test func squareNamesMatchFilesAndRanks() throws {
    let e4 = try #require(BoardSquare(name: "e4"))
    #expect(e4.file == 4)  // a=0, b=1, ..., e=4
    #expect(e4.rank == 3)  // rank 1 = 0, ..., rank 4 = 3
    #expect(e4.name == "e4")
    #expect(BoardSquare(name: "z9") == nil)
    #expect(BoardSquare.all.count == 64)
}

@Test func lightAndDarkSquaresAlternate() throws {
    #expect(try #require(BoardSquare(name: "a1")).isLight == false)  // a1 is always dark
    #expect(try #require(BoardSquare(name: "h1")).isLight == true)
    #expect(try #require(BoardSquare(name: "e4")).isLight == true)
}

/// Turns square names into a set, so tests can say `squares("e3", "e4")`.
private func squares(_ names: String...) -> Set<BoardSquare> {
    Set(names.compactMap { BoardSquare(name: $0) })
}

import PawnPalsCore
import Testing

// Counting material: pawn 1, knight 3, bishop 3, rook 5, queen 9.

@Test func startingPositionIsEven() {
    #expect(ChessGame().materialBalance == 0)
}

@Test func whiteUpAKnightIsPlusThree() throws {
    // Black's b8 knight is missing.
    let game = try #require(
        ChessGame(fen: "r1bqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))
    #expect(game.materialBalance == 3)
}

@Test func blackUpARookIsMinusFive() throws {
    // White's h1 rook is missing.
    let game = try #require(
        ChessGame(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBN1 w Qkq - 0 1"))
    #expect(game.materialBalance == -5)
}

@Test func tradingQueensKeepsItEven() throws {
    // Both queens are gone.
    let game = try #require(
        ChessGame(fen: "rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNB1KBNR w KQkq - 0 1"))
    #expect(game.materialBalance == 0)
}

@Test func kingsAloneAreEven() throws {
    let game = try #require(ChessGame(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1"))
    #expect(game.materialBalance == 0)
}

@Test func promotedPawnCountsAsAQueen() throws {
    // White's pawn has just become a second queen: a pawn turned into 9.
    let game = try #require(ChessGame(fen: "Q3k3/8/8/8/8/8/8/Q3K3 b - - 0 1"))
    #expect(game.materialBalance == 18)
}

@Test func capturingAPieceChangesTheCount() throws {
    // 1. e4 d5 2. exd5: White wins a pawn.
    var game = ChessGame()
    for (from, to) in [("e2", "e4"), ("d7", "d5"), ("e4", "d5")] {
        game.move(
            from: try #require(BoardSquare(name: from)), to: try #require(BoardSquare(name: to)))
    }
    #expect(game.materialBalance == 1)
}

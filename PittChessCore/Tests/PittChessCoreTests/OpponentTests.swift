import Testing

@testable import PittChessCore

// StockfishOpponent without starting Stockfish. Its games are in StockfishEngineTests.

@Test func stockfishOpponentCantGoBelowStockfishsLowestRating() {
    let opponent = StockfishOpponent(engine: StockfishEngine(), rating: 800)
    #expect(opponent.rating == EngineStrength.lowestRating)
}

@Test func stockfishOpponentKeepsARatingItSupports() {
    let opponent = StockfishOpponent(engine: StockfishEngine(), rating: 1800)
    #expect(opponent.rating == 1800)
}

@Test func pretendOpponentPlaysALegalMove() async throws {
    var game = ChessGame()
    game.move(engineMove: "e2e4")

    let move = try await FirstLegalMoveOpponent().chooseMove(in: game)

    let wasPlayed = game.move(engineMove: move)
    #expect(wasPlayed)
}

@Test func pretendOpponentHasNoMoveWhenCheckmated() async throws {
    // After Fool's Mate: White to move and already checkmated.
    let game = try #require(
        ChessGame(fen: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"))
    await #expect(throws: EngineError.noMove) {
        try await FirstLegalMoveOpponent().chooseMove(in: game)
    }
}

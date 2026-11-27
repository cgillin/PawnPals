import ChessKitEngine
import Testing

@testable import PittChessCore

// Stockfish's output occasionally reaches us cut in two. These check that a cut-off
// line can't sneak in a wrong score or a wrong move.

private func score(fromLine line: String) throws -> EngineScore? {
    guard case .info(let info) = try #require(EngineResponse(rawValue: line)) else {
        Issue.record("Not an info line: \(line)")
        return nil
    }
    return StockfishEngine.engineScore(from: info)
}

@Test func completeScoreLineIsTrusted() throws {
    let line = "info depth 12 seldepth 12 multipv 1 score cp 735 nodes 2519 pv c8g4 e4d5"
    #expect(try score(fromLine: line) == .centipawns(735))
}

@Test func scoreLineCutBeforeItsMovesIsIgnored() throws {
    // "cp 735" cut down to "cp 7": without the moves at the end, it can't be trusted.
    #expect(try score(fromLine: "info depth 12 seldepth 12 multipv 1 score cp 7") == nil)
}

@Test func gameOverScoreWithNoMovesIsTrusted() throws {
    // Stockfish's whole answer for a checkmated position: depth 0, mate 0, no moves.
    #expect(try score(fromLine: "info depth 0 score mate 0") == .mate(0))
}

@Test func boundScoresAreIgnored() throws {
    let line = "info depth 10 score cp 50 lowerbound nodes 100 pv e2e4"
    #expect(try score(fromLine: line) == nil)
}

@Test func engineMovesAreRecognized() {
    #expect(StockfishEngine.isCompleteMove("e2e4"))
    #expect(StockfishEngine.isCompleteMove("e7e8q"))
}

@Test func cutOffOrMissingMovesAreRejected() {
    #expect(!StockfishEngine.isCompleteMove("e2"))
    #expect(!StockfishEngine.isCompleteMove("(none)"))
    #expect(!StockfishEngine.isCompleteMove("e7e8k"))
    #expect(!StockfishEngine.isCompleteMove("i2e4"))
}

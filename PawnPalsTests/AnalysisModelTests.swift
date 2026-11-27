import PawnPalsCore
import Testing

@testable import PawnPals

// AnalysisModel with pretend engines, so these run instantly without Stockfish.

/// Gives the same answers, round by round, for every position, and remembers what it
/// was asked.
private actor PretendAnalyzer: PositionAnalyzer {
    let answers: [EngineAnalysis]
    private(set) var askedFENs: [String] = []

    /// One answer per round: `(depth, evaluation)`.
    init(rounds: [(depth: Int, evaluation: Evaluation)]) {
        answers = rounds.map { EngineAnalysis(evaluation: $1, bestMove: "e2e4", depth: $0) }
    }

    func start() async throws {}

    nonisolated func analyses(fen: String, depth: Int)
        -> AsyncThrowingStream<EngineAnalysis, any Error>
    {
        let (stream, continuation) = AsyncThrowingStream<EngineAnalysis, any Error>.makeStream()
        Task {
            await self.remember(fen)
            for answer in answers { continuation.yield(answer) }
            continuation.finish()
        }
        return stream
    }

    private func remember(_ fen: String) {
        askedFENs.append(fen)
    }
}

/// An engine that starts fine but whose search fails, like when Stockfish's answer
/// gets lost.
private struct FailingSearchAnalyzer: PositionAnalyzer {
    func start() async throws {}

    func analyses(fen: String, depth: Int) -> AsyncThrowingStream<EngineAnalysis, any Error> {
        AsyncThrowingStream { $0.finish(throwing: EngineError.noEvaluation) }
    }
}

/// An engine that can't start, like when its network files are missing.
private struct BrokenAnalyzer: PositionAnalyzer {
    func start() async throws {
        throw EngineError.missingNetworkFile("nn-1111cefa1111.nnue")
    }

    func analyses(fen: String, depth: Int) -> AsyncThrowingStream<EngineAnalysis, any Error> {
        AsyncThrowingStream { $0.finish(throwing: EngineError.notStarted) }
    }
}

@MainActor @Test func barEndsOnTheDeepestAnswer() async {
    let analyzer = PretendAnalyzer(rounds: [
        (5, .centipawns(10)), (8, .centipawns(25)), (12, .centipawns(35)),
    ])
    let model = AnalysisModel(analyzer: analyzer)

    await model.update(for: ChessGame())

    #expect(model.evaluation == .centipawns(35))
    #expect(await analyzer.askedFENs == [ChessGame().fen])
}

@MainActor @Test func finishedAnswerIsShownEvenIfShallow() async {
    // Shallow rounds are skipped while searching, but the engine's last word always shows.
    let shallow = AnalysisModel.firstDepthShown - 1
    let model = AnalysisModel(
        analyzer: PretendAnalyzer(rounds: [(1, .centipawns(900)), (shallow, .centipawns(-400))]))

    await model.update(for: ChessGame())

    #expect(model.evaluation == .centipawns(-400))
}

@MainActor @Test func scoreRemembersWhichPositionItIsFor() async throws {
    let model = AnalysisModel(analyzer: PretendAnalyzer(rounds: [(12, .centipawns(35))]))
    var afterE4 = ChessGame()
    afterE4.move(
        from: try #require(BoardSquare(name: "e2")), to: try #require(BoardSquare(name: "e4")))

    await model.update(for: ChessGame())

    // Right after a move, the score on screen is still the previous position's.
    #expect(model.isCurrent(for: ChessGame().fen))
    #expect(!model.isCurrent(for: afterE4.fen))
}

@MainActor @Test func oneFailedSearchDoesNotMarkTheEngineUnavailable() async {
    let model = AnalysisModel(analyzer: FailingSearchAnalyzer())

    await model.update(for: ChessGame())

    #expect(!model.isUnavailable)
    #expect(model.evaluation == nil)
}

@MainActor @Test func checkmateNeedsNoEngine() async throws {
    // After Fool's Mate (1. f3 e5 2. g4 Qh4#), Black has won.
    var game = ChessGame()
    for (from, to) in [("f2", "f3"), ("e7", "e5"), ("g2", "g4"), ("d8", "h4")] {
        game.move(
            from: try #require(BoardSquare(name: from)), to: try #require(BoardSquare(name: to)))
    }
    let analyzer = PretendAnalyzer(rounds: [(12, .centipawns(0))])
    let model = AnalysisModel(analyzer: analyzer)

    await model.update(for: game)

    #expect(model.evaluation == .mate(winner: .black, moves: 0))
    #expect(await analyzer.askedFENs.isEmpty)
}

@MainActor @Test func engineThatCantStartMarksTheBarUnavailable() async {
    let model = AnalysisModel(analyzer: BrokenAnalyzer())

    await model.update(for: ChessGame())

    #expect(model.isUnavailable)
    #expect(model.evaluation == nil)
}

@MainActor @Test func cancelledRequestDoesNotChangeTheBar() async {
    let model = AnalysisModel(analyzer: PretendAnalyzer(rounds: [(12, .centipawns(500))]))
    let request = Task { await model.update(for: ChessGame()) }
    request.cancel()
    await request.value

    // The answer arrived after the board moved on, so it's thrown away.
    #expect(model.evaluation == nil)
    #expect(!model.isUnavailable)
}

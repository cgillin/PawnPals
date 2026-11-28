import PittChessCore
import Testing

extension Tag {
    /// Tests that start the real Stockfish. Slower; skip them with `--skip StockfishEngineTests`.
    @Tag static var engine: Self
}

/// One Stockfish for every test: only one can run per process (see `StockfishEngine`).
private let sharedEngine = StockfishEngine()

private func startedEngine() async throws -> StockfishEngine {
    await MainRunLoop.keepRunning()
    try await sharedEngine.start()
    return sharedEngine
}

@Suite(.tags(.engine), .timeLimit(.minutes(1)))
struct StockfishEngineTests {
    @Test func startingPositionIsRoughlyEqual() async throws {
        let engine = try await startedEngine()
        let analysis = try await engine.analyze(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", depth: 10)

        guard case .centipawns(let centipawns) = analysis.evaluation else {
            Issue.record("Expected a centipawn score, got \(analysis.evaluation)")
            return
        }
        #expect(abs(centipawns) < 100)
        #expect(analysis.bestMove != nil)
        #expect(analysis.depth >= 10)
    }

    @Test func whiteUpAQueenIsClearlyBetterForWhite() async throws {
        // Black's queen is gone; everything else is where it started.
        let analysis = try await startedEngine().analyze(
            fen: "rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", depth: 10)
        #expect(Self.whitePointOfView(analysis.evaluation) > 500)
    }

    @Test func blackToMoveAndUpAQueenIsNegativeForWhite() async throws {
        // The sign flip, checked end to end: Black to move, Black is winning,
        // so the score we store must be negative.
        let analysis = try await startedEngine().analyze(
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNB1KBNR b KQkq - 0 1", depth: 10)
        #expect(Self.whitePointOfView(analysis.evaluation) < -500)
    }

    @Test func backRankMateInOneIsFound() async throws {
        // White plays Re8#: the black king is stuck behind its own pawns.
        let analysis = try await startedEngine().analyze(
            fen: "6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1", depth: 10)
        #expect(analysis.evaluation == .mate(winner: .white, moves: 1))
        #expect(analysis.bestMove == "e1e8")
    }

    @Test func checkmatedPositionHasNoBestMove() async throws {
        // After Fool's Mate: White to move and already checkmated.
        let analysis = try await startedEngine().analyze(
            fen: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3", depth: 10)
        #expect(analysis.evaluation == .mate(winner: .black, moves: 0))
        #expect(analysis.bestMove == nil)
    }

    @Test func brokenPositionIsRejectedBeforeReachingStockfish() async throws {
        let engine = try await startedEngine()
        await #expect(throws: EngineError.invalidPosition("not a position")) {
            try await engine.analyze(fen: "not a position", depth: 10)
        }
    }

    @Test func cancelledSearchStopsAndLaterSearchesStillWork() async throws {
        let engine = try await startedEngine()
        let deepSearch = Task {
            try await engine.analyze(
                fen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
                depth: 40)
        }
        deepSearch.cancel()
        await #expect(throws: CancellationError.self) { try await deepSearch.value }

        // The engine must still answer normally afterward.
        let analysis = try await engine.analyze(
            fen: "6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1", depth: 10)
        #expect(analysis.bestMove == "e1e8")
    }

    @Test func onlyTheLatestOfQuickMovesNeedsAnAnswer() async throws {
        // Like a player moving fast: each new position cancels the search before it.
        // After 1. e4 d5 2. Qg4?? Black's bishop takes the queen.
        let engine = try await startedEngine()
        let positions = [
            "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
            "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2",
            "rnbqkbnr/ppp1pppp/8/3p4/4P1Q1/8/PPPP1PPP/RNB1KBNR b KQkq - 1 2",
        ]
        var searches: [Task<EngineAnalysis, any Error>] = []
        for fen in positions {
            searches.last?.cancel()
            searches.append(Task { try await engine.analyze(fen: fen, depth: 12) })
            try await Task.sleep(for: .milliseconds(30))
        }

        let latest = try #require(try await searches.last?.value)
        #expect(Self.whitePointOfView(latest.evaluation) < -500)
        #expect(latest.bestMove == "c8g4")
    }

    @Test func answersArriveRoundByRoundThenTheFinishedOne() async throws {
        let engine = try await startedEngine()
        var answers: [EngineAnalysis] = []
        for try await answer in engine.analyses(
            fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1", depth: 10)
        {
            answers.append(answer)
        }

        let depths = answers.map(\.depth)
        #expect(answers.count > 2)
        #expect(depths == depths.sorted(), "Each round goes at least as deep as the last")
        let finished = try #require(answers.last)
        #expect(finished.depth >= 10)
        #expect(finished.bestMove != nil)
    }

    @Test func stoppingReadingEarlyStopsTheSearch() async throws {
        let engine = try await startedEngine()
        // Depth 40 would take far longer than this test's time limit if it kept going.
        for try await _ in engine.analyses(
            fen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3", depth: 40)
        {
            break  // The first rough answer is enough.
        }

        // The next search only gets its turn once Stockfish has really stopped.
        let analysis = try await engine.analyze(
            fen: "6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1", depth: 10)
        #expect(analysis.bestMove == "e1e8")
    }

    @Test func weakenedSearchStillScoresTheTopLine() async throws {
        // At reduced strength Stockfish also reports weaker moves. The score must still
        // be the best move's: here, mate in one with Re8#.
        let analysis = try await startedEngine().analyze(
            fen: "6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1", depth: 10,
            strength: .limited(rating: 1320))
        #expect(analysis.evaluation == .mate(winner: .white, moves: 1))
        #expect(analysis.bestMove != nil)
    }

    @Test func stockfishOpponentPlaysALegalMove() async throws {
        let opponent = StockfishOpponent(engine: try await startedEngine(), rating: 1500)
        var game = ChessGame()
        game.move(engineMove: "e2e4")

        let move = try await opponent.chooseMove(in: game)

        let wasPlayed = game.move(engineMove: move)
        #expect(wasPlayed, "Stockfish chose \(move), which isn't legal")
        #expect(game.sideToMove == .white)
    }

    @Test func opponentsWeakSettingDoesNotWeakenTheAnalysisAfterIt() async throws {
        // The opponent and the eval bar share one Stockfish. After a weakened search,
        // the next analysis must be at full strength again.
        let engine = try await startedEngine()
        let opponent = StockfishOpponent(engine: engine, rating: 1320)
        _ = try await opponent.chooseMove(in: ChessGame())

        // After 1. e4 d5 2. Qg4?? the bishop takes the queen. Full strength always sees it.
        let analysis = try await engine.analyze(
            fen: "rnbqkbnr/ppp1pppp/8/3p4/4P1Q1/8/PPPP1PPP/RNB1KBNR b KQkq - 1 2", depth: 12)
        #expect(analysis.bestMove == "c8g4")
    }

    /// A score as a number for comparisons, treating a mate as a huge advantage.
    private static func whitePointOfView(_ evaluation: Evaluation) -> Int {
        switch evaluation {
        case .centipawns(let centipawns): centipawns
        case .mate(let winner, _): winner == .white ? 100_000 : -100_000
        }
    }
}

@Test func engineMustBeStartedFirst() async throws {
    let engine = StockfishEngine()
    await #expect(throws: EngineError.notStarted) {
        try await engine.analyze(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1", depth: 1)
    }
}

@Test func gameGivesItsPositionAsFEN() {
    #expect(ChessGame().fen == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
}

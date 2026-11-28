import PittChessCore
import Testing

@testable import PittChess

// Playing against a bot, with pretend opponents so no Stockfish is needed.

/// Plays the given moves in order, one per turn.
private actor ScriptedOpponent: Opponent {
    nonisolated let rating = 1400
    private var moves: [String]

    init(_ moves: [String]) {
        self.moves = moves
    }

    func chooseMove(in game: ChessGame) async throws -> String {
        guard !moves.isEmpty else { throw EngineError.noMove }
        return moves.removeFirst()
    }
}

/// Can't choose a move, like when Stockfish didn't start.
private struct FailingOpponent: Opponent {
    let rating = 1400

    func chooseMove(in game: ChessGame) async throws -> String {
        throw EngineError.didNotStart
    }
}

/// Fails a set number of times (like a lost Stockfish answer), then plays its move.
private actor FlakyOpponent: Opponent {
    nonisolated let rating = 1400
    private var failuresLeft: Int
    private let move: String
    private(set) var timesAsked = 0

    init(failures: Int, then move: String) {
        failuresLeft = failures
        self.move = move
    }

    func chooseMove(in game: ChessGame) async throws -> String {
        timesAsked += 1
        if failuresLeft > 0 {
            failuresLeft -= 1
            throw EngineError.noMove
        }
        return move
    }
}

/// Waits to answer until the test says which move to play, so a test can change the
/// game while the bot is still thinking.
private actor SlowOpponent: Opponent {
    nonisolated let rating = 1400
    private var answer: CheckedContinuation<String, Never>?
    private var whenAsked: CheckedContinuation<Void, Never>?

    func chooseMove(in game: ChessGame) async throws -> String {
        await withCheckedContinuation { continuation in
            answer = continuation
            whenAsked?.resume()
            whenAsked = nil
        }
    }

    /// Returns once the bot has started thinking.
    func waitUntilAsked() async {
        guard answer == nil else { return }
        await withCheckedContinuation { whenAsked = $0 }
    }

    func reply(_ move: String) {
        answer?.resume(returning: move)
        answer = nil
    }
}

@MainActor
struct BotGameTests {
    @Test func botRepliesAfterYourMove() async throws {
        let model = botGame(humanSide: .white, opponent: ScriptedOpponent(["e7e5"]))
        try tap(model, "e2", "e4")
        #expect(model.isBotsTurn)

        await model.playBotMove()

        #expect(model.game.moveHistory == ["e4", "e5"])
        #expect(!model.isBotsTurn)
    }

    @Test func botMovesFirstWhenYouPlayBlack() async {
        let model = botGame(humanSide: .black, opponent: ScriptedOpponent(["d2d4"]))
        #expect(model.isBotsTurn)

        await model.playBotMove()

        #expect(model.game.moveHistory == ["d4"])
    }

    @Test func youCantMoveWhileTheBotIsThinking() throws {
        let model = botGame(humanSide: .white, opponent: ScriptedOpponent([]))
        try tap(model, "e2", "e4")

        // Black's pieces are the bot's, so tapping them does nothing.
        try tap(model, "e7")
        #expect(model.selectedSquare == nil)
    }

    @Test func undoTakesBackYourMoveAndTheBotsReply() async throws {
        let model = botGame(humanSide: .white, opponent: ScriptedOpponent(["e7e5"]))
        try tap(model, "e2", "e4")
        await model.playBotMove()

        model.undo()

        #expect(model.game.moveHistory.isEmpty)
        #expect(!model.isBotsTurn)
    }

    @Test func undoWhileTheBotIsThinkingTakesBackJustYourMove() throws {
        let model = botGame(humanSide: .white, opponent: ScriptedOpponent([]))
        try tap(model, "e2", "e4")

        model.undo()

        #expect(model.game.moveHistory.isEmpty)
    }

    @Test func cantUndoTheBotsFirstMove() async {
        let model = botGame(humanSide: .black, opponent: ScriptedOpponent(["d2d4"]))
        await model.playBotMove()

        #expect(!model.canUndo)
    }

    @Test func playingBlackUndoStopsOnYourTurn() async throws {
        let model = botGame(
            humanSide: .black, opponent: ScriptedOpponent(["d2d4", "c2c4"]))
        await model.playBotMove()
        try tap(model, "d7", "d5")
        await model.playBotMove()

        model.undo()

        #expect(model.game.moveHistory == ["d4"])
        #expect(model.game.sideToMove == .black)
    }

    @Test func boardShowsYourSideAtTheBottom() async throws {
        let asBlack = botGame(humanSide: .black, opponent: ScriptedOpponent(["e2e4"]))
        #expect(asBlack.isBoardFlipped)

        let asWhite = botGame(humanSide: .white, opponent: ScriptedOpponent(["e7e5"]))
        asWhite.flipsEachTurn = true  // Only for two players on one phone.
        try tap(asWhite, "e2", "e4")
        #expect(!asWhite.isBoardFlipped)
    }

    @Test func botAnswerForAnOldPositionIsThrownAway() async throws {
        let opponent = SlowOpponent()
        let model = botGame(humanSide: .white, opponent: opponent)
        try tap(model, "e2", "e4")

        let thinking = Task { await model.playBotMove() }
        await opponent.waitUntilAsked()
        model.undo()  // Takes back e4 while the bot is still thinking about it.
        await opponent.reply("e7e5")
        await thinking.value

        #expect(model.game.moveHistory.isEmpty)
        #expect(!model.botFailed)
    }

    @Test func botThatCantMoveIsReported() async throws {
        let model = botGame(humanSide: .white, opponent: FailingOpponent())
        try tap(model, "e2", "e4")

        await model.playBotMove()

        #expect(model.botFailed)
        model.undo()
        #expect(!model.botFailed)
    }

    @Test func botTriesOnceMoreAfterAFailure() async throws {
        let opponent = FlakyOpponent(failures: 1, then: "e7e5")
        let model = botGame(humanSide: .white, opponent: opponent)
        try tap(model, "e2", "e4")

        await model.playBotMove()

        #expect(model.game.moveHistory == ["e4", "e5"])
        #expect(!model.botFailed)
        #expect(await opponent.timesAsked == 2)
    }

    @Test func botGivesUpAfterTwoFailures() async throws {
        let opponent = FlakyOpponent(failures: 2, then: "e7e5")
        let model = botGame(humanSide: .white, opponent: opponent)
        try tap(model, "e2", "e4")

        await model.playBotMove()

        #expect(model.botFailed)
        #expect(model.game.moveHistory == ["e4"])
        #expect(await opponent.timesAsked == GameModel.botAttempts)
    }

    @Test func tryAgainAsksTheBotOnceMore() async throws {
        let opponent = FlakyOpponent(failures: 2, then: "e7e5")
        let model = botGame(humanSide: .white, opponent: opponent)
        try tap(model, "e2", "e4")
        await model.playBotMove()
        let turnBefore = model.botTurnID

        model.retryBotMove()
        #expect(!model.botFailed)
        #expect(model.botTurnID != turnBefore)  // This makes the view ask the bot again.
        await model.playBotMove()

        #expect(model.game.moveHistory == ["e4", "e5"])
    }

    @Test func illegalBotMoveIsNotPlayed() async throws {
        // ChessKit is the referee, even for the bot. It asks again, then gives up.
        let model = botGame(
            humanSide: .white, opponent: ScriptedOpponent(["e7e4", "e7e4"]))
        try tap(model, "e2", "e4")

        await model.playBotMove()

        #expect(model.game.moveHistory == ["e4"])
        #expect(model.botFailed)
    }

    @Test func newGameAgainstABotAsksForItsRating() {
        var ratingsAsked: [Int] = []
        let model = GameModel(makeOpponent: { rating in
            ratingsAsked.append(rating)
            return FirstLegalMoveOpponent(rating: rating)
        })
        let firstGame = model.botTurnID

        model.startNewGame(.bot(level: .expert, humanSide: .black))

        #expect(ratingsAsked == [BotLevel.expert.rating])
        #expect(model.setup == .bot(level: .expert, humanSide: .black))
        #expect(model.isBotsTurn)
        #expect(model.botTurnID != firstGame)
    }

    @Test func passAndPlayHasNoBot() async throws {
        let model = GameModel()
        try tap(model, "e2", "e4")

        #expect(!model.isBotsTurn)
        await model.playBotMove()
        #expect(model.game.moveHistory == ["e4"])
    }

    @Test func botTakesAtLeastItsThinkingTime() async throws {
        let model = GameModel(
            setup: .bot(level: .advanced, humanSide: .white),
            botThinkingTime: .milliseconds(200),
            makeOpponent: { _ in ScriptedOpponent(["e7e5"]) })
        try tap(model, "e2", "e4")

        let started = ContinuousClock.now
        await model.playBotMove()

        #expect(ContinuousClock.now - started >= .milliseconds(200))
        #expect(model.game.moveHistory == ["e4", "e5"])
    }

    // MARK: - Resigning

    @Test func resigningAgainstABotMeansYouLose() throws {
        let model = botGame(humanSide: .black, opponent: ScriptedOpponent([]))

        model.resign()

        #expect(model.game.outcome == .resigned(winner: .white))
        #expect(!model.canResign)
        #expect(!model.isBotsTurn)
    }

    @Test func botAnswerAfterYouResignIsIgnored() async throws {
        let opponent = SlowOpponent()
        let model = botGame(humanSide: .white, opponent: opponent)
        try tap(model, "e2", "e4")

        let thinking = Task { await model.playBotMove() }
        await opponent.waitUntilAsked()
        model.resign()
        await opponent.reply("e7e5")
        await thinking.value

        #expect(model.game.moveHistory == ["e4"])
        #expect(model.game.outcome == .resigned(winner: .black))
        #expect(!model.botFailed)
    }

    @Test func inPassAndPlayThePlayerToMoveResigns() throws {
        let model = GameModel()
        try tap(model, "e2", "e4")

        model.resign()  // Black's turn, so Black gives up.

        #expect(model.game.outcome == .resigned(winner: .white))
    }

    // MARK: - Leaving

    @Test func youCanLeaveOnlyBeforeTheFirstMove() async throws {
        let friendGame = GameModel()
        #expect(friendGame.canLeaveWithoutResigning)
        try tap(friendGame, "e2", "e4")
        #expect(!friendGame.canLeaveWithoutResigning)

        // Against a bot playing White, its first move counts too.
        let botGame = botGame(humanSide: .black, opponent: ScriptedOpponent(["d2d4"]))
        #expect(botGame.canLeaveWithoutResigning)
        await botGame.playBotMove()
        #expect(!botGame.canLeaveWithoutResigning)
    }

    // MARK: - Helpers

    private func botGame(humanSide: Side, opponent: any Opponent) -> GameModel {
        GameModel(
            setup: .bot(level: .advanced, humanSide: humanSide), botThinkingTime: .zero,
            makeOpponent: { _ in opponent })
    }

    /// Taps the named squares in order.
    private func tap(_ model: GameModel, _ names: String...) throws {
        for name in names {
            model.tap(try #require(BoardSquare(name: name)))
        }
    }
}

import ChessKitEngine
import Foundation

/// Talks to Stockfish: give it a position, get back a score and its favorite move.
///
/// This is an `actor`, so only one caller at a time can be inside it. On top of that,
/// `analyze` waits its turn: one search finishes before the next starts, so answers
/// never get mixed up between positions.
///
/// **Only one Stockfish can run per app.** ChessKitEngine talks to it through the app's
/// own input and output streams, so a second one would steal the first one's answers.
/// Everything that needs the engine (the eval bar and the computer opponent) shares
/// this one, and its queue keeps them from talking over each other.
public actor StockfishEngine {
    private let connection = StockfishConnection()
    private var responses: AsyncStream<EngineResponse>.Iterator

    private var startup: Task<Void, any Error>?
    private var isStarted = false

    // The queue of searches. Only the search holding the turn talks to Stockfish.
    private var isSearching = false
    private var waitingSearches: [CheckedContinuation<Void, Never>] = []
    private var nextSearchID = 0
    private var currentSearchID: Int?
    /// Searches waiting for their turn. Cancelling one removes it, so it's skipped.
    private var waitingSearchIDs: Set<Int> = []

    /// How many "isready" questions Stockfish hasn't answered yet.
    private var unansweredReadyChecks = 0

    /// How long a search may run before we ask Stockfish to stop and answer.
    private let searchTimeLimit: Duration

    public init(searchTimeLimit: Duration = .seconds(10)) {
        self.searchTimeLimit = searchTimeLimit
        responses = connection.responses.makeAsyncIterator()
    }

    /// Starts Stockfish and loads its neural networks. Safe to call more than once,
    /// even at the same time: later callers wait for the first start to finish.
    ///
    /// If starting fails, every later call throws the same error. Stockfish can only be
    /// started once per app, and none of the failures fix themselves while it runs.
    public func start() async throws {
        if let startup {
            return try await startup.value
        }
        let newStartup = Task { try await self.startStockfish() }
        startup = newStartup
        try await newStartup.value
    }

    /// How long Stockfish gets to start and load its networks before we give up.
    static let startupTimeLimit: Duration = .seconds(20)

    private func startStockfish() async throws {
        // Check before starting: Stockfish quits the whole app if a network is missing.
        let networks = try StockfishNetworks.locate()

        connection.start()
        // If Stockfish never answers, closing the connection ends the waiting below.
        let timeout = Task { [connection] in
            do {
                try await Task.sleep(for: Self.startupTimeLimit)
                connection.close()
            } catch {
                // Cancelled because Stockfish started in time.
            }
        }
        defer { timeout.cancel() }

        connection.send(.uci)
        var saidUCIOK = false
        while let response = await nextResponse() {
            if response == .uciok {
                saidUCIOK = true
                break
            }
        }
        guard saidUCIOK else { throw EngineError.didNotStart }

        connection.send(.setoption(name: "EvalFile", value: networks.main))
        connection.send(.setoption(name: "EvalFileSmall", value: networks.small))
        connection.send(.setoption(name: "Threads", value: "\(Self.threadCount)"))
        guard await waitUntilReady() else { throw EngineError.didNotStart }
        isStarted = true
    }

    /// How many processor cores Stockfish searches with: two, or one on a single-core
    /// machine. An iPhone XR has two fast cores; leaving the rest keeps the app smooth.
    static let threadCount = max(1, min(2, ProcessInfo.processInfo.activeProcessorCount))

    /// Stockfish's answer as it improves, for showing right away.
    ///
    /// Stockfish searches in rounds, one half-move deeper each time, and has a score
    /// after every round. This hands over each round's answer as it comes (the first
    /// within milliseconds), then the finished answer with Stockfish's chosen move.
    ///
    /// Stopping early (say, the player moved again, so the task reading this was
    /// cancelled) tells Stockfish to stop.
    public nonisolated func analyses(fen: String, depth: Int)
        -> AsyncThrowingStream<EngineAnalysis, any Error>
    {
        let (stream, continuation) = AsyncThrowingStream<EngineAnalysis, any Error>.makeStream()
        let search = Task {
            do {
                let finished = try await self.analyze(fen: fen, depth: depth) { roundAnswer in
                    continuation.yield(roundAnswer)
                }
                continuation.yield(finished)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { termination in
            if case .cancelled = termination { search.cancel() }
        }
        return stream
    }

    /// Asks Stockfish how good a position is and which move it would play.
    ///
    /// If the task calling this is cancelled (say, the player moved again), Stockfish
    /// is told to stop and this throws `CancellationError`.
    ///
    /// - parameter fen: the position to look at.
    /// - parameter depth: how many half-moves ahead to look. More is stronger and slower.
    /// - parameter strength: how hard Stockfish tries. Analysis uses `.full`; the
    ///   computer opponent asks for less.
    /// - parameter onRound: called with Stockfish's answer after each round of its search.
    public func analyze(
        fen: String, depth: Int, strength: EngineStrength = .full,
        onRound: @escaping @Sendable (EngineAnalysis) -> Void = { _ in }
    ) async throws -> EngineAnalysis {
        guard isStarted else { throw EngineError.notStarted }
        // Stockfish trusts whatever it's given and can crash on a broken position,
        // so ChessKit checks the FEN first.
        guard let game = ChessGame(fen: fen) else { throw EngineError.invalidPosition(fen) }

        let id = nextSearchID
        nextSearchID += 1
        waitingSearchIDs.insert(id)

        // The search runs in its own task, so that cancelling our caller doesn't cut
        // Stockfish off mid-sentence. Cancelling asks Stockfish to stop instead.
        let search = Task {
            try await self.search(
                id: id, fen: game.fen, sideToMove: game.sideToMove, depth: depth,
                strength: strength, onRound: onRound)
        }
        let result = await withTaskCancellationHandler {
            await search.result
        } onCancel: {
            Task { await self.cancelSearch(id: id) }
        }
        try Task.checkCancellation()
        return try result.get()
    }

    // MARK: - One search

    private func search(
        id: Int, fen: String, sideToMove: Side, depth: Int, strength: EngineStrength,
        onRound: @Sendable (EngineAnalysis) -> Void
    ) async throws -> EngineAnalysis {
        await waitForTurn()
        defer { finishTurn() }
        // Cancelled while waiting: skip it.
        guard waitingSearchIDs.remove(id) != nil else { throw CancellationError() }

        currentSearchID = id
        defer { currentSearchID = nil }

        // Every search sets the strength it wants, so the last search's setting
        // never carries over.
        for command in Self.strengthCommands(for: strength) {
            connection.send(command)
        }
        connection.send(.position(fen: fen))
        connection.send(.go(depth: depth))
        let watchdog = startWatchdog(for: id)
        defer { watchdog.cancel() }

        var deepest: (score: EngineScore, depth: Int)?
        var bestMove: String?
        searching: while let response = await nextResponse() {
            switch response {
            case .info(let info):
                if let score = Self.engineScore(from: info), let infoDepth = info.depth,
                    infoDepth >= (deepest?.depth ?? 0)
                {
                    deepest = (score, infoDepth)
                    onRound(
                        EngineAnalysis(
                            evaluation: Evaluation(engineScore: score, sideToMove: sideToMove),
                            bestMove: info.pv?.first, depth: infoDepth))
                }
            case .bestmove(let move, _):
                // "(none)" means no legal moves. A move that isn't complete means the
                // line was cut in two; then we have no move rather than a wrong one.
                bestMove = Self.isCompleteMove(move) ? move : nil
                break searching
            case .readyok:
                // Only the watchdog asks "isready" mid-search, when Stockfish's
                // "bestmove" line went missing. Go with what we have.
                if unansweredReadyChecks == 0 { break searching }
            case .id, .uciok:
                continue
            }
        }
        // If the watchdog asked "isready", collect the answer now so it can't
        // confuse the next search.
        if unansweredReadyChecks > 0 { await waitUntilReady() }

        guard let deepest else { throw EngineError.noEvaluation }
        return EngineAnalysis(
            evaluation: Evaluation(engineScore: deepest.score, sideToMove: sideToMove),
            bestMove: bestMove,
            depth: deepest.depth)
    }

    /// The UCI commands that set Stockfish's strength for the next search.
    static func strengthCommands(for strength: EngineStrength) -> [StockfishConnection.Command] {
        switch strength {
        case .full:
            return [.setoption(name: "UCI_LimitStrength", value: "false")]
        case .limited(let rating):
            let supported = min(
                max(rating, EngineStrength.lowestRating), EngineStrength.highestRating)
            return [
                .setoption(name: "UCI_LimitStrength", value: "true"),
                .setoption(name: "UCI_Elo", value: "\(supported)"),
            ]
        }
    }

    /// Reads a score out of one of Stockfish's "info" lines, if it has an exact one.
    ///
    /// Stockfish ends every scored line with "pv" and its planned moves, after the score.
    /// A line cut short (see `StockfishConnection`) can lose the end of its score, like
    /// "cp 7" from "cp 735", so a line without "pv" isn't trusted. The one exception is
    /// depth 0, which Stockfish sends with no moves when the game is already over.
    ///
    /// At reduced strength, Stockfish quietly looks at its top four moves and reports
    /// each one ("multipv 2", "multipv 3", …). Only the top line scores the position.
    static func engineScore(from info: EngineResponse.Info) -> EngineScore? {
        guard let score = info.score, score.lowerbound != true, score.upperbound != true,
            info.pv?.isEmpty == false || info.depth == 0,
            (info.multipv ?? 1) == 1
        else {
            return nil
        }
        if let mate = score.mate { return .mate(mate) }
        if let centipawns = score.cp { return .centipawns(Int(centipawns.rounded())) }
        return nil
    }

    /// True for a move written the way engines write them: "e2e4", or "e7e8q" for a
    /// promotion.
    static func isCompleteMove(_ move: String) -> Bool {
        let characters = Array(move)
        guard characters.count == 4 || characters.count == 5 else { return false }
        let files: Set<Character> = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let ranks: Set<Character> = ["1", "2", "3", "4", "5", "6", "7", "8"]
        let promotions: Set<Character> = ["q", "r", "b", "n"]
        return files.contains(characters[0]) && ranks.contains(characters[1])
            && files.contains(characters[2]) && ranks.contains(characters[3])
            && (characters.count == 4 || promotions.contains(characters[4]))
    }

    private func cancelSearch(id: Int) {
        if currentSearchID == id {
            connection.send(.stop)
        } else {
            // Still waiting for its turn, so it'll be skipped. (If it already finished,
            // there's nothing to do.)
            waitingSearchIDs.remove(id)
        }
    }

    /// If a search runs too long, tells Stockfish to stop and answer. If its answer
    /// still doesn't arrive (a line can occasionally get lost), "isready" makes it
    /// say "readyok", which ends the search with what we have.
    private func startWatchdog(for id: Int) -> Task<Void, Never> {
        let limit = searchTimeLimit
        return Task {
            do {
                try await Task.sleep(for: limit)
                guard self.currentSearchID == id else { return }
                self.connection.send(.stop)
                try await Task.sleep(for: .seconds(2))
                guard self.currentSearchID == id else { return }
                self.sendReadyCheck()
            } catch {
                // Cancelled because the search finished in time.
            }
        }
    }

    // MARK: - Taking turns

    private func waitForTurn() async {
        if isSearching {
            await withCheckedContinuation { waitingSearches.append($0) }
        } else {
            isSearching = true
        }
    }

    private func finishTurn() {
        if waitingSearches.isEmpty {
            isSearching = false
        } else {
            // Hand the turn straight to the next search in line.
            waitingSearches.removeFirst().resume()
        }
    }

    // MARK: - Reading Stockfish's answers

    /// The next thing Stockfish said.
    ///
    /// Only called from inside the actor, and never from a task that might be cancelled:
    /// cancelling a task that's waiting on an `AsyncStream` closes the stream for good.
    private func nextResponse() async -> EngineResponse? {
        // Swift doesn't let an actor change a stored property across an `await`, so read
        // through a copy. Copies of a stream iterator share the same stream.
        var iterator = responses
        let response = await iterator.next(isolation: self)
        responses = iterator
        if response == .readyok {
            unansweredReadyChecks = max(0, unansweredReadyChecks - 1)
        }
        return response
    }

    /// Asks Stockfish "isready?". It answers "readyok" once it has finished everything
    /// sent before, so counting the questions matches each answer to its question.
    private func sendReadyCheck() {
        unansweredReadyChecks += 1
        connection.send(.isready)
    }

    /// Sends "isready" and skips everything until every ready check has been answered.
    ///
    /// - returns: false if Stockfish's answers stopped coming before that.
    @discardableResult
    private func waitUntilReady() async -> Bool {
        sendReadyCheck()
        while unansweredReadyChecks > 0 {
            guard await nextResponse() != nil else { return false }
        }
        return true
    }
}

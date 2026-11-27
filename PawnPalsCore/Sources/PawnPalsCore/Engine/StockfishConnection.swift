import ChessKitEngine
import ChessKitEngineCore

/// The wire to Stockfish: send it commands, hear its answers in the order it said them.
///
/// ChessKitEngine has a friendlier `Engine` class, but it hands each answer over on a
/// separate task, so answers can arrive out of order (a score line after "bestmove",
/// or "readyok" before lines Stockfish printed earlier). We use the layer underneath,
/// `EngineMessenger`, which calls us once per line, in order, and still use
/// ChessKitEngine's parser to read each line.
///
/// `EngineMessenger` only hears Stockfish while the main run loop is running. Apps
/// always have one; tests start one themselves.
///
/// It reads Stockfish's output in chunks and splits each chunk into lines, so once in
/// a while a line is cut in two. `StockfishEngine` checks each line it relies on is
/// complete.
final class StockfishConnection: Sendable {
    private let messenger: EngineMessenger
    private let continuation: AsyncStream<EngineResponse>.Continuation

    /// Everything Stockfish says, in order. Lines that aren't UCI answers are skipped.
    let responses: AsyncStream<EngineResponse>

    init() {
        let messenger = EngineMessenger(engineType: .stockfish)
        let (responses, continuation) = AsyncStream<EngineResponse>.makeStream()
        messenger.responseHandler = { line in
            if let response = EngineResponse(rawValue: line) {
                continuation.yield(response)
            }
        }
        self.messenger = messenger
        self.responses = responses
        self.continuation = continuation
    }

    /// Ends `responses`, so anything waiting for Stockfish's next line gets nil.
    /// Used when Stockfish doesn't answer at all.
    func close() {
        continuation.finish()
    }

    /// Starts Stockfish running in the background. Call once, before `send`.
    func start() {
        messenger.start()
    }

    func send(_ command: Command) {
        messenger.sendCommand(command.text)
    }

    /// The UCI commands we send. UCI is the plain-text language chess engines speak.
    enum Command: Equatable {
        /// "Speak UCI, please." Stockfish answers "uciok".
        case uci
        /// "Are you done with everything I sent?" Stockfish answers "readyok".
        case isready
        case setoption(name: String, value: String)
        /// Sets up the board to analyze.
        case position(fen: String)
        /// Starts searching, `depth` half-moves ahead. Ends with "bestmove".
        case go(depth: Int)
        /// "Stop thinking and tell me your best move now."
        case stop

        var text: String {
            switch self {
            case .uci: "uci"
            case .isready: "isready"
            case .setoption(let name, let value): "setoption name \(name) value \(value)"
            case .position(let fen): "position fen \(fen)"
            case .go(let depth): "go depth \(depth)"
            case .stop: "stop"
            }
        }
    }
}

/// What the engine found when it looked at one position.
public struct EngineAnalysis: Sendable, Equatable {
    /// How good the position is, from White's point of view.
    public let evaluation: Evaluation

    /// The move the engine likes best, written the way engines write moves
    /// ("e2e4", or "e7e8q" for a promotion). Nil when there are no legal moves
    /// because the game is over.
    public let bestMove: String?

    /// How many half-moves ahead the engine looked.
    public let depth: Int

    public init(evaluation: Evaluation, bestMove: String?, depth: Int) {
        self.evaluation = evaluation
        self.bestMove = bestMove
        self.depth = depth
    }
}

/// Things that can go wrong when talking to the engine.
public enum EngineError: Error, Equatable, CustomStringConvertible {
    /// A neural-network file isn't in the app. Stockfish can't evaluate without it.
    case missingNetworkFile(String)

    /// Stockfish didn't answer when we started it.
    case didNotStart

    /// `analyze` was called before `start`.
    case notStarted

    /// The position isn't valid FEN.
    case invalidPosition(String)

    /// Stockfish finished without ever giving a score.
    case noEvaluation

    public var description: String {
        switch self {
        case .missingNetworkFile(let name):
            "Stockfish's network file \(name) is missing. Run scripts/fetch-stockfish-networks.sh."
        case .didNotStart: "Stockfish didn't start."
        case .notStarted: "Start the engine before asking it about a position."
        case .invalidPosition(let fen): "Not a valid position: \(fen)"
        case .noEvaluation: "Stockfish finished without giving a score."
        }
    }
}

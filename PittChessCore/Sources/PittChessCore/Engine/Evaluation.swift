/// How good a position is, according to the engine, **always from White's point of view**.
///
/// Stockfish reports scores from the point of view of the player whose turn it is.
/// `init(engineScore:sideToMove:)` turns that into White's point of view, and it's the
/// only place in the app that does. Everything else can trust that "positive is good for White."
public enum Evaluation: Sendable, Equatable {
    /// An advantage measured in hundredths of a pawn: +100 means White is about a pawn ahead,
    /// -250 means Black is about two and a half pawns ahead.
    case centipawns(Int)

    /// Someone can force checkmate in `moves` of their own moves.
    /// `moves` is 0 when the player to move is already checkmated.
    case mate(winner: Side, moves: Int)

    /// Converts a score that Stockfish reported from the side to move's point of view.
    ///
    /// - parameter engineScore: the score as Stockfish said it.
    /// - parameter sideToMove: whose turn it was in the position Stockfish looked at.
    public init(engineScore: EngineScore, sideToMove: Side) {
        switch engineScore {
        case .centipawns(let forSideToMove):
            self = .centipawns(sideToMove == .white ? forSideToMove : -forSideToMove)
        case .mate(let forSideToMove):
            // Positive: the side to move gives mate. Negative or 0: it gets mated.
            let winner = forSideToMove > 0 ? sideToMove : sideToMove.opponent
            self = .mate(winner: winner, moves: abs(forSideToMove))
        }
    }

    /// The score of a finished game, straight from the rules: no engine needed.
    /// Checkmate is a win for the winner; any draw is level.
    ///
    /// Nil after a resignation: the rules don't score the position, so ask the engine.
    public init?(outcome: GameOutcome) {
        switch outcome {
        case .checkmate(let winner): self = .mate(winner: winner, moves: 0)
        case .draw: self = .centipawns(0)
        case .resigned: return nil
        }
    }
}

/// A score exactly as Stockfish reports it: from the point of view of the side to move.
///
/// Only `Evaluation(engineScore:sideToMove:)` should read one of these.
public enum EngineScore: Sendable, Equatable {
    /// Positive is good for the side to move.
    case centipawns(Int)

    /// Positive: the side to move mates in this many moves. Negative: it gets mated.
    /// 0: it's already checkmated.
    case mate(Int)
}

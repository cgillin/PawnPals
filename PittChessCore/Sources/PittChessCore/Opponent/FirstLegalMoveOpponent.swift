/// A pretend opponent for previews and tests: it plays the first legal move it finds,
/// instantly, without Stockfish. It's not meant to be played against for real.
public struct FirstLegalMoveOpponent: Opponent {
    public let rating: Int

    public init(rating: Int = 0) {
        self.rating = rating
    }

    public func chooseMove(in game: ChessGame) async throws -> String {
        for start in BoardSquare.all {
            // ChessKit decides what's legal; we just take the first move it allows.
            if let end = game.legalDestinations(from: start).min(by: { $0.name < $1.name }) {
                return start.name + end.name
            }
        }
        throw EngineError.noMove
    }
}

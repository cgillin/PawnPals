/// A computer opponent that is Stockfish holding back to play at a set rating.
///
/// It can't play below `EngineStrength.lowestRating` (about 1320), so beginner levels
/// need a different opponent.
public struct StockfishOpponent: Opponent {
    public let rating: Int
    private let engine: StockfishEngine

    /// How far ahead it looks. At reduced strength Stockfish picks its move early in
    /// the search (by depth 6 for ratings up to about 2200) and ignores what it finds
    /// after that, so searching deeper only makes the computer slower.
    static let depth = 8

    /// - parameter engine: the app's one Stockfish, shared with the eval bar.
    /// - parameter rating: how strongly to play. Moved into Stockfish's range if needed.
    public init(engine: StockfishEngine, rating: Int) {
        self.engine = engine
        self.rating = min(
            max(rating, EngineStrength.lowestRating), EngineStrength.highestRating)
    }

    public func chooseMove(in game: ChessGame) async throws -> String {
        try await engine.start()
        let analysis = try await engine.analyze(
            fen: game.fen, depth: Self.depth, strength: .limited(rating: rating))
        guard let move = analysis.bestMove else { throw EngineError.noMove }
        return move
    }
}

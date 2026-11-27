/// Anything that can look at a position and say how good it is.
///
/// `StockfishEngine` is the real one. Tests and previews use pretend ones that answer
/// instantly, so they don't have to start Stockfish.
public protocol PositionAnalyzer: Sendable {
    /// Gets ready to analyze. Safe to call more than once.
    func start() async throws

    /// How good `fen` is and which move is best, looking `depth` half-moves ahead:
    /// a rough answer first, then better ones as the search goes deeper.
    /// Stopping reading early stops the search.
    func analyses(fen: String, depth: Int) -> AsyncThrowingStream<EngineAnalysis, any Error>
}

extension StockfishEngine: PositionAnalyzer {}

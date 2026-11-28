/// How hard Stockfish tries in one search.
///
/// Every search says which strength it wants, and the engine sets it before that
/// search starts. So a weakened opponent's setting can never leak into the eval bar's
/// analysis, or the other way round, even though they share one Stockfish.
public enum EngineStrength: Sendable, Equatable {
    /// Stockfish at its best. The eval bar and grading always use this.
    case full

    /// Stockfish holding back to play at about this rating. Ratings outside what
    /// Stockfish supports are moved to the nearest end of its range.
    ///
    /// Stockfish measured these ratings in fast games against other engines, not
    /// people, so treat them as a rough guide and tune levels by playing them.
    case limited(rating: Int)

    /// The weakest rating Stockfish can play at by itself. Below this, we need our own
    /// weak bot.
    public static let lowestRating = 1320

    /// The strongest rating Stockfish's strength limit goes up to.
    public static let highestRating = 3190
}

/// Anything that can choose the computer's move.
///
/// `StockfishOpponent` is the first kind. Our own weak bot for beginners comes next,
/// and Maia may join later. The app only talks to this protocol, so it never needs to
/// know which kind it's playing.
public protocol Opponent: Sendable {
    /// The rating this opponent plays at, roughly.
    var rating: Int { get }

    /// The move to play in `game`'s current position, written the way engines write
    /// moves ("e2e4", or "e7e8n" for a promotion).
    ///
    /// Throws if no move can be found, for example because the engine couldn't start.
    func chooseMove(in game: ChessGame) async throws -> String
}

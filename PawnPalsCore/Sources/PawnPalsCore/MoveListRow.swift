/// One numbered row of the move list, like "1. e4 e5".
///
/// `white` is nil when the game started with Black to move (written "1. … e5"),
/// and `black` is nil while Black hasn't replied yet.
public struct MoveListRow: Equatable, Sendable {
    public let number: Int
    public let white: String?
    public let black: String?

    public init(number: Int, white: String?, black: String?) {
        self.number = number
        self.white = white
        self.black = black
    }
}

/// One of the 64 squares on the board, like "e4".
///
/// Files (columns) and ranks (rows) are numbered from 0, so the app can use
/// them directly for drawing: `file` 0 is the a-file, `rank` 0 is rank 1.
public struct BoardSquare: Hashable, Sendable {
    /// Column, 0...7 for files a...h.
    public let file: Int
    /// Row, 0...7 for ranks 1...8.
    public let rank: Int

    /// The square's name in chess notation, like "e4".
    public var name: String {
        "\(Self.fileLetters[file])\(rank + 1)"
    }

    /// Light or dark square. a1 is always dark.
    public var isLight: Bool {
        (file + rank) % 2 == 1
    }

    /// All 64 squares, a1 through h8.
    public static let all: [BoardSquare] = (0..<8).flatMap { rank in
        (0..<8).compactMap { file in BoardSquare(file: file, rank: rank) }
    }

    /// Creates a square from numbers, or nil if they're off the board.
    public init?(file: Int, rank: Int) {
        guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
        self.file = file
        self.rank = rank
    }

    /// Creates a square from its name, like "e4", or nil if the name isn't a square.
    public init?(name: String) {
        guard name.count == 2,
            let fileLetter = name.first,
            let file = Self.fileLetters.firstIndex(of: fileLetter),
            let rankNumber = name.last?.wholeNumberValue
        else { return nil }
        self.init(file: file, rank: rankNumber - 1)
    }

    private static let fileLetters: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h"]
}

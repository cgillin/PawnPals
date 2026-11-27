import Foundation

extension Evaluation {
    /// White's chance of winning, from 0 to 100.
    ///
    /// Being +8 instead of +5 hardly matters (White is winning either way), but +1
    /// instead of -2 matters a lot. This S-shaped curve, the one Lichess uses, captures
    /// that: it's steep near equal and flattens out as one side pulls far ahead.
    /// See DESIGN.md §3. The eval bar shows this now; grading will use it in step 5.
    public var whiteWinPercent: Double {
        switch self {
        case .centipawns(let centipawns):
            50 + 50 * (2 / (1 + exp(-0.003_682_08 * Double(centipawns))) - 1)
        case .mate(let winner, _):
            winner == .white ? 100 : 0
        }
    }
}

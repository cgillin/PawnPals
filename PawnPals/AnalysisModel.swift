import Observation
import PawnPalsCore

/// The engine's opinion of the position on the board, for the eval bar.
///
/// The view calls `update(for:)` whenever the board changes. If the board changes
/// again before the engine answers, SwiftUI cancels the old request, so the bar
/// only ever shows the position that's actually on screen.
@Observable
final class AnalysisModel {
    /// How good the position is, from White's point of view.
    /// Nil until the first answer arrives. Between moves it keeps the last answer,
    /// so the bar slides to the new value instead of jumping back to the middle.
    private(set) var evaluation: Evaluation?

    /// The position `evaluation` belongs to, as FEN. When it doesn't match the board,
    /// the score is the previous position's and the header shows it faded.
    private(set) var evaluatedFEN: String?

    /// True if the engine couldn't start, for example because its network files are missing.
    private(set) var isUnavailable = false

    /// How far ahead the engine looks for the bar. Deep enough to be sensible,
    /// quick enough (well under a second on an iPhone XR) to keep up with play.
    static let depth = 12

    /// The bar starts moving once the search is this deep. The first few rounds take
    /// only milliseconds but can swing wildly, which would make the bar twitch.
    /// The finished answer is always shown, however deep it got.
    static let firstDepthShown = 5

    private let analyzer: any PositionAnalyzer

    init(analyzer: any PositionAnalyzer) {
        self.analyzer = analyzer
    }

    /// True when `evaluation` is about the position `fen`, not an earlier one.
    func isCurrent(for fen: String) -> Bool {
        evaluatedFEN == fen
    }

    /// Asks the engine about `game`'s current position and updates `evaluation`.
    func update(for game: ChessGame) async {
        let fen = game.fen
        // A finished game needs no engine: the rules already say who won.
        if let outcome = game.outcome {
            show(Evaluation(outcome: outcome), for: fen)
            return
        }

        do {
            try await analyzer.start()
        } catch {
            isUnavailable = true
            return
        }

        do {
            // A rough answer comes within milliseconds, then better ones as the engine
            // looks deeper. If the board changes, SwiftUI cancels this task: the loop
            // ends and the engine is told to stop.
            var latest: Evaluation?
            for try await analysis in analyzer.analyses(fen: fen, depth: Self.depth) {
                // The board may have moved on while we waited; then this answer is stale.
                try Task.checkCancellation()
                latest = analysis.evaluation
                if analysis.depth >= Self.firstDepthShown {
                    show(analysis.evaluation, for: fen)
                }
            }
            try Task.checkCancellation()
            if let latest {
                show(latest, for: fen)
            }
        } catch {
            // The board changed (cancelled), or this one search went wrong. Either way
            // the next move asks again; the last score stays, shown faded as out of date.
        }
    }

    private func show(_ newEvaluation: Evaluation, for fen: String) {
        evaluation = newEvaluation
        evaluatedFEN = fen
    }
}

extension AnalysisModel {
    /// A model that always gives the same answer, for previews.
    static func preview(showing evaluation: Evaluation) -> AnalysisModel {
        AnalysisModel(analyzer: FixedAnalyzer(evaluation: evaluation))
    }
}

/// A pretend engine that always gives the same answer, instantly.
private struct FixedAnalyzer: PositionAnalyzer {
    let evaluation: Evaluation

    func start() async throws {}

    func analyses(fen: String, depth: Int) -> AsyncThrowingStream<EngineAnalysis, any Error> {
        let (stream, continuation) = AsyncThrowingStream<EngineAnalysis, any Error>.makeStream()
        continuation.yield(EngineAnalysis(evaluation: evaluation, bestMove: nil, depth: depth))
        continuation.finish()
        return stream
    }
}

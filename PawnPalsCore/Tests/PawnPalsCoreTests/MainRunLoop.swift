import Foundation

/// Keeps the main run loop turning while tests run.
///
/// ChessKitEngine only hears Stockfish's answers when the main thread's run loop is
/// running. An app always has one going; the `swift test` runner doesn't, so without
/// this, Stockfish would talk and nobody would listen.
@MainActor
enum MainRunLoop {
    private static var pump: Task<Void, Never>?

    static func keepRunning() {
        guard pump == nil else { return }
        pump = Task { @MainActor in
            while !Task.isCancelled {
                turnOnce()
                await Task.yield()
            }
        }
    }

    /// Lets the run loop handle whatever is waiting, for up to 10 milliseconds.
    /// (Swift doesn't allow this call directly inside async code, so it gets its own function.)
    private static func turnOnce() {
        RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
    }
}

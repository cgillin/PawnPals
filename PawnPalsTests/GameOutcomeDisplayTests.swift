import PawnPalsCore
import Testing

@testable import PawnPals

// Tests for the words on the game-over card.
// `@MainActor` because the app's code runs on the main thread by default.

@MainActor @Test func checkmateCardSaysWhoWon() {
    let outcome = GameOutcome.checkmate(winner: .black)
    #expect(outcome.title == "Checkmate!")
    #expect(outcome.detail == "Black wins")
}

@MainActor @Test func drawCardSaysWhyItsADraw() {
    let outcome = GameOutcome.draw(.repetition)
    #expect(outcome.title == "It's a draw")
    #expect(outcome.detail == "The same position came up three times")
}

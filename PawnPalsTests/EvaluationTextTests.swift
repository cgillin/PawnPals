import PawnPalsCore
import Testing

@testable import PawnPals

// The header's score, its label, the material count, and what VoiceOver says.

@MainActor @Test func whiteAheadShowsAPlusSignAndTwoDecimals() {
    #expect(EvaluationText.score(for: .centipawns(182)) == "+1.82")
}

@MainActor @Test func blackAheadShowsAMinusSign() {
    #expect(EvaluationText.score(for: .centipawns(-50)) == "\u{2212}0.50")
}

@MainActor @Test func smallScoresKeepTheirLeadingZero() {
    #expect(EvaluationText.score(for: .centipawns(7)) == "+0.07")
}

@MainActor @Test func levelScoreHasNoSignAndReadsEven() {
    #expect(EvaluationText.score(for: .centipawns(0)) == "0.00")
    #expect(EvaluationText.label(for: .centipawns(0)) == "Even")
}

@MainActor @Test func labelSaysWhoHasTheAdvantage() {
    #expect(EvaluationText.label(for: .centipawns(182)) == "White advantage")
    #expect(EvaluationText.label(for: .centipawns(-80)) == "Black advantage")
}

@MainActor @Test func lessThanHalfAPawnCountsAsEven() {
    // The boundary: 49 is even, 50 is an advantage, for either side.
    #expect(EvaluationText.label(for: .centipawns(49)) == "Even")
    #expect(EvaluationText.label(for: .centipawns(-49)) == "Even")
    #expect(EvaluationText.label(for: .centipawns(50)) == "White advantage")
    #expect(EvaluationText.label(for: .centipawns(-50)) == "Black advantage")
}

@MainActor @Test func labelAndVoiceOverAgreeOnEven() {
    // A tiny edge: the number still shows, but nobody is called "ahead".
    #expect(EvaluationText.score(for: .centipawns(7)) == "+0.07")
    #expect(EvaluationText.label(for: .centipawns(7)) == "Even")
    #expect(EvaluationText.spoken(for: .centipawns(7)) == "The position is about even")
}

@MainActor @Test func mateShowsTheMovesLeft() {
    #expect(EvaluationText.score(for: .mate(winner: .black, moves: 3)) == "M3")
    #expect(EvaluationText.label(for: .mate(winner: .black, moves: 3)) == "Black can mate")
}

@MainActor @Test func checkmateShowsAHashAndTheWinner() {
    #expect(EvaluationText.score(for: .mate(winner: .white, moves: 0)) == "#")
    #expect(EvaluationText.label(for: .mate(winner: .white, moves: 0)) == "White wins")
}

@MainActor @Test func materialShowsWhoHasMore() {
    #expect(EvaluationText.material(3) == "+3")
    #expect(EvaluationText.material(-2) == "\u{2212}2")
    #expect(EvaluationText.material(0) == "0")
}

@MainActor @Test func smallAdvantageIsSpokenAsEven() {
    #expect(EvaluationText.spoken(for: .centipawns(30)) == "The position is about even")
}

@MainActor @Test func advantageIsSpokenInPawns() {
    #expect(EvaluationText.spoken(for: .centipawns(100)) == "White is ahead by about 1 pawn")
    #expect(EvaluationText.spoken(for: .centipawns(-250)) == "Black is ahead by about 2.5 pawns")
}

@MainActor @Test func mateIsSpokenInPlainWords() {
    #expect(
        EvaluationText.spoken(for: .mate(winner: .white, moves: 1))
            == "White can force checkmate in 1 move")
    #expect(
        EvaluationText.spoken(for: .mate(winner: .black, moves: 0))
            == "Black has won by checkmate")
}

@MainActor @Test func materialIsSpokenInPoints() {
    #expect(EvaluationText.spokenMaterial(0) == "Material is even")
    #expect(EvaluationText.spokenMaterial(1) == "White is up 1 point of material")
    #expect(EvaluationText.spokenMaterial(-5) == "Black is up 5 points of material")
}

import PittChessCore
import Testing

// Stockfish scores from the side to move's point of view; we store White's.
// These tests pin down the sign flip, which DESIGN.md says will make every move
// look like a blunder if we get it wrong.

@Test func whiteToMoveScoreKeepsItsSign() {
    let evaluation = Evaluation(engineScore: .centipawns(150), sideToMove: .white)
    #expect(evaluation == .centipawns(150))
}

@Test func blackToMoveScoreIsFlippedToWhitesView() {
    // Black to move and Black is 1.5 pawns better: White is 1.5 pawns worse.
    let evaluation = Evaluation(engineScore: .centipawns(150), sideToMove: .black)
    #expect(evaluation == .centipawns(-150))
}

@Test func blackToMoveLosingScoreMeansWhiteIsAhead() {
    let evaluation = Evaluation(engineScore: .centipawns(-300), sideToMove: .black)
    #expect(evaluation == .centipawns(300))
}

@Test func levelScoreStaysLevelForEitherSide() {
    #expect(Evaluation(engineScore: .centipawns(0), sideToMove: .white) == .centipawns(0))
    #expect(Evaluation(engineScore: .centipawns(0), sideToMove: .black) == .centipawns(0))
}

@Test func sideToMoveCanMateSoItWins() {
    #expect(
        Evaluation(engineScore: .mate(3), sideToMove: .white) == .mate(winner: .white, moves: 3))
    #expect(
        Evaluation(engineScore: .mate(2), sideToMove: .black) == .mate(winner: .black, moves: 2))
}

@Test func sideToMoveGetsMatedSoTheOpponentWins() {
    #expect(
        Evaluation(engineScore: .mate(-4), sideToMove: .white) == .mate(winner: .black, moves: 4))
    #expect(
        Evaluation(engineScore: .mate(-1), sideToMove: .black) == .mate(winner: .white, moves: 1))
}

@Test func alreadyCheckmatedSideToMoveHasLost() {
    // After Fool's Mate it's White to move, and White is checkmated: "mate 0".
    #expect(
        Evaluation(engineScore: .mate(0), sideToMove: .white) == .mate(winner: .black, moves: 0))
}

@Test func checkmatedGameIsAWinForTheWinner() {
    #expect(Evaluation(outcome: .checkmate(winner: .black)) == .mate(winner: .black, moves: 0))
}

@Test func drawnGameIsLevel() {
    #expect(Evaluation(outcome: .draw(.stalemate)) == .centipawns(0))
    #expect(Evaluation(outcome: .draw(.repetition)) == .centipawns(0))
}

@Test func resignationIsNotScoredByTheRules() {
    // Giving up doesn't change the position, so the engine still scores it.
    #expect(Evaluation(outcome: .resigned(winner: .white)) == nil)
}

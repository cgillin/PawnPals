import PawnPalsCore
import Testing

// White's chance of winning, from the engine's score.

@Test func levelPositionIsAFiftyFiftyChance() {
    #expect(Evaluation.centipawns(0).whiteWinPercent == 50)
}

@Test func onePawnAheadIsAboutASixtyPercentChance() {
    // The Lichess curve puts +100 at 59.1%.
    #expect(abs(Evaluation.centipawns(100).whiteWinPercent - 59.1) < 0.1)
}

@Test func beingBehindMirrorsBeingAhead() {
    let ahead = Evaluation.centipawns(250).whiteWinPercent
    let behind = Evaluation.centipawns(-250).whiteWinPercent
    #expect(abs(ahead + behind - 100) < 0.000_001)
}

@Test func threePawnsMatterLessWhenAlreadyFarAhead() {
    // Going from +5 to +8 (you're winning either way) changes the chance much less
    // than going from +1 to -2, even though both are three pawns.
    let farAhead =
        Evaluation.centipawns(800).whiteWinPercent
        - Evaluation.centipawns(500).whiteWinPercent
    let nearEven =
        Evaluation.centipawns(100).whiteWinPercent
        - Evaluation.centipawns(-200).whiteWinPercent
    #expect(farAhead < nearEven / 2)
    #expect(Evaluation.centipawns(800).whiteWinPercent < 100)
}

@Test func whiteMatingIsACertainWin() {
    #expect(Evaluation.mate(winner: .white, moves: 3).whiteWinPercent == 100)
}

@Test func blackMatingIsACertainLossForWhite() {
    #expect(Evaluation.mate(winner: .black, moves: 1).whiteWinPercent == 0)
}

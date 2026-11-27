import PawnPalsCore
import Testing

// Tests for the moves a game remembers: writing them down in chess notation,
// numbering them for the move list, and taking them back with undo.

// MARK: - Writing moves down

@Test func newGameHasNoMoves() {
    let game = ChessGame()
    #expect(game.moveHistory.isEmpty)
    #expect(game.canUndo == false)
}

@Test func movesAreWrittenInChessNotation() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("e7", "e5"), ("g1", "f3"))
    #expect(game.moveHistory == ["e4", "e5", "Nf3"])
}

@Test func captureIsWrittenWithAnX() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("d7", "d5"), ("e4", "d5"))
    #expect(game.moveHistory.last == "exd5")
}

@Test func checkmateIsWrittenWithAHash() throws {
    // Fool's mate: 1. f3 e5 2. g4 Qh4#
    var game = ChessGame()
    try play(&game, ("f2", "f3"), ("e7", "e5"), ("g2", "g4"), ("d8", "h4"))
    #expect(game.moveHistory == ["f3", "e5", "g4", "Qh4#"])
}

@Test func castlingKingsideIsWrittenOO() throws {
    var game = try #require(ChessGame(fen: "4k3/8/8/8/8/8/8/4K2R w K - 0 1"))
    try play(&game, ("e1", "g1"))
    #expect(game.moveHistory == ["O-O"])
}

@Test func promotionShowsTheNewPieceAndTheCheck() throws {
    // The new queen on a8 looks straight along the back row at the black king on e8.
    var game = try #require(ChessGame(fen: "4k3/P7/8/8/8/8/8/4K3 w - - 0 1"))
    try play(&game, ("a7", "a8"))
    #expect(game.moveHistory == ["a8=Q+"])
}

// MARK: - Numbering moves for the move list

@Test func moveListPairsEachWhiteMoveWithBlacksReply() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("e7", "e5"), ("g1", "f3"))
    #expect(
        game.moveListRows == [
            MoveListRow(
                number: 1, white: .init(index: 0, san: "e4"), black: .init(index: 1, san: "e5")),
            MoveListRow(number: 2, white: .init(index: 2, san: "Nf3"), black: nil),
        ])
}

@Test func moveListStartsWithAGapWhenBlackMovesFirst() throws {
    // A puzzle position where it's Black's turn: the first row is "1. … d5".
    var game = try #require(ChessGame(fen: "4k3/3p4/8/4P3/8/8/8/4K3 b - - 0 1"))
    try play(&game, ("d7", "d5"), ("e5", "d6"))
    #expect(
        game.moveListRows == [
            MoveListRow(number: 1, white: nil, black: .init(index: 0, san: "d5")),
            MoveListRow(number: 2, white: .init(index: 1, san: "exd6"), black: nil),
        ])
}

// MARK: - Looking back at earlier moves

@Test func lastMoveRemembersWhereThePieceWentFromAndTo() throws {
    var game = ChessGame()
    #expect(game.lastMove == nil)

    try play(&game, ("g1", "f3"))
    #expect(game.lastMove == MoveSquares(from: try square("g1"), to: try square("f3")))
}

@Test func lookingBackShowsTheBoardRightAfterThatMove() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("e7", "e5"), ("g1", "f3"))

    let afterFirstMove = try #require(game.game(afterMoveAt: 0))
    #expect(afterFirstMove.piece(at: try square("e4")) == ChessPiece(.pawn, .white))
    #expect(afterFirstMove.piece(at: try square("e5")) == nil)  // Black hasn't replied yet.
    #expect(afterFirstMove.sideToMove == .black)
    #expect(afterFirstMove.moveHistory == ["e4"])
    #expect(afterFirstMove.lastMove == MoveSquares(from: try square("e2"), to: try square("e4")))
}

@Test func lookingBackAtTheLatestMoveShowsTheCurrentBoard() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("e7", "e5"))

    let latest = try #require(game.game(afterMoveAt: 1))
    #expect(latest.piece(at: try square("e5")) == ChessPiece(.pawn, .black))
    #expect(latest.sideToMove == .white)
}

@Test func lookingBackDoesNotChangeTheRealGame() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("e7", "e5"))

    _ = game.game(afterMoveAt: 0)
    #expect(game.moveHistory == ["e4", "e5"])
    #expect(game.piece(at: try square("e5")) == ChessPiece(.pawn, .black))
}

@Test func lookingBackAtAMoveThatWasNeverPlayedGivesNothing() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"))

    #expect(game.game(afterMoveAt: 1) == nil)
    #expect(game.game(afterMoveAt: -1) == nil)
}

// MARK: - Undo

@Test func undoTakesBackTheLastMove() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"))

    #expect(game.undo() == true)
    #expect(game.piece(at: try square("e2")) == ChessPiece(.pawn, .white))
    #expect(game.piece(at: try square("e4")) == nil)
    #expect(game.sideToMove == .white)
    #expect(game.moveHistory.isEmpty)
}

@Test func undoWithNoMovesDoesNothing() {
    var game = ChessGame()
    #expect(game.undo() == false)
    #expect(game.sideToMove == .white)
}

@Test func undoAfterCheckmateLetsTheGameContinue() throws {
    var game = ChessGame()
    try play(&game, ("f2", "f3"), ("e7", "e5"), ("g2", "g4"), ("d8", "h4"))
    #expect(game.outcome == .checkmate(winner: .black))

    game.undo()
    #expect(game.outcome == nil)
    #expect(game.sideToMove == .black)
    #expect(game.piece(at: try square("d8")) == ChessPiece(.queen, .black))
}

@Test func undoPutsACapturedPieceBack() throws {
    var game = ChessGame()
    try play(&game, ("e2", "e4"), ("d7", "d5"), ("e4", "d5"))

    game.undo()
    #expect(game.piece(at: try square("d5")) == ChessPiece(.pawn, .black))
    #expect(game.piece(at: try square("e4")) == ChessPiece(.pawn, .white))
}

@Test func undoingAPromotionTurnsTheQueenBackIntoAPawn() throws {
    var game = try #require(ChessGame(fen: "4k3/P7/8/8/8/8/8/4K3 w - - 0 1"))
    try play(&game, ("a7", "a8"))

    game.undo()
    #expect(game.piece(at: try square("a7")) == ChessPiece(.pawn, .white))
    #expect(game.piece(at: try square("a8")) == nil)
}

@Test func undoingCastlingLetsTheKingCastleAgain() throws {
    // Castling is only allowed if the king and rook have never moved.
    // Undo has to give that right back, not just move the pieces.
    var game = try #require(ChessGame(fen: "4k3/8/8/8/8/8/8/4K2R w K - 0 1"))
    try play(&game, ("e1", "g1"))

    game.undo()
    #expect(game.piece(at: try square("e1")) == ChessPiece(.king, .white))
    #expect(game.piece(at: try square("h1")) == ChessPiece(.rook, .white))
    #expect(game.legalDestinations(from: try square("e1")).contains(try square("g1")))
}

@Test func undoKeepsTheChanceToCaptureEnPassant() throws {
    // En passant is only allowed right after the pawn's two-square jump.
    // Undoing White's capture must bring that chance back.
    var game = try #require(ChessGame(fen: "4k3/3p4/8/4P3/8/8/8/4K3 b - - 0 1"))
    try play(&game, ("d7", "d5"), ("e5", "d6"))

    game.undo()
    #expect(game.legalDestinations(from: try square("e5")).contains(try square("d6")))
}

// MARK: - How a draw happened

@Test func kingWithNoSafeMoveAndNotInCheckIsStalemate() throws {
    // After Qf7, Black's king on h8 isn't in check, but every square it could go to
    // is attacked. (We reach stalemate by playing a move because ChessKit only spots
    // it after a move, not in a position loaded straight from a FEN.)
    var game = try #require(ChessGame(fen: "7k/8/6K1/5Q2/8/8/8/8 w - - 0 1"))
    try play(&game, ("f5", "f7"))
    #expect(game.outcome == .draw(.stalemate))
}

@Test func justTwoKingsIsADrawByInsufficientMaterial() throws {
    let game = try #require(ChessGame(fen: "8/8/8/4k3/8/8/8/4K3 w - - 0 1"))
    #expect(game.outcome == .draw(.insufficientMaterial))
}

@Test func fiftyMovesWithoutACaptureOrPawnMoveIsADraw() throws {
    // The FEN's "99" means 99 half-moves have passed with no capture or pawn move.
    var game = try #require(ChessGame(fen: "4k3/8/8/8/8/8/8/R3K3 w - - 99 80"))
    try play(&game, ("a1", "a2"))
    #expect(game.outcome == .draw(.fiftyMoveRule))
}

@Test func samePositionThreeTimesIsADrawAndUndoTakesItBack() throws {
    // Both knights hop out and back twice, so the starting position appears a third time.
    var game = ChessGame()
    let shuffle = [("g1", "f3"), ("g8", "f6"), ("f3", "g1"), ("f6", "g8")]
    for (from, to) in shuffle + shuffle {
        try play(&game, (from, to))
    }
    #expect(game.outcome == .draw(.repetition))

    // Taking back the last move means the position has only appeared twice.
    game.undo()
    #expect(game.outcome == nil)
}

// MARK: - Helpers

/// Plays moves given as square names, failing the test if any move is rejected.
private func play(_ game: inout ChessGame, _ moves: (String, String)...) throws {
    for (from, to) in moves {
        let moved = game.move(from: try square(from), to: try square(to))
        try #require(moved, "\(from)-\(to) should be legal")
    }
}

private func square(_ name: String) throws -> BoardSquare {
    try #require(BoardSquare(name: name))
}

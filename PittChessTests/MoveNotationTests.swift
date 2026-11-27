import Testing

@testable import PittChess

// Tests for splitting a move into piece pictures and text.
// `@MainActor` because the app's code runs on the main thread by default.
// "\u{FE0E}" is the invisible marker that keeps iOS from drawing the picture as an emoji.

@MainActor @Test func knightMoveShowsAKnightPicture() {
    #expect(MoveNotation.parts(of: "Nf3") == [.picture("♞\u{FE0E}"), .text("f3")])
}

@MainActor @Test func captureKeepsTheXAndTheSquare() {
    #expect(MoveNotation.parts(of: "Bxb5") == [.picture("♝\u{FE0E}"), .text("xb5")])
}

@MainActor @Test func pawnMoveShowsAPawnPicture() {
    #expect(MoveNotation.parts(of: "e4") == [.picture("♟\u{FE0E}"), .text("e4")])
}

@MainActor @Test func pawnCaptureShowsAPawnPicture() {
    #expect(MoveNotation.parts(of: "exd5") == [.picture("♟\u{FE0E}"), .text("exd5")])
}

@MainActor @Test func promotionShowsThePawnAndTheNewPiece() {
    #expect(
        MoveNotation.parts(of: "a8=Q+") == [
            .picture("♟\u{FE0E}"), .text("a8="), .picture("♛\u{FE0E}"), .text("+"),
        ])
}

@MainActor @Test func castlingHasNoPicture() {
    #expect(MoveNotation.parts(of: "O-O") == [.text("O-O")])
    #expect(MoveNotation.parts(of: "O-O-O") == [.text("O-O-O")])
}

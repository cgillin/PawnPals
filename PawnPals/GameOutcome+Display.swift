import PawnPalsCore

/// The words the game-over card shows. Presentation, so it lives in the app target.
extension GameOutcome {
    /// The big line, like "Checkmate!".
    var title: String {
        switch self {
        case .checkmate: "Checkmate!"
        case .draw: "It's a draw"
        }
    }

    /// The smaller line underneath, saying who won or why it's a draw.
    var detail: String {
        switch self {
        case .checkmate(winner: .white): "White wins"
        case .checkmate(winner: .black): "Black wins"
        case .draw(.stalemate): "Stalemate: the player to move isn't in check but has no move"
        case .draw(.insufficientMaterial): "Neither side has enough pieces left to checkmate"
        case .draw(.fiftyMoveRule): "Fifty moves with no capture and no pawn move"
        case .draw(.repetition): "The same position came up three times"
        case .draw(.agreement): "Both players agreed to a draw"
        }
    }
}

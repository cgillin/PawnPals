import PawnPalsCore
import SwiftUI

/// The card that appears when the game ends: who won (or why it's a draw),
/// and a button to play again.
struct GameOverView: View {
    let outcome: GameOutcome
    let startNewGame: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(outcome.title)
                .font(.title2.bold())
            Text(outcome.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("New Game", systemImage: "arrow.counterclockwise", action: startNewGame)
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
                .accessibilityIdentifier("new-game-button")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        // VoiceOver keeps the title and detail together; the button stays separate.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("game-over")
    }
}

#Preview("Checkmate") {
    GameOverView(outcome: .checkmate(winner: .black)) {}
        .padding()
}

#Preview("Stalemate") {
    GameOverView(outcome: .draw(.stalemate)) {}
        .padding()
}

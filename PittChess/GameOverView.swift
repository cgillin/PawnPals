import PittChessCore
import SwiftUI

/// The card that appears when the game ends: who won (or why it's a draw), a button
/// to go back to the home screen, and a button to play again with the same players.
struct GameOverView: View {
    let outcome: GameOutcome
    let returnHome: () -> Void
    let startNewGame: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(outcome.title)
                .font(.title2.bold())
            Text(outcome.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Return", systemImage: "house.fill", action: returnHome)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("return-home-button")
                Button("Play Again", systemImage: "arrow.counterclockwise", action: startNewGame)
                    .buttonStyle(.borderedProminent)
                    // Black on the yellow accent: the default white is hard to read.
                    .foregroundStyle(.black)
                    .accessibilityIdentifier("new-game-button")
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        // Groups the card as one container for VoiceOver (and gives UI tests one element
        // to find). The title, detail, and buttons are still read one at a time.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("game-over")
    }
}

#Preview("Checkmate") {
    GameOverView(outcome: .checkmate(winner: .black), returnHome: {}, startNewGame: {})
        .padding()
}

#Preview("Resigned") {
    GameOverView(outcome: .resigned(winner: .white), returnHome: {}, startNewGame: {})
        .padding()
}

#Preview("Stalemate") {
    GameOverView(outcome: .draw(.stalemate), returnHome: {}, startNewGame: {})
        .padding()
}

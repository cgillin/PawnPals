import SwiftUI

/// The card that appears when the bot couldn't move, even after trying twice:
/// try again, or quit to the home screen. Quitting doesn't count as resigning,
/// because the problem was the bot's, not yours.
struct BotFailedView: View {
    let quit: () -> Void
    let tryAgain: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("The bot is stuck")
                .font(.title2.bold())
            Text("It couldn't choose a move. Try again, or quit this game.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Quit", systemImage: "house.fill", action: quit)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("quit-game-button")
                Button("Try Again", systemImage: "arrow.clockwise", action: tryAgain)
                    .buttonStyle(.borderedProminent)
                    // Black on the yellow accent: the default white is hard to read.
                    .foregroundStyle(.black)
                    .accessibilityIdentifier("retry-bot-button")
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bot-failed")
    }
}

#Preview {
    BotFailedView(quit: {}, tryAgain: {})
        .padding()
}

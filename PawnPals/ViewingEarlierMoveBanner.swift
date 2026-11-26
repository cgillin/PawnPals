import SwiftUI

/// Shown above the board while looking back at an earlier move: which move it is,
/// and a small button that jumps back to the game as it is now.
struct ViewingEarlierMoveBanner: View {
    /// The move's number: "2." for a White move, "3…" for a Black one.
    let moveNumber: String
    /// The move in standard notation, like "Nf3". Shown with a piece picture.
    let san: String
    let returnToCurrentMove: () -> Void

    /// The user's text size setting, so the header can make room at the largest sizes.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 8) {
            // The clock is decoration, so it's the first thing to go when space is tight.
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            HStack(spacing: 4) {
                Text(moveNumber)
                MoveText(san: san)
            }
            .font(.headline)
            // Keep the move on one line. If it doesn't fit, shrink it a little
            // rather than cutting it short with "…".
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            // When space is shared, the move gets it before the button.
            .layoutPriority(1)
            // VoiceOver reads this as one line, using letters rather than pictures.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Looking back at move \(moveNumber) \(san)")
            .accessibilityIdentifier("viewing-label")
            // "Skip to the end", like on a music player: jump to the latest move.
            Button("Back to Game", systemImage: "forward.end.fill", action: returnToCurrentMove)
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("back-to-game-button")
        }
    }
}

#Preview("White's move") {
    ViewingEarlierMoveBanner(moveNumber: "2.", san: "Nf3") {}
}

#Preview("Black's move") {
    ViewingEarlierMoveBanner(moveNumber: "3…", san: "Nxe5") {}
}

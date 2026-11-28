import SwiftUI

/// The first screen: the app's name, a king standing on a board, and a choice of
/// playing a friend or a bot.
struct HomeView: View {
    let playFriend: () -> Void
    let playBot: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // "Pitt" in yellow, "Chess" in the normal text color.
            Text("\(Text("Pitt").foregroundStyle(.tint))Chess")
                .font(.system(size: 48, weight: .heavy))
                .padding(.top, 32)
                .accessibilityIdentifier("home-title")

            KingOnBoard()
                .frame(maxHeight: .infinity)
                // Undo the page's side margins, so the board runs to the screen edges.
                .padding(.horizontal, -16)

            Button(action: playFriend) {
                ChoiceLabel(title: "Play a Friend", subtitle: "Take turns on this phone") {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("play-friend-button")

            Button(action: playBot) {
                ChoiceLabel(title: "Play a Bot", subtitle: nil) {
                    BotFace(size: 36)
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("play-bot-button")
        }
        .padding()
        .padding(.bottom, 24)
    }
}

/// A gold king with a soft glow, standing on one square of a big checkerboard that
/// fades into the distance. Decorative, so VoiceOver skips it.
///
/// It's laid out at one fixed size, then shrunk to fit the space the title and
/// buttons leave over, so small iPhones and large text sizes still fit everything.
private struct KingOnBoard: View {
    /// How wide one square is before the board is tipped back. Big enough for the
    /// king's base to fit inside a single square.
    static let squareSize: CGFloat = 150

    /// The picture's full height: the board's three rows before tipping.
    static let fullHeight = 3 * squareSize

    var body: some View {
        // A `GeometryReader` tells its content how much space it was given.
        GeometryReader { geometry in
            let scale = min(1, geometry.size.height / Self.fullHeight)
            scene
                .scaleEffect(scale, anchor: .bottom)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
        }
        // The board is wider than the screen; only the middle part shows.
        .clipped()
        .accessibilityHidden(true)
    }

    /// The king, glow, and board at full size.
    private var scene: some View {
        ZStack(alignment: .bottom) {
            CheckerFloor(squareSize: Self.squareSize)
            // The glow behind the king.
            RadialGradient(
                colors: [Color.accentColor.opacity(0.35), .clear], center: .center,
                startRadius: 0, endRadius: 150
            )
            .frame(width: 300, height: 300)
            .offset(y: -140)
            // The king photo has a see-through background, so it works in light and dark mode.
            Image("KingHero")
                .resizable()
                .scaledToFit()
                .frame(height: 260)
                .shadow(color: .black.opacity(0.4), radius: 12, y: 8)
                // Lifts the king so its base sits in the middle of the center square
                // of the second row.
                .offset(y: -73)
        }
        .frame(height: Self.fullHeight, alignment: .bottom)
    }
}

/// A few rows of big squares tipped back in 3D, fading out toward the top. Only part
/// of a board, with the middle square of the front rows under the king.
private struct CheckerFloor: View {
    let squareSize: CGFloat

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(0..<5, id: \.self) { column in
                        Rectangle()
                            .fill(
                                Color.primary.opacity((row + column).isMultiple(of: 2) ? 0.2 : 0.05)
                            )
                            .frame(width: squareSize, height: squareSize)
                    }
                }
            }
        }
        // Fade the far row out before tipping, so the fade follows the board.
        .mask {
            LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom)
        }
        // Tip the board away from the viewer, hinged at its front edge.
        .rotation3DEffect(.degrees(60), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.7)
        // Lay out at the screen's width, so the board's extra width doesn't push the
        // page wider. The parent clips what hangs over the sides.
        .frame(width: 0)
    }
}

/// An icon, a divider, and a title with an optional subtitle, as in the home screen's
/// big buttons. `Icon` is whatever view goes on the left.
private struct ChoiceLabel<Icon: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let icon: Icon

    var body: some View {
        HStack(spacing: 16) {
            icon
                .frame(width: 44)
                .accessibilityHidden(true)
            Divider()
                .frame(height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.bold())
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView(playFriend: {}, playBot: {})
}

import SwiftUI

/// The bot's face: a friendly metallic robot with gold eyes.
///
/// The artwork is an SVG in the asset catalog. Xcode keeps it as a vector, so it
/// stays sharp at any size.
struct BotFace: View {
    var size: CGFloat = 56

    var body: some View {
        Image("BotFace")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        BotFace(size: 32)
        BotFace()
        BotFace(size: 100)
    }
    .padding()
}

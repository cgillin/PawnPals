import SwiftUI

/// The big yellow button for the main choice on a screen ("Play a Friend", "Next").
///
/// A `ButtonStyle` decides how every button using it looks, so all the big buttons
/// match without repeating the same modifiers.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            // Black on yellow reads clearly in both light and dark mode.
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal)
            .background(Color.accentColor, in: .rect(cornerRadius: 16))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

/// The big grey button for the other choices on a screen.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal)
            .background(.fill.secondary, in: .rect(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Play a Friend") {}
            .buttonStyle(PrimaryButtonStyle())
        Button("Play a Bot") {}
            .buttonStyle(SecondaryButtonStyle())
        Button("Not Yet") {}
            .buttonStyle(PrimaryButtonStyle())
            .disabled(true)
    }
    .padding()
}

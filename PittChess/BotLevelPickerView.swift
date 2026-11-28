import SwiftUI

/// "Choose Your Opponent": pick how strong the bot is.
struct BotLevelPickerView: View {
    /// Called with the chosen level when Next is tapped.
    let next: (BotLevel) -> Void

    @State private var selected: BotLevel = .advanced

    var body: some View {
        VStack(spacing: 16) {
            BotHeader {
                Text("Choose Your Opponent")
                    .font(.title2.bold())
            }

            VStack(spacing: 12) {
                ForEach(BotLevel.allCases, id: \.self) { level in
                    Button {
                        selected = level
                    } label: {
                        LevelCard(level: level, isSelected: level == selected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(level == selected ? .isSelected : [])
                    .accessibilityIdentifier("bot-level-\(level.name.lowercased())")
                }
            }

            Text("Easier bots for beginners are coming soon.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Next") { next(selected) }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("bot-level-next-button")
        }
        .padding()
        .navigationTitle("Play a Bot")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The bot's face with a title underneath. Shared by both bot screens.
struct BotHeader<Title: View>: View {
    @ViewBuilder let title: Title

    var body: some View {
        VStack(spacing: 12) {
            BotFace(size: 88)
            title
        }
        .padding(.vertical)
    }
}

/// One level in the list: strength bars, name, rating range, and a round check.
private struct LevelCard: View {
    let level: BotLevel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Fills in more bars for stronger bots.
            Image(systemName: "cellularbars", variableValue: level.strength)
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(level.name)
                    .font(.headline)
                // Verbatim, so 1450 isn't shown as "1,450" like an amount.
                Text(verbatim: "\(level.rating) ELO")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .accessibilityHidden(true)
        }
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(.rect)
    }
}

#Preview {
    NavigationStack {
        BotLevelPickerView { _ in }
    }
}

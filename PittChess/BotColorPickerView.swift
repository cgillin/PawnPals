import PittChessCore
import SwiftUI

/// "Choose Your Color": play the chosen bot as White or Black.
struct BotColorPickerView: View {
    let level: BotLevel
    /// Called with the chosen side when Start Game is tapped.
    let start: (Side) -> Void

    @State private var selected: Side = .white

    var body: some View {
        VStack(spacing: 16) {
            BotHeader {
                VStack(spacing: 4) {
                    Text("Bot Level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(level.name)
                        .font(.title.bold())
                    Text(verbatim: "\(level.rating) ELO")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text("Choose Your Color")
                .font(.title3.bold())

            HStack(spacing: 12) {
                ForEach([Side.white, .black], id: \.self) { side in
                    Button {
                        selected = side
                    } label: {
                        SideCard(side: side, isSelected: side == selected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(side == selected ? .isSelected : [])
                    .accessibilityIdentifier("side-\(side == .white ? "white" : "black")")
                }
            }

            Spacer()

            Button("Start Game") { start(selected) }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("start-game-button")
        }
        .padding()
        .navigationTitle("Play a Bot")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A big king for one side, its name, and a round check.
private struct SideCard: View {
    let side: Side
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            // The same piece symbols the board uses, drawn large.
            Text(ChessPiece(.king, side).symbol)
                .font(.system(size: 80))
                .foregroundStyle(side == .white ? .white : .black)
                // An outline in the opposite color, so each king shows up on any background.
                .shadow(color: side == .white ? .black : .white, radius: 1)
                .accessibilityHidden(true)
            Text(side == .white ? "White" : "Black")
                .font(.headline)
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
        BotColorPickerView(level: .advanced) { _ in }
    }
}

import PittChessCore
import SwiftUI

/// The moves so far as a scrolling line of tappable chips: "1. [e4] [e5]  2. [♞f3]".
///
/// The highlighted chip is the move the board is showing. Tapping a chip shows
/// the board as it was right after that move.
struct MoveListView: View {
    let rows: [MoveListRow]
    /// The move whose chip is lit up, or nil for none.
    let highlightedMoveIndex: Int?
    /// Called with a move's index when its chip is tapped.
    let selectMove: (Int) -> Void

    var body: some View {
        // ScrollViewReader lets code scroll the list, here to the highlighted chip.
        ScrollViewReader { scroller in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if rows.isEmpty {
                        Text("No moves yet")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(rows, id: \.number) { row in
                        rowView(row)
                    }
                }
                .padding(.horizontal)
            }
            // `initial: true` also scrolls when the list first appears with moves in it.
            .onChange(of: highlightedMoveIndex, initial: true) {
                if let highlightedMoveIndex {
                    withAnimation { scroller.scrollTo(Self.chipID(highlightedMoveIndex)) }
                }
            }
        }
        .accessibilityIdentifier("move-list")
    }

    /// "2." followed by White's chip and Black's chip. A missing White move
    /// (Black moved first) shows as "…".
    private func rowView(_ row: MoveListRow) -> some View {
        // Line the move number up with the text inside the chips, not the chip edges.
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(row.number).")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            if let white = row.white {
                chip(for: white, number: row.number, side: "White")
            } else {
                Text("…").foregroundStyle(.secondary)
            }
            if let black = row.black {
                chip(for: black, number: row.number, side: "Black")
            }
        }
    }

    private func chip(for entry: MoveListRow.Entry, number: Int, side: String) -> some View {
        let isHighlighted = entry.index == highlightedMoveIndex
        return Button {
            selectMove(entry.index)
        } label: {
            // The padding and capsule go inside the label, so the whole chip is
            // tappable, not just the move text in the middle.
            MoveText(san: entry.san)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(isHighlighted ? .white : .primary)
                .background(
                    isHighlighted ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary),
                    in: .capsule
                )
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .id(Self.chipID(entry.index))
        // VoiceOver reads the letter version: it would call ♞ "black chess knight"
        // even for White's knight.
        .accessibilityLabel("Move \(number), \(side): \(entry.san)")
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
        .accessibilityIdentifier("move-\(entry.index)")
    }

    /// The scroll tag for a chip, like "move-4". It's a string on purpose: the rows
    /// are already tagged with their move numbers (plain numbers), and a chip tagged
    /// with the number 4 could be mixed up with row 4.
    private static func chipID(_ index: Int) -> String {
        "move-\(index)"
    }
}

#Preview("A few moves in") {
    MoveListView(
        rows: [
            MoveListRow(
                number: 1, white: .init(index: 0, san: "e4"), black: .init(index: 1, san: "e5")),
            MoveListRow(
                number: 2, white: .init(index: 2, san: "Nf3"), black: .init(index: 3, san: "Nc6")),
            MoveListRow(number: 3, white: .init(index: 4, san: "Bb5"), black: nil),
        ],
        highlightedMoveIndex: 4, selectMove: { _ in })
}

#Preview("Looking back at move 2") {
    MoveListView(
        rows: [
            MoveListRow(
                number: 1, white: .init(index: 0, san: "e4"), black: .init(index: 1, san: "e5")),
            MoveListRow(
                number: 2, white: .init(index: 2, san: "Nf3"), black: .init(index: 3, san: "Nc6")),
            MoveListRow(number: 3, white: .init(index: 4, san: "Bb5"), black: nil),
        ],
        highlightedMoveIndex: 2, selectMove: { _ in })
}

#Preview("No moves yet") {
    MoveListView(rows: [], highlightedMoveIndex: nil, selectMove: { _ in })
}

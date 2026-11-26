import PawnPalsCore
import SwiftUI

/// The moves so far, in one scrolling line: "1. e4 e5  2. Nf3 …".
///
/// It scrolls by itself to keep the newest move in view.
struct MoveListView: View {
    let rows: [MoveListRow]

    var body: some View {
        // ScrollViewReader lets code scroll the list, here to the last row.
        ScrollViewReader { scroller in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if rows.isEmpty {
                        Text("No moves yet")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(rows, id: \.number) { row in
                        Text(text(for: row))
                            .monospacedDigit()
                            .id(row.number)
                    }
                }
                .padding(.horizontal)
            }
            // `initial: true` also scrolls when the list first appears with moves in it.
            .onChange(of: rows, initial: true) {
                if let last = rows.last {
                    withAnimation { scroller.scrollTo(last.number, anchor: .trailing) }
                }
            }
        }
        .font(.body)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moves")
        .accessibilityValue(
            rows.isEmpty ? "No moves yet" : rows.map(text(for:)).joined(separator: ", ")
        )
        .accessibilityIdentifier("move-list")
    }

    /// One row as text, like "1. e4 e5", or "1. … e5" if Black moved first.
    private func text(for row: MoveListRow) -> String {
        let white = row.white ?? "…"
        guard let black = row.black else { return "\(row.number). \(white)" }
        return "\(row.number). \(white) \(black)"
    }
}

#Preview("A few moves in") {
    MoveListView(rows: [
        MoveListRow(number: 1, white: "e4", black: "e5"),
        MoveListRow(number: 2, white: "Nf3", black: "Nc6"),
        MoveListRow(number: 3, white: "Bb5", black: nil),
    ])
}

#Preview("No moves yet") {
    MoveListView(rows: [])
}

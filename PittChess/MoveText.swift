import SwiftUI

/// A move drawn with piece pictures, like "♞xe5", where the pictures use a larger
/// font than the letters. Chess symbols come out small in the system font, so at
/// the same size the knight would look tiny next to "xe5".
struct MoveText: View {
    /// The move in standard notation, like "Nxe5".
    let san: String
    /// The font for the pictures. Text styles like `.title2` still follow the
    /// user's text size setting (Dynamic Type).
    var pictureFont: Font = .title2

    var body: some View {
        // Joining Texts with string interpolation keeps one line of text whose
        // parts can each have their own font.
        MoveNotation.parts(of: san).reduce(Text(verbatim: "")) { line, part in
            switch part {
            case .picture(let symbol):
                Text("\(line)\(Text(verbatim: symbol).font(pictureFont))")
            case .text(let text):
                Text("\(line)\(Text(verbatim: text))")
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        MoveText(san: "e4")
        MoveText(san: "Nxe5")
        MoveText(san: "a8=Q+")
        MoveText(san: "O-O")
    }
    .font(.body)
}

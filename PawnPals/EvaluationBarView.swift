import PawnPalsCore
import SwiftUI

/// A small upright bar showing who the engine thinks is winning, at a glance.
///
/// The more of it is white, the better White is doing. White fills from the bottom,
/// like White's side of the board, or from the top when the board is flipped.
/// Like the board, its colors stay the same in dark mode.
struct EvaluationBarView: View {
    /// Nil while waiting for the first answer: the bar sits at even.
    let evaluation: Evaluation?
    /// True when the board has Black at the bottom, so White fills from the top.
    let isFlipped: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isFlipped ? .top : .bottom) {
                Rectangle().fill(Color(white: 0.2))
                Rectangle()
                    .fill(Color(white: 0.92))
                    .frame(height: geometry.size.height * whiteFraction)
            }
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.gray.opacity(0.5), lineWidth: 0.5))
        .animation(.easeInOut(duration: 0.3), value: whiteFraction)
    }

    /// How much of the bar is white: White's chance of winning, from 0 to 1.
    private var whiteFraction: Double {
        (evaluation?.whiteWinPercent ?? 50) / 100
    }
}

#Preview("White a bit better, Black winning flipped") {
    HStack(spacing: 20) {
        EvaluationBarView(evaluation: .centipawns(182), isFlipped: false)
        EvaluationBarView(evaluation: .centipawns(-450), isFlipped: true)
        EvaluationBarView(evaluation: nil, isFlipped: false)
    }
    .frame(width: 80, height: 44)
    .padding()
}

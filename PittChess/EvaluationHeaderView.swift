import PittChessCore
import SwiftUI

/// The card above the board: a small eval bar, the engine's score with who it
/// favors, and the material count on the right.
struct EvaluationHeaderView: View {
    /// The engine's opinion, or nil while it's still thinking about the first position.
    let evaluation: Evaluation?
    /// White's material minus Black's, in pawns.
    let materialBalance: Int
    /// True when the board has Black at the bottom.
    let isFlipped: Bool
    /// True when the engine couldn't start.
    var isUnavailable = false
    /// True when `evaluation` is still the previous position's, while the engine
    /// thinks about the new one. The score is shown faded until the new answer arrives.
    var isStale = false

    /// Sizes that grow with the reader's text size setting.
    @ScaledMetric(relativeTo: .title2) private var barHeight: CGFloat = 34
    @ScaledMetric(relativeTo: .title2) private var barWidth: CGFloat = 8

    var body: some View {
        HStack(spacing: 12) {
            evaluationPart
            Spacer(minLength: 8)
            materialPart
        }
        .lineLimit(1)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
    }

    private var evaluationPart: some View {
        HStack(spacing: 12) {
            EvaluationBarView(evaluation: evaluation, isFlipped: isFlipped)
                .frame(width: barWidth, height: barHeight)
            // The score, with who it favors underneath.
            VStack(alignment: .leading, spacing: 0) {
                Text(scoreText)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(scoreColor)
                Text(labelText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.8)
            }
        }
        .opacity(isUnavailable || isStale ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.2), value: isStale)
        // VoiceOver reads this part as one item: "Evaluation, White is ahead by…"
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Evaluation")
        .accessibilityValue(spokenEvaluation)
        .accessibilityIdentifier("evaluation")
    }

    private var materialPart: some View {
        // The count, with its label underneath, matching the score on the left.
        VStack(alignment: .trailing, spacing: 0) {
            Text(EvaluationText.material(materialBalance))
                .font(.title2.weight(.semibold).monospacedDigit())
            Text("Material")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Material")
        .accessibilityValue(EvaluationText.spokenMaterial(materialBalance))
        .accessibilityIdentifier("material")
    }

    private var scoreText: String {
        guard let evaluation, !isUnavailable else { return "–" }
        return EvaluationText.score(for: evaluation)
    }

    private var labelText: String {
        if isUnavailable { return "Engine unavailable" }
        guard let evaluation else { return "Thinking…" }
        return EvaluationText.label(for: evaluation)
    }

    /// Green when someone is ahead, plain when it's even or unknown.
    private var scoreColor: Color {
        guard let evaluation, !isUnavailable, !EvaluationText.isEven(evaluation) else {
            return .primary
        }
        return .green
    }

    private var spokenEvaluation: String {
        if isUnavailable { return "Not available" }
        guard let evaluation, !isStale else { return "Thinking" }
        return EvaluationText.spoken(for: evaluation)
    }
}

#Preview("White better, up a knight") {
    EvaluationHeaderView(evaluation: .centipawns(182), materialBalance: 3, isFlipped: false)
        .padding()
}

#Preview("Black can mate, board flipped") {
    EvaluationHeaderView(
        evaluation: .mate(winner: .black, moves: 2), materialBalance: -5, isFlipped: true
    )
    .padding()
}

#Preview("Previous position's score, faded") {
    EvaluationHeaderView(
        evaluation: .centipawns(182), materialBalance: 3, isFlipped: false, isStale: true
    )
    .padding()
}

#Preview("Thinking") {
    EvaluationHeaderView(evaluation: nil, materialBalance: 0, isFlipped: false)
        .padding()
}

#Preview("Engine unavailable") {
    EvaluationHeaderView(
        evaluation: nil, materialBalance: 0, isFlipped: false, isUnavailable: true
    )
    .padding()
}

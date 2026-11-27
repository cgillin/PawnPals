import PawnPalsCore

/// How engine scores and material are written and spoken. Presentation, so it lives
/// in the app target.
enum EvaluationText {
    /// Scores closer to 0 than this (half a pawn) count as even: the label says "Even",
    /// the score isn't colored, and VoiceOver says "about even".
    static let evenCentipawns = 50

    /// True when neither side is meaningfully ahead.
    static func isEven(_ evaluation: Evaluation) -> Bool {
        guard case .centipawns(let centipawns) = evaluation else { return false }
        return abs(centipawns) < evenCentipawns
    }

    /// The score in the header: "+1.82", "−0.50", "0.00", "M3" for mate in 3,
    /// or "#" once someone is checkmated.
    static func score(for evaluation: Evaluation) -> String {
        switch evaluation {
        case .centipawns(let centipawns):
            let number = pawns(centipawns, decimals: 2)
            if number == "0.00" { return number }
            return signed(centipawns, number)
        case .mate(_, let moves):
            return moves == 0 ? "#" : "M\(moves)"
        }
    }

    /// The words beside the score: "White advantage", "Even", "Black can mate", "White wins".
    static func label(for evaluation: Evaluation) -> String {
        switch evaluation {
        case .centipawns(let centipawns):
            if isEven(evaluation) { return "Even" }
            return centipawns > 0 ? "White advantage" : "Black advantage"
        case .mate(let winner, let moves):
            let side = winner == .white ? "White" : "Black"
            return moves == 0 ? "\(side) wins" : "\(side) can mate"
        }
    }

    /// The material count: "+3", "−2", or "0". Positive means White has more.
    static func material(_ balance: Int) -> String {
        balance == 0 ? "0" : signed(balance, "\(abs(balance))")
    }

    /// What VoiceOver says about the score, in plain words.
    static func spoken(for evaluation: Evaluation) -> String {
        switch evaluation {
        case .centipawns(let centipawns):
            if isEven(evaluation) { return "The position is about even" }
            let side = centipawns > 0 ? "White" : "Black"
            var amount = pawns(centipawns, decimals: 1)
            if amount.hasSuffix(".0") { amount.removeLast(2) }
            return "\(side) is ahead by about \(amount) \(amount == "1" ? "pawn" : "pawns")"
        case .mate(let winner, let moves):
            let side = winner == .white ? "White" : "Black"
            if moves == 0 { return "\(side) has won by checkmate" }
            return "\(side) can force checkmate in \(moves) \(moves == 1 ? "move" : "moves")"
        }
    }

    /// What VoiceOver says about the material count.
    static func spokenMaterial(_ balance: Int) -> String {
        if balance == 0 { return "Material is even" }
        let side = balance > 0 ? "White" : "Black"
        let points = abs(balance)
        return "\(side) is up \(points) \(points == 1 ? "point" : "points") of material"
    }

    /// Centipawns as pawns, without a sign, rounded to `decimals` places (1 or 2):
    /// 182 → "1.82" or "1.8". Written out by hand so it's "1.82" whatever the phone's
    /// language settings, as on chess sites.
    private static func pawns(_ centipawns: Int, decimals: Int) -> String {
        if decimals == 1 {
            let tenths = (abs(centipawns) + 5) / 10  // Rounded to the nearest tenth.
            return "\(tenths / 10).\(tenths % 10)"
        }
        let hundredths = abs(centipawns)
        let digits = hundredths % 100 < 10 ? "0\(hundredths % 100)" : "\(hundredths % 100)"
        return "\(hundredths / 100).\(digits)"
    }

    /// Puts "+" or a real minus sign (−, which lines up better than a hyphen) in
    /// front of `number`, depending on whether `value` is positive or negative.
    private static func signed(_ value: Int, _ number: String) -> String {
        (value > 0 ? "+" : "\u{2212}") + number
    }
}

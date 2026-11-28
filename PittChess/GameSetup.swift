import PittChessCore

/// Who's playing: two people sharing the phone, or one person against a bot.
enum GameSetup: Hashable {
    /// Two players take turns on the same phone.
    case passAndPlay

    /// One player against a bot.
    case bot(level: BotLevel, humanSide: Side)

    /// The side the bot plays, or nil in a pass-and-play game.
    var botSide: Side? {
        if case .bot(_, let humanSide) = self { humanSide.opponent } else { nil }
    }
}

/// How strongly a bot plays.
///
/// For now these are Stockfish holding back, which can't play below about 1320.
/// Easier levels come with our own beginner bot.
enum BotLevel: CaseIterable, Hashable {
    case advanced
    case expert

    var name: String {
        switch self {
        case .advanced: "Advanced"
        case .expert: "Expert"
        }
    }

    /// The rating the bot plays at, shown to the player as its ELO.
    var rating: Int {
        switch self {
        case .advanced: 1450
        case .expert: 1800
        }
    }

    /// How full the strength bars are, from 0 to 1.
    var strength: Double {
        switch self {
        case .advanced: 0.75
        case .expert: 1
        }
    }
}

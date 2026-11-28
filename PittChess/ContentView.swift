import PittChessCore
import SwiftUI

/// The app's screens and how you move between them:
/// home → (bot level → bot color →) game.
struct ContentView: View {
    /// `@State` keeps the same game alive while the screen redraws.
    @State private var model: GameModel
    /// The screens on top of the home screen, in order. Changing it moves between them.
    @State private var path: [Screen] = []

    /// The screens that can sit on top of the home screen.
    enum Screen: Hashable {
        case botLevel
        case botColor(BotLevel)
        case game
    }

    /// The app passes in a model whose bot uses Stockfish. Previews pass one with a
    /// pretend bot.
    init(model: GameModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                playFriend: { start(.passAndPlay) },
                playBot: { path.append(.botLevel) }
            )
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .botLevel:
                    BotLevelPickerView { level in path.append(.botColor(level)) }
                case .botColor(let level):
                    BotColorPickerView(level: level) { side in
                        start(.bot(level: level, humanSide: side))
                    }
                case .game:
                    GameView(model: model)
                }
            }
        }
    }

    /// Starts a game and shows it. Back from the game goes straight home, not
    /// through the bot screens again.
    private func start(_ setup: GameSetup) {
        model.startNewGame(setup)
        path = [.game]
    }
}

#Preview {
    ContentView(model: GameModel())
        .environment(AnalysisModel.preview(showing: .centipawns(20)))
}

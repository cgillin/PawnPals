//
//  PittChessApp.swift
//  PittChess
//
//  Created by Christopher Gillin on 11/25/26.
//

import PittChessCore
import SwiftUI

@main
struct PittChessApp: App {
    @State private var analysis: AnalysisModel
    @State private var game: GameModel

    init() {
        // One engine for the whole app: only one Stockfish can run at a time. The eval
        // bar and the computer opponent share it and take turns.
        let engine = StockfishEngine()
        _analysis = State(initialValue: AnalysisModel(analyzer: engine))
        _game = State(
            initialValue: GameModel(makeOpponent: { rating in
                StockfishOpponent(engine: engine, rating: rating)
            }))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: game)
                .environment(analysis)
        }
    }
}

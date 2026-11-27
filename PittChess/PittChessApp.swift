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
    /// One engine for the whole app: only one Stockfish can run at a time.
    @State private var analysis = AnalysisModel(analyzer: StockfishEngine())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(analysis)
        }
    }
}

//
//  PawnPalsApp.swift
//  PawnPals
//
//  Created by Christopher Gillin on 11/25/26.
//

import PawnPalsCore
import SwiftUI

@main
struct PawnPalsApp: App {
    /// One engine for the whole app: only one Stockfish can run at a time.
    @State private var analysis = AnalysisModel(analyzer: StockfishEngine())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(analysis)
        }
    }
}

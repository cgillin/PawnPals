//
//  ContentView.swift
//  PawnPals
//
//  Created by Christopher Gillin on 11/25/26.
//

import PawnPalsCore
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "crown.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(Greeting.title).font(.largeTitle)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

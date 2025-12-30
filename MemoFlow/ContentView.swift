//
//  ContentView.swift
//  MemoFlow
//
//  メインエントリポイント
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainCaptureView()
    }
}

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

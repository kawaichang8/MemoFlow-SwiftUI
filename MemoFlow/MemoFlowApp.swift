//
//  MemoFlowApp.swift
//  MemoFlow
//
//  GTD Capture Hub - 思いついたら即キャプチャ
//

import SwiftUI

@main
struct MemoFlowApp: App {
    @State private var settings = AppSettings.shared
    
    init() {
        // アプリ起動時の初期設定
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .preferredColorScheme(colorSchemeFromSettings)
        }
    }
    
    /// 設定から ColorScheme を取得
    private var colorSchemeFromSettings: ColorScheme? {
        switch settings.appearanceMode {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil // システムに従う
        }
    }
    
    private func configureAppearance() {
        // ナビゲーションバーの外観設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - App Intent for Shortcuts (iOS 16+)
import AppIntents

@available(iOS 16.0, *)
struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "クイックキャプチャ"
    static var description = IntentDescription("MemoFlowでメモをすばやくキャプチャ")
    
    @Parameter(title: "メモ内容")
    var content: String?
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // メモ内容がある場合は自動入力（将来実装）
        return .result()
    }
}

@available(iOS 16.0, *)
struct MemoFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickCaptureIntent(),
            phrases: [
                "\(.applicationName)でメモ",
                "\(.applicationName)でキャプチャ",
                "\(.applicationName)を開く",
                "\(.applicationName)に追加"
            ],
            shortTitle: "クイックキャプチャ",
            systemImageName: "note.text.badge.plus"
        )
    }
}

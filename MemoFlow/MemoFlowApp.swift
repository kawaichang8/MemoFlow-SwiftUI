//
//  MemoFlowApp.swift
//  MemoFlow
//
//  GTD Capture Hub - 思いついたら即キャプチャ
//

import SwiftUI
import SwiftData

@main
struct MemoFlowApp: App {
    @State private var settings = AppSettings.shared
    @State private var themeManager = ThemeManager.shared
    @State private var languageRefreshId = UUID()
    
    init() {
        // アプリ起動時の初期設定
        Self.configureAppearance()
    }
    
    /// ナビゲーションバーの外観設定（static）
    private static func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(languageRefreshId) // 言語変更時にビューを再生成
                .environment(settings)
                .environment(themeManager)
                .preferredColorScheme(colorSchemeFromTheme)
                .appLanguage(settings.appLanguage)
                .onReceive(NotificationCenter.default.publisher(for: AppSettings.languageDidChangeNotification)) { _ in
                    // 言語が変更されたらビューを再生成
                    DispatchQueue.main.async {
                        languageRefreshId = UUID()
                    }
                }
        }
        .modelContainer(for: MemoHistoryItem.self)
    }
    
    /// テーマから ColorScheme を取得
    private var colorSchemeFromTheme: ColorScheme? {
        themeManager.currentTheme.colorScheme
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

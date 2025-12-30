//
//  ThemeManager.swift
//  MemoFlow
//
//  カスタムテーマとフォント管理
//  アプリ全体の外観を一元管理
//

import SwiftUI

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case light = "light"
    case dark = "dark"
    case sepia = "sepia"
    case blueLightCut = "blue_light_cut"
    
    var id: String { rawValue }
    
    /// 表示名
    var displayName: String {
        switch self {
        case .light:
            return "ライト"
        case .dark:
            return "ダーク"
        case .sepia:
            return "セピア"
        case .blueLightCut:
            return "ブルーライトカット"
        }
    }
    
    /// アイコン名
    var iconName: String {
        switch self {
        case .light:
            return "sun.max"
        case .dark:
            return "moon.fill"
        case .sepia:
            return "book.fill"
        case .blueLightCut:
            return "eye"
        }
    }
    
    /// 説明
    var description: String {
        switch self {
        case .light:
            return "純白の明るい画面"
        case .dark:
            return "純黒の暗い画面"
        case .sepia:
            return "暖かいベージュ背景"
        case .blueLightCut:
            return "目に優しい暖色系"
        }
    }
    
    /// プレビュー用の色
    var previewColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return Color(white: 0.1)
        case .sepia:
            return Color(red: 0.96, green: 0.94, blue: 0.88)
        case .blueLightCut:
            return Color(red: 0.98, green: 0.95, blue: 0.90)
        }
    }
    
    /// システムのColorSchemeに対応するか
    var colorScheme: ColorScheme? {
        switch self {
        case .light, .sepia, .blueLightCut:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Font Size
enum AppFontSize: String, CaseIterable, Identifiable, Codable {
    case standard = "standard"
    case large = "large"
    case extraLarge = "extra_large"
    
    var id: String { rawValue }
    
    /// 表示名
    var displayName: String {
        switch self {
        case .standard:
            return "標準"
        case .large:
            return "大"
        case .extraLarge:
            return "特大"
        }
    }
    
    /// メインテキストサイズ
    var mainTextSize: CGFloat {
        switch self {
        case .standard:
            return 24
        case .large:
            return 28
        case .extraLarge:
            return 34
        }
    }
    
    /// 行間
    var lineSpacing: CGFloat {
        switch self {
        case .standard:
            return 10
        case .large:
            return 12
        case .extraLarge:
            return 16
        }
    }
    
    /// プレースホルダーサイズ
    var placeholderSize: CGFloat {
        mainTextSize
    }
    
    /// タグチップのサイズ
    var tagTextSize: CGFloat {
        switch self {
        case .standard:
            return 14
        case .large:
            return 16
        case .extraLarge:
            return 18
        }
    }
    
    /// UIのスケール係数
    var scaleFactor: CGFloat {
        switch self {
        case .standard:
            return 1.0
        case .large:
            return 1.1
        case .extraLarge:
            return 1.25
        }
    }
}

// MARK: - Theme Manager
@Observable
final class ThemeManager {
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Properties
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let theme = "appTheme"
        static let fontSize = "appFontSize"
    }
    
    /// 現在のテーマ
    var currentTheme: AppTheme {
        get {
            guard let raw = defaults.string(forKey: Keys.theme),
                  let theme = AppTheme(rawValue: raw) else {
                return .light
            }
            return theme
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.theme)
        }
    }
    
    /// 現在のフォントサイズ
    var fontSize: AppFontSize {
        get {
            guard let raw = defaults.string(forKey: Keys.fontSize),
                  let size = AppFontSize(rawValue: raw) else {
                return .standard
            }
            return size
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.fontSize)
        }
    }
    
    // MARK: - Colors
    
    /// 背景色
    var backgroundColor: Color {
        switch currentTheme {
        case .light:
            return .white
        case .dark:
            return Color(white: 0.05)
        case .sepia:
            return Color(red: 0.96, green: 0.94, blue: 0.88)
        case .blueLightCut:
            return Color(red: 0.98, green: 0.95, blue: 0.90)
        }
    }
    
    /// セカンダリ背景色
    var secondaryBackgroundColor: Color {
        switch currentTheme {
        case .light:
            return Color(white: 0.96)
        case .dark:
            return Color(white: 0.12)
        case .sepia:
            return Color(red: 0.92, green: 0.89, blue: 0.82)
        case .blueLightCut:
            return Color(red: 0.95, green: 0.92, blue: 0.86)
        }
    }
    
    /// テキスト色
    var textColor: Color {
        switch currentTheme {
        case .light:
            return .black
        case .dark:
            return .white
        case .sepia:
            return Color(red: 0.3, green: 0.25, blue: 0.2)
        case .blueLightCut:
            return Color(red: 0.25, green: 0.2, blue: 0.15)
        }
    }
    
    /// セカンダリテキスト色
    var secondaryTextColor: Color {
        switch currentTheme {
        case .light:
            return Color(white: 0.4)
        case .dark:
            return Color(white: 0.6)
        case .sepia:
            return Color(red: 0.5, green: 0.45, blue: 0.4)
        case .blueLightCut:
            return Color(red: 0.45, green: 0.4, blue: 0.35)
        }
    }
    
    /// ターシャリテキスト色
    var tertiaryTextColor: Color {
        switch currentTheme {
        case .light:
            return Color(white: 0.6)
        case .dark:
            return Color(white: 0.4)
        case .sepia:
            return Color(red: 0.65, green: 0.6, blue: 0.55)
        case .blueLightCut:
            return Color(red: 0.6, green: 0.55, blue: 0.5)
        }
    }
    
    /// プレースホルダー色
    var placeholderColor: Color {
        tertiaryTextColor.opacity(0.6)
    }
    
    /// 送信ボタン背景色
    var sendButtonBackgroundColor: Color {
        switch currentTheme {
        case .light, .sepia, .blueLightCut:
            return .black
        case .dark:
            return .white
        }
    }
    
    /// 送信ボタンアイコン色
    var sendButtonIconColor: Color {
        switch currentTheme {
        case .light, .sepia, .blueLightCut:
            return .white
        case .dark:
            return .black
        }
    }
    
    /// セパレーター色
    var separatorColor: Color {
        switch currentTheme {
        case .light:
            return Color(white: 0.85)
        case .dark:
            return Color(white: 0.2)
        case .sepia:
            return Color(red: 0.85, green: 0.82, blue: 0.75)
        case .blueLightCut:
            return Color(red: 0.88, green: 0.85, blue: 0.80)
        }
    }
    
    /// 波形バー色
    var waveformColor: Color {
        textColor.opacity(0.6)
    }
    
    /// タグチップ背景（提案）
    var suggestedTagBackgroundColor: Color {
        secondaryBackgroundColor
    }
    
    /// タグチップボーダー（提案）
    var suggestedTagBorderColor: Color {
        separatorColor
    }
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Methods
    
    /// テーマをリセット
    func reset() {
        currentTheme = .light
        fontSize = .standard
    }
}

// MARK: - Environment Key
struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    /// テーママネージャーを環境に注入
    func withThemeManager() -> some View {
        self.environment(\.themeManager, ThemeManager.shared)
    }
}


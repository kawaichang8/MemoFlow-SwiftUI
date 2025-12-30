//
//  AppSettings.swift
//  MemoFlow
//
//  アプリ設定モデル
//

import Foundation

/// アプリ全体の設定
@Observable
final class AppSettings {
    // MARK: - Singleton
    static let shared = AppSettings()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let defaultDestination = "defaultDestination"
        static let tagAutoMode = "tagAutoMode"
        static let templateSuggestionMode = "templateSuggestionMode"
        static let localAIEnabled = "localAIEnabled"
        static let notionAPIKey = "notionAPIKey"
        static let notionDatabaseId = "notionDatabaseId"
        static let todoistAPIKey = "todoistAPIKey"
        static let todoistProjectId = "todoistProjectId"
        static let slackBotToken = "slackBotToken"
        static let slackChannelId = "slackChannelId"
        static let reflectAPIKey = "reflectAPIKey"
        static let reflectGraphId = "reflectGraphId"
        static let emailToSelfAddress = "emailToSelfAddress"
        static let hapticEnabled = "hapticEnabled"
        static let soundEnabled = "soundEnabled"
        static let savedTags = "savedTags"
        static let appearanceMode = "appearanceMode"
        static let streakEnabled = "streakEnabled"
        static let streakReminderEnabled = "streakReminderEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Properties
    
    /// デフォルト送信先
    var defaultDestination: Destination {
        get {
            guard let raw = defaults.string(forKey: Keys.defaultDestination),
                  let dest = Destination(rawValue: raw) else {
                return .notionInbox
            }
            return dest
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.defaultDestination)
        }
    }
    
    /// タグ自動モード
    var tagAutoMode: TagAutoMode {
        get {
            guard let raw = defaults.string(forKey: Keys.tagAutoMode),
                  let mode = TagAutoMode(rawValue: raw) else {
                return .suggestOnly
            }
            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.tagAutoMode)
        }
    }
    
    /// テンプレート提案モード
    var templateSuggestionMode: TemplateSuggestionMode {
        get {
            guard let raw = defaults.string(forKey: Keys.templateSuggestionMode),
                  let mode = TemplateSuggestionMode(rawValue: raw) else {
                return .suggestOnly // デフォルトは「提案のみ」
            }
            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.templateSuggestionMode)
        }
    }
    
    // MARK: - AI Settings
    
    /// ローカルAI優先（Apple Intelligence使用）
    /// オン: デバイス上でNLP処理（高精度、オフライン可）
    /// オフ: キーワードベースのみ（軽量）
    var localAIEnabled: Bool {
        get {
            // デフォルトはオン（ローカルAI優先）
            if defaults.object(forKey: Keys.localAIEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.localAIEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.localAIEnabled)
        }
    }
    
    // MARK: - Notion Settings
    var notionAPIKey: String {
        get { defaults.string(forKey: Keys.notionAPIKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.notionAPIKey) }
    }
    
    var notionDatabaseId: String {
        get { defaults.string(forKey: Keys.notionDatabaseId) ?? "" }
        set { defaults.set(newValue, forKey: Keys.notionDatabaseId) }
    }
    
    var isNotionConfigured: Bool {
        !notionAPIKey.isEmpty && !notionDatabaseId.isEmpty
    }
    
    // MARK: - Todoist Settings
    var todoistAPIKey: String {
        get { defaults.string(forKey: Keys.todoistAPIKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.todoistAPIKey) }
    }
    
    var todoistProjectId: String {
        get { defaults.string(forKey: Keys.todoistProjectId) ?? "" }
        set { defaults.set(newValue, forKey: Keys.todoistProjectId) }
    }
    
    var isTodoistConfigured: Bool {
        !todoistAPIKey.isEmpty
    }
    
    // MARK: - Slack Settings
    var slackBotToken: String {
        get { defaults.string(forKey: Keys.slackBotToken) ?? "" }
        set { defaults.set(newValue, forKey: Keys.slackBotToken) }
    }
    
    var slackChannelId: String {
        get { defaults.string(forKey: Keys.slackChannelId) ?? "" }
        set { defaults.set(newValue, forKey: Keys.slackChannelId) }
    }
    
    var isSlackConfigured: Bool {
        !slackBotToken.isEmpty && !slackChannelId.isEmpty
    }
    
    // MARK: - Reflect Settings
    var reflectAPIKey: String {
        get { defaults.string(forKey: Keys.reflectAPIKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.reflectAPIKey) }
    }
    
    var reflectGraphId: String {
        get { defaults.string(forKey: Keys.reflectGraphId) ?? "" }
        set { defaults.set(newValue, forKey: Keys.reflectGraphId) }
    }
    
    var isReflectConfigured: Bool {
        !reflectAPIKey.isEmpty && !reflectGraphId.isEmpty
    }
    
    // MARK: - Email Settings
    var emailToSelfAddress: String {
        get { defaults.string(forKey: Keys.emailToSelfAddress) ?? "" }
        set { defaults.set(newValue, forKey: Keys.emailToSelfAddress) }
    }
    
    var isEmailConfigured: Bool {
        !emailToSelfAddress.isEmpty
    }
    
    // MARK: - UX Settings
    var hapticEnabled: Bool {
        get { defaults.bool(forKey: Keys.hapticEnabled) }
        set { defaults.set(newValue, forKey: Keys.hapticEnabled) }
    }
    
    var soundEnabled: Bool {
        get { defaults.bool(forKey: Keys.soundEnabled) }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }
    
    // MARK: - Streak Settings
    
    /// ストリーク表示（デフォルトオン）
    var streakEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.streakEnabled) == nil {
                return true // デフォルトはオン
            }
            return defaults.bool(forKey: Keys.streakEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.streakEnabled) }
    }
    
    /// ストリークリマインダー通知
    var streakReminderEnabled: Bool {
        get { defaults.bool(forKey: Keys.streakReminderEnabled) }
        set { defaults.set(newValue, forKey: Keys.streakReminderEnabled) }
    }
    
    // MARK: - Onboarding
    
    /// 初回起動ガイドを完了したか
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    // MARK: - Appearance Settings
    /// 外観モード: 0=システム, 1=ライト, 2=ダーク（レガシー、ThemeManagerに移行）
    var appearanceMode: Int {
        get { defaults.integer(forKey: Keys.appearanceMode) }
        set { defaults.set(newValue, forKey: Keys.appearanceMode) }
    }
    
    // MARK: - Theme & Font Settings
    
    /// アプリテーマ（ThemeManagerと連携）
    var appTheme: AppTheme {
        get { ThemeManager.shared.currentTheme }
        set { ThemeManager.shared.currentTheme = newValue }
    }
    
    /// フォントサイズ（ThemeManagerと連携）
    var appFontSize: AppFontSize {
        get { ThemeManager.shared.fontSize }
        set { ThemeManager.shared.fontSize = newValue }
    }
    
    // MARK: - Saved Tags
    var savedTags: [Tag] {
        get {
            guard let data = defaults.data(forKey: Keys.savedTags),
                  let tags = try? JSONDecoder().decode([Tag].self, from: data) else {
                return Tag.presets
            }
            return tags
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.savedTags)
            }
        }
    }
    
    // MARK: - Init
    private init() {
        // 初回起動時のデフォルト設定
        if defaults.object(forKey: Keys.hapticEnabled) == nil {
            hapticEnabled = true
        }
        if defaults.object(forKey: Keys.soundEnabled) == nil {
            soundEnabled = true
        }
    }
    
    // MARK: - Methods
    
    /// 送信先が設定済みかチェック
    func isDestinationConfigured(_ destination: Destination) -> Bool {
        switch destination {
        case .notionInbox:
            return isNotionConfigured
        case .todoist:
            return isTodoistConfigured
        case .slack:
            return isSlackConfigured
        case .reflect:
            return isReflectConfigured
        case .emailToSelf:
            return isEmailConfigured
        case .taskTemplate, .noteTemplate:
            return true
        }
    }
    
    /// 設定をリセット
    func reset() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }
}


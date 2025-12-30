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
        static let notionAPIKey = "notionAPIKey"
        static let notionDatabaseId = "notionDatabaseId"
        static let todoistAPIKey = "todoistAPIKey"
        static let todoistProjectId = "todoistProjectId"
        static let slackBotToken = "slackBotToken"
        static let slackChannelId = "slackChannelId"
        static let reflectAPIKey = "reflectAPIKey"
        static let hapticEnabled = "hapticEnabled"
        static let soundEnabled = "soundEnabled"
        static let savedTags = "savedTags"
        static let appearanceMode = "appearanceMode"
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
    
    var isReflectConfigured: Bool {
        !reflectAPIKey.isEmpty
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
    
    // MARK: - Appearance Settings
    /// 外観モード: 0=システム, 1=ライト, 2=ダーク
    var appearanceMode: Int {
        get { defaults.integer(forKey: Keys.appearanceMode) }
        set { defaults.set(newValue, forKey: Keys.appearanceMode) }
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


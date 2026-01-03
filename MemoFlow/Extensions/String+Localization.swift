//
//  String+Localization.swift
//  MemoFlow
//
//  ローカライゼーションヘルパー
//  アプリ全体で使用するローカライズ文字列を一元管理
//

import SwiftUI

// MARK: - Localization Manager
/// 動的言語切り替えをサポートするローカライゼーションマネージャー
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    /// 現在の言語設定に基づいてBundleを取得
    var currentBundle: Bundle {
        let language = AppSettings.shared.appLanguage
        
        // システム設定の場合はメインバンドル
        guard language != .system else {
            return .main
        }
        
        // 指定言語のバンドルを取得
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        
        return bundle
    }
    
    /// ローカライズ文字列を取得
    func localized(_ key: String) -> String {
        currentBundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    /// フォーマット付きローカライズ文字列を取得
    func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = currentBundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: args)
    }
}

/// 簡易アクセス関数
func localized(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}

func localized(_ key: String, _ args: CVarArg...) -> String {
    let format = LocalizationManager.shared.currentBundle.localizedString(forKey: key, value: nil, table: nil)
    return String(format: format, arguments: args)
}

// MARK: - Localized String Keys
/// アプリ内で使用するローカライズキーを定義
/// 注意: 動的言語切り替えをサポートするため、computed propertyを使用
enum L10n {
    
    // MARK: - Common
    enum Common {
        static var done: String { localized("common.done") }
        static var cancel: String { localized("common.cancel") }
        static var close: String { localized("common.close") }
        static var ok: String { localized("common.ok") }
        static var error: String { localized("common.error") }
        static var success: String { localized("common.success") }
        static var save: String { localized("common.save") }
        static var delete: String { localized("common.delete") }
        static var edit: String { localized("common.edit") }
        static var send: String { localized("common.send") }
        static var retry: String { localized("common.retry") }
        static var settings: String { localized("common.settings") }
        static var version: String { localized("common.version") }
        static var premium: String { localized("common.premium") }
    }
    
    // MARK: - App
    enum App {
        static var name: String { localized("app.name") }
        static var tagline: String { localized("app.tagline") }
        static var description: String { localized("app.description") }
    }
    
    // MARK: - Capture
    enum Capture {
        static var placeholder: String { localized("capture.placeholder") }
        static var speakPrompt: String { localized("capture.speakPrompt") }
        static var adopt: String { localized("capture.adopt") }
        
        static func sendTo(_ destination: String) -> String {
            localized("capture.sendTo", destination)
        }
    }
    
    // MARK: - Streak
    enum Streak {
        static var title: String { localized("streak.title") }
        static var current: String { localized("streak.current") }
        static var longest: String { localized("streak.longest") }
        static var total: String { localized("streak.total") }
        static var todayComplete: String { localized("streak.todayComplete") }
        static var todayNotSent: String { localized("streak.todayNotSent") }
        static var daysConsecutive: String { localized("streak.daysConsecutive") }
        static var encouragement: String { localized("streak.encouragement") }
        
        static func days(_ count: Int) -> String {
            localized("streak.days", count)
        }
    }
    
    // MARK: - Destinations
    enum Destination {
        static var notionInbox: String { localized("destination.notionInbox") }
        static var todoist: String { localized("destination.todoist") }
        static var slack: String { localized("destination.slack") }
        static var reflect: String { localized("destination.reflect") }
        static var emailToSelf: String { localized("destination.emailToSelf") }
        static var task: String { localized("destination.task") }
        static var note: String { localized("destination.note") }
    }
    
    // MARK: - Theme
    enum Theme {
        static var system: String { localized("theme.system") }
        static var light: String { localized("theme.light") }
        static var dark: String { localized("theme.dark") }
        static var sepia: String { localized("theme.sepia") }
        static var blueLightCut: String { localized("theme.blueLightCut") }
        
        enum Description {
            static var system: String { localized("theme.system.description") }
            static var light: String { localized("theme.light.description") }
            static var dark: String { localized("theme.dark.description") }
            static var sepia: String { localized("theme.sepia.description") }
            static var blueLightCut: String { localized("theme.blueLightCut.description") }
        }
    }
    
    // MARK: - Font Size
    enum FontSize {
        static var standard: String { localized("fontSize.standard") }
        static var large: String { localized("fontSize.large") }
        static var extraLarge: String { localized("fontSize.extraLarge") }
    }
    
    // MARK: - Settings
    enum Settings {
        static var title: String { localized("settings.title") }
        static var general: String { localized("settings.general") }
        static var defaultDestination: String { localized("settings.defaultDestination") }
        static var aiTagSuggestion: String { localized("settings.aiTagSuggestion") }
        static var aiTemplateDetection: String { localized("settings.aiTemplateDetection") }
        static var themeAndFont: String { localized("settings.themeAndFont") }
        static var fontSize: String { localized("settings.fontSize") }
        static var theme: String { localized("settings.theme") }
        static var preview: String { localized("settings.preview") }
        static var previewText: String { localized("settings.previewText") }
        
        static func themeLabel(_ theme: String) -> String {
            localized("settings.themeLabel", theme)
        }
        
        static func fontSizeLabel(_ size: String) -> String {
            localized("settings.fontSizeLabel", size)
        }
        
        // Tag Modes
        enum TagMode {
            static var autoAdopt: String { localized("settings.tagMode.autoAdopt") }
            static var suggestOnly: String { localized("settings.tagMode.suggestOnly") }
            static var off: String { localized("settings.tagMode.off") }
            
            enum Description {
                static var autoAdopt: String { localized("settings.tagMode.autoAdopt.description") }
                static var suggestOnly: String { localized("settings.tagMode.suggestOnly.description") }
                static var off: String { localized("settings.tagMode.off.description") }
            }
        }
        
        // Template Modes
        enum TemplateMode {
            static var off: String { localized("settings.templateMode.off") }
            static var suggestOnly: String { localized("settings.templateMode.suggestOnly") }
            static var autoSwitch: String { localized("settings.templateMode.autoSwitch") }
            
            enum Description {
                static var off: String { localized("settings.templateMode.off.description") }
                static var suggestOnly: String { localized("settings.templateMode.suggestOnly.description") }
                static var autoSwitch: String { localized("settings.templateMode.autoSwitch.description") }
            }
        }
        
        // Feedback
        static var feedback: String { localized("settings.feedback") }
        static var hapticFeedback: String { localized("settings.hapticFeedback") }
        static var sound: String { localized("settings.sound") }
        
        // Streak
        static var streak: String { localized("settings.streak") }
        static var streakDisplay: String { localized("settings.streakDisplay") }
        static var streakReminder: String { localized("settings.streakReminder") }
        static var todayComplete: String { localized("settings.todayComplete") }
        
        // AI
        static var aiSettings: String { localized("settings.aiSettings") }
        static var appleIntelligence: String { localized("settings.appleIntelligence") }
        static var localAIPriority: String { localized("settings.localAIPriority") }
        static var onDevice: String { localized("settings.onDevice") }
        static var localAIPrivacy: String { localized("settings.localAIPrivacy") }
        static var localAIEnabledDescription: String { localized("settings.localAIEnabled.description") }
        static var localAIDisabledDescription: String { localized("settings.localAIDisabled.description") }
        
        // API
        static var apiKey: String { localized("settings.apiKey") }
        static var apiToken: String { localized("settings.apiToken") }
        static var databaseId: String { localized("settings.databaseId") }
        static var projectId: String { localized("settings.projectId") }
        static var botToken: String { localized("settings.botToken") }
        static var channelId: String { localized("settings.channelId") }
        static var graphId: String { localized("settings.graphId") }
        static var emailAddress: String { localized("settings.emailAddress") }
        static var connectionTest: String { localized("settings.connectionTest") }
        
        // Integrations
        static var notion: String { localized("settings.notion") }
        static var todoist: String { localized("settings.todoist") }
        static var slack: String { localized("settings.slack") }
        static var reflect: String { localized("settings.reflect") }
        static var emailToSelf: String { localized("settings.emailToSelf") }
        
        enum IntegrationDescription {
            static var notion: String { localized("settings.notion.description") }
            static var todoist: String { localized("settings.todoist.description") }
            static var slack: String { localized("settings.slack.description") }
            static var reflect: String { localized("settings.reflect.description") }
            static var email: String { localized("settings.email.description") }
            static var emailNotAvailable: String { localized("settings.email.notAvailable") }
        }
        
        // Placeholders
        enum Placeholder {
            static var secret: String { localized("settings.placeholder.secret") }
            static var apiToken: String { localized("settings.placeholder.apiToken") }
            static var xoxb: String { localized("settings.placeholder.xoxb") }
            static var apiKey: String { localized("settings.placeholder.apiKey") }
        }
        
        // Support
        static var support: String { localized("settings.support") }
        static var helpAndGuide: String { localized("settings.helpAndGuide") }
        static var helpDescription: String { localized("settings.helpDescription") }
        static var contactSupport: String { localized("settings.contactSupport") }
        
        // Legal
        static var legal: String { localized("settings.legal") }
        static var privacyPolicy: String { localized("settings.privacyPolicy") }
        static var termsOfUse: String { localized("settings.termsOfUse") }
        static var cancelSubscription: String { localized("settings.cancelSubscription") }
        static var copyright: String { localized("settings.copyright") }
        
        // Reset
        static var resetAll: String { localized("settings.resetAll") }
    }
    
    // MARK: - Premium
    enum Premium {
        static var title: String { localized("premium.title") }
        static var tagline: String { localized("premium.tagline") }
        static var upgradeButton: String { localized("premium.upgradeButton") }
        static var restore: String { localized("premium.restore") }
        static var trial: String { localized("premium.trial") }
        static var cancelAnytime: String { localized("premium.cancelAnytime") }
        static var terms: String { localized("premium.terms") }
        static var privacy: String { localized("premium.privacy") }
        static var manageSubscription: String { localized("premium.manageSubscription") }
        static var badge: String { localized("premium.badge") }
        static var features: String { localized("premium.features") }
        static var unlockDescription: String { localized("premium.unlockDescription") }
        static var trialInfo: String { localized("premium.trialInfo") }
        
        static func nextRenewal(_ date: String) -> String {
            localized("premium.nextRenewal", date)
        }
        
        static func autoRenew(_ price: String) -> String {
            localized("premium.autoRenew", price)
        }
        
        static func trialDays(_ count: Int) -> String {
            localized("premium.trialDays", count)
        }
        
        static func featureUpsell(_ feature: String) -> String {
            localized("premium.featureUpsell", feature)
        }
        
        enum Feature {
            static var unlimited: String { localized("premium.feature.unlimited") }
            static var unlimitedDescription: String { localized("premium.feature.unlimited.description") }
            static var ai: String { localized("premium.feature.ai") }
            static var aiDescription: String { localized("premium.feature.ai.description") }
            static var themes: String { localized("premium.feature.themes") }
            static var themesDescription: String { localized("premium.feature.themes.description") }
        }
        
        enum Error {
            static var purchase: String { localized("premium.error.purchase") }
            static var noRestore: String { localized("premium.error.noRestore") }
            static var restoreFailed: String { localized("premium.error.restoreFailed") }
        }
    }
    
    // MARK: - Help
    enum Help {
        static var title: String { localized("help.title") }
        static var integrationGuides: String { localized("help.integrationGuides") }
        static var support: String { localized("help.support") }
        static var contactUs: String { localized("help.contactUs") }
        static var contactDescription: String { localized("help.contactDescription") }
        
        enum QuickStart {
            static var title: String { localized("help.quickStart.title") }
            static var subtitle: String { localized("help.quickStart.subtitle") }
            static var intro: String { localized("help.quickStart.intro") }
            static var header: String { localized("help.quickStart.header") }
            static var proTips: String { localized("help.quickStart.proTips") }
            static var tip1: String { localized("help.quickStart.tip1") }
            static var tip2: String { localized("help.quickStart.tip2") }
            static var tip3: String { localized("help.quickStart.tip3") }
        }
        
        enum Notion {
            static var title: String { localized("help.notion.title") }
            static var subtitle: String { localized("help.notion.subtitle") }
            static var header: String { localized("help.notion.header") }
            static var intro: String { localized("help.notion.intro") }
            static var complete: String { localized("help.notion.complete") }
            static var completeDescription: String { localized("help.notion.completeDescription") }
        }
        
        enum Todoist {
            static var title: String { localized("help.todoist.title") }
            static var subtitle: String { localized("help.todoist.subtitle") }
            static var header: String { localized("help.todoist.header") }
            static var intro: String { localized("help.todoist.intro") }
        }
        
        enum Slack {
            static var title: String { localized("help.slack.title") }
            static var subtitle: String { localized("help.slack.subtitle") }
        }
        
        enum Reflect {
            static var title: String { localized("help.reflect.title") }
            static var subtitle: String { localized("help.reflect.subtitle") }
        }
        
        enum Troubleshooting {
            static var title: String { localized("help.troubleshooting.title") }
            static var subtitle: String { localized("help.troubleshooting.subtitle") }
        }
        
        enum FAQ {
            static var title: String { localized("help.faq.title") }
            static var subtitle: String { localized("help.faq.subtitle") }
        }
    }
    
    // MARK: - History
    enum History {
        static var title: String { localized("history.title") }
        static var empty: String { localized("history.empty") }
        static var resend: String { localized("history.resend") }
        static var deleteConfirm: String { localized("history.deleteConfirm") }
        
        static func count(_ count: Int) -> String {
            localized("history.count", count)
        }
    }
    
    // MARK: - Onboarding
    enum Onboarding {
        static var welcome: String { localized("onboarding.welcome") }
        static var getStarted: String { localized("onboarding.getStarted") }
        static var next: String { localized("onboarding.next") }
        static var skip: String { localized("onboarding.skip") }
    }
    
    // MARK: - Errors
    enum Error {
        static var network: String { localized("error.network") }
        static var sendFailed: String { localized("error.sendFailed") }
        static var apiKeyMissing: String { localized("error.apiKeyMissing") }
        static var unauthorized: String { localized("error.unauthorized") }
        static var notConfigured: String { localized("error.notConfigured") }
        static var unknown: String { localized("error.unknown") }
    }
    
    // MARK: - Tags
    enum Tag {
        static var task: String { localized("tag.task") }
        static var idea: String { localized("tag.idea") }
        static var memo: String { localized("tag.memo") }
        static var work: String { localized("tag.work") }
        static var privateTag: String { localized("tag.private") }
        static var shopping: String { localized("tag.shopping") }
        static var meeting: String { localized("tag.meeting") }
        static var project: String { localized("tag.project") }
        static var health: String { localized("tag.health") }
        static var study: String { localized("tag.study") }
        
        static func count(_ count: Int) -> String {
            localized("tag.count", count)
        }
    }
    
    // MARK: - Notifications
    enum Notification {
        enum StreakReminder {
            static var title: String { localized("notification.streakReminder.title") }
            static var body: String { localized("notification.streakReminder.body") }
        }
        
        enum StreakLost {
            static var title: String { localized("notification.streakLost.title") }
            static var body: String { localized("notification.streakLost.body") }
        }
    }
    
    // MARK: - Widget
    enum Widget {
        static var quickCapture: String { localized("widget.quickCapture") }
        static var tapToCapture: String { localized("widget.tapToCapture") }
        static var streak: String { localized("widget.streak") }
    }
}

// MARK: - LocalizedStringKey Extension for SwiftUI
extension LocalizedStringKey {
    /// プレビュー用に特定の言語でローカライズされた文字列を取得
    func localized(for locale: Locale = .current) -> String {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let key = child.value as? String {
                let path = Bundle.main.path(forResource: locale.language.languageCode?.identifier ?? "ja", ofType: "lproj")
                let bundle = path != nil ? Bundle(path: path!) ?? .main : .main
                return NSLocalizedString(key, bundle: bundle, comment: "")
            }
        }
        return ""
    }
}

// MARK: - Preview Helper
/// プレビューで言語を切り替えるためのモディファイア
struct LocalizationPreview: ViewModifier {
    let locale: Locale
    
    func body(content: Content) -> some View {
        content
            .environment(\.locale, locale)
    }
}

extension View {
    /// プレビュー用に言語を設定
    func previewLocale(_ locale: Locale) -> some View {
        modifier(LocalizationPreview(locale: locale))
    }
    
    /// 日本語プレビュー
    func previewJapanese() -> some View {
        previewLocale(Locale(identifier: "ja"))
    }
    
    /// 英語プレビュー
    func previewEnglish() -> some View {
        previewLocale(Locale(identifier: "en"))
    }
}

// MARK: - Supported Locales
enum SupportedLocale: String, CaseIterable {
    case japanese = "ja"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portugueseBrazil = "pt-BR"
    
    var locale: Locale {
        Locale(identifier: rawValue)
    }
    
    var displayName: String {
        switch self {
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .korean:
            return "한국어"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .portugueseBrazil:
            return "Português (Brasil)"
        }
    }
    
    var flag: String {
        switch self {
        case .japanese:
            return "🇯🇵"
        case .english:
            return "🇺🇸"
        case .simplifiedChinese:
            return "🇨🇳"
        case .korean:
            return "🇰🇷"
        case .spanish:
            return "🇪🇸"
        case .french:
            return "🇫🇷"
        case .german:
            return "🇩🇪"
        case .portugueseBrazil:
            return "🇧🇷"
        }
    }
}

extension View {
    /// 簡体中国語プレビュー
    func previewSimplifiedChinese() -> some View {
        previewLocale(Locale(identifier: "zh-Hans"))
    }
    
    /// 韓国語プレビュー
    func previewKorean() -> some View {
        previewLocale(Locale(identifier: "ko"))
    }
    
    /// スペイン語プレビュー
    func previewSpanish() -> some View {
        previewLocale(Locale(identifier: "es"))
    }
    
    /// フランス語プレビュー
    func previewFrench() -> some View {
        previewLocale(Locale(identifier: "fr"))
    }
    
    /// ドイツ語プレビュー
    func previewGerman() -> some View {
        previewLocale(Locale(identifier: "de"))
    }
    
    /// ブラジルポルトガル語プレビュー
    func previewPortugueseBrazil() -> some View {
        previewLocale(Locale(identifier: "pt-BR"))
    }
}

// MARK: - App Language Setting
/// アプリ言語設定（設定画面から選択可能）
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case japanese = "ja"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portugueseBrazil = "pt-BR"
    
    var id: String { rawValue }
    
    /// 表示名（常に各言語のネイティブ名を表示）
    var displayName: String {
        switch self {
        case .system:
            return "🌐 " + localized("language.system")
        case .japanese:
            return "🇯🇵 日本語"
        case .english:
            return "🇺🇸 English"
        case .simplifiedChinese:
            return "🇨🇳 简体中文"
        case .korean:
            return "🇰🇷 한국어"
        case .spanish:
            return "🇪🇸 Español"
        case .french:
            return "🇫🇷 Français"
        case .german:
            return "🇩🇪 Deutsch"
        case .portugueseBrazil:
            return "🇧🇷 Português (Brasil)"
        }
    }
    
    /// 対応するLocale（nilはシステム設定に従う）
    var locale: Locale? {
        switch self {
        case .system:
            return nil
        case .japanese:
            return Locale(identifier: "ja")
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        case .korean:
            return Locale(identifier: "ko")
        case .spanish:
            return Locale(identifier: "es")
        case .french:
            return Locale(identifier: "fr")
        case .german:
            return Locale(identifier: "de")
        case .portugueseBrazil:
            return Locale(identifier: "pt-BR")
        }
    }
    
    /// 短い表示名（設定セクション用）
    var shortName: String {
        switch self {
        case .system:
            return localized("language.system")
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .korean:
            return "한국어"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .portugueseBrazil:
            return "Português (Brasil)"
        }
    }
}

// MARK: - Language Environment Modifier
/// アプリ全体の言語を設定するモディファイア
struct AppLanguageModifier: ViewModifier {
    let language: AppLanguage
    
    func body(content: Content) -> some View {
        if let locale = language.locale {
            content
                .environment(\.locale, locale)
        } else {
            content // システム設定に従う
        }
    }
}

extension View {
    /// アプリ言語を設定
    func appLanguage(_ language: AppLanguage) -> some View {
        modifier(AppLanguageModifier(language: language))
    }
}


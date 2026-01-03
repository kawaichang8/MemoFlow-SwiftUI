//
//  Models+Localization.swift
//  MemoFlow
//
//  モデルのローカライズ拡張
//  各モデルのdisplayNameをローカライズされた文字列に対応
//

import SwiftUI

// MARK: - Destination Localization
extension Destination {
    /// ローカライズされた表示名
    var localizedDisplayName: String {
        switch self {
        case .notionInbox:
            return L10n.Destination.notionInbox
        case .todoist:
            return L10n.Destination.todoist
        case .slack:
            return L10n.Destination.slack
        case .reflect:
            return L10n.Destination.reflect
        case .emailToSelf:
            return L10n.Destination.emailToSelf
        case .taskTemplate:
            return L10n.Destination.task
        case .noteTemplate:
            return L10n.Destination.note
        }
    }
}

// MARK: - AppTheme Localization
extension AppTheme {
    /// ローカライズされた表示名
    var localizedDisplayName: String {
        switch self {
        case .system:
            return L10n.Theme.system
        case .light:
            return L10n.Theme.light
        case .dark:
            return L10n.Theme.dark
        case .sepia:
            return L10n.Theme.sepia
        case .blueLightCut:
            return L10n.Theme.blueLightCut
        }
    }
    
    /// ローカライズされた説明
    var localizedDescription: String {
        switch self {
        case .system:
            return L10n.Theme.Description.system
        case .light:
            return L10n.Theme.Description.light
        case .dark:
            return L10n.Theme.Description.dark
        case .sepia:
            return L10n.Theme.Description.sepia
        case .blueLightCut:
            return L10n.Theme.Description.blueLightCut
        }
    }
}

// MARK: - AppFontSize Localization
extension AppFontSize {
    /// ローカライズされた表示名
    var localizedDisplayName: String {
        switch self {
        case .standard:
            return L10n.FontSize.standard
        case .large:
            return L10n.FontSize.large
        case .extraLarge:
            return L10n.FontSize.extraLarge
        }
    }
}

// MARK: - TagAutoMode Localization
extension TagAutoMode {
    /// ローカライズされた表示名
    var localizedDisplayName: String {
        switch self {
        case .autoAdopt:
            return L10n.Settings.TagMode.autoAdopt
        case .suggestOnly:
            return L10n.Settings.TagMode.suggestOnly
        case .off:
            return L10n.Settings.TagMode.off
        }
    }
}

// MARK: - TemplateSuggestionMode Localization
extension TemplateSuggestionMode {
    /// ローカライズされた表示名
    var localizedDisplayName: String {
        switch self {
        case .off:
            return L10n.Settings.TemplateMode.off
        case .suggestOnly:
            return L10n.Settings.TemplateMode.suggestOnly
        case .autoSwitch:
            return L10n.Settings.TemplateMode.autoSwitch
        }
    }
}

// MARK: - TemplateType Localization
extension TemplateType {
    /// ローカライズされた表示名
    var localizedDisplayName: String {
        switch self {
        case .task:
            return L10n.Destination.task
        case .note:
            return L10n.Destination.note
        case .unknown:
            return displayName // 元のdisplayNameを使用（"不明"）
        }
    }
}


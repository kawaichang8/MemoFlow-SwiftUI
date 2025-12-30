//
//  TemplateType.swift
//  MemoFlow
//
//  AI自動テンプレート判別用の型定義
//

import Foundation
import SwiftUI

/// テンプレートタイプ（タスク or ノート）
enum TemplateType: String, Codable, CaseIterable, Identifiable {
    case task = "task"
    case note = "note"
    case unknown = "unknown"
    
    var id: String { rawValue }
    
    /// 表示名
    var displayName: String {
        switch self {
        case .task:
            return "タスク"
        case .note:
            return "ノート"
        case .unknown:
            return "不明"
        }
    }
    
    /// アイコン名（SF Symbols）
    var iconName: String {
        switch self {
        case .task:
            return "checklist"
        case .note:
            return "note.text"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    /// カラー
    var color: Color {
        switch self {
        case .task:
            return .blue
        case .note:
            return .green
        case .unknown:
            return .gray
        }
    }
    
    /// 対応する送信先
    var suggestedDestination: Destination {
        switch self {
        case .task:
            return .todoist
        case .note:
            return .notionInbox
        case .unknown:
            return .notionInbox
        }
    }
    
    /// 提案メッセージ
    var suggestionMessage: String {
        switch self {
        case .task:
            return "タスクとして送る？"
        case .note:
            return "ノートとして送る？"
        case .unknown:
            return ""
        }
    }
}

/// テンプレート提案モード
enum TemplateSuggestionMode: String, Codable, CaseIterable, Identifiable {
    case off = "off"
    case suggestOnly = "suggest_only"
    case autoSwitch = "auto_switch"
    
    var id: String { rawValue }
    
    /// 表示名
    var displayName: String {
        switch self {
        case .off:
            return "オフ"
        case .suggestOnly:
            return "提案のみ"
        case .autoSwitch:
            return "自動切り替え"
        }
    }
    
    /// 説明
    var description: String {
        switch self {
        case .off:
            return "テンプレート判別を使用しません"
        case .suggestOnly:
            return "バナーで提案、タップで採用"
        case .autoSwitch:
            return "自動で送信先を切り替え"
        }
    }
}

/// テンプレート提案結果
struct TemplateSuggestion: Equatable {
    let type: TemplateType
    let confidence: Float  // 0.0 - 1.0
    let suggestedDestination: Destination
    
    var isConfident: Bool {
        confidence >= 0.6
    }
    
    static let empty = TemplateSuggestion(type: .unknown, confidence: 0, suggestedDestination: .notionInbox)
}


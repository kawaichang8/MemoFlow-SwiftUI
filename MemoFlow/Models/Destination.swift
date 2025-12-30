//
//  Destination.swift
//  MemoFlow
//
//  送信先の定義
//

import Foundation
import SwiftUI

/// 送信先の種類
enum Destination: String, Codable, CaseIterable, Identifiable {
    case notionInbox = "notion_inbox"
    case todoist = "todoist"
    case slack = "slack"
    case reflect = "reflect"
    case taskTemplate = "task_template"
    case noteTemplate = "note_template"
    
    var id: String { rawValue }
    
    /// 表示名
    var displayName: String {
        switch self {
        case .notionInbox:
            return "Notion Inbox"
        case .todoist:
            return "Todoist"
        case .slack:
            return "Slack"
        case .reflect:
            return "Reflect"
        case .taskTemplate:
            return "タスク"
        case .noteTemplate:
            return "ノート"
        }
    }
    
    /// アイコン名（SF Symbols）
    var iconName: String {
        switch self {
        case .notionInbox:
            return "tray.and.arrow.down"
        case .todoist:
            return "checkmark.circle"
        case .slack:
            return "number.square"
        case .reflect:
            return "brain.head.profile"
        case .taskTemplate:
            return "checklist"
        case .noteTemplate:
            return "note.text"
        }
    }
    
    /// カラー
    var color: Color {
        switch self {
        case .notionInbox:
            return .primary
        case .todoist:
            return .red
        case .slack:
            return Color(red: 0.32, green: 0.71, blue: 0.67) // Slackのブランドカラー（緑系）
        case .reflect:
            return .purple
        case .taskTemplate:
            return .blue
        case .noteTemplate:
            return .green
        }
    }
    
    /// この送信先がAPI設定を必要とするか
    var requiresAPIKey: Bool {
        switch self {
        case .notionInbox, .todoist, .slack, .reflect:
            return true
        case .taskTemplate, .noteTemplate:
            return false
        }
    }
}

// MARK: - 送信先設定
struct DestinationConfig: Codable {
    var destination: Destination
    var isEnabled: Bool
    var apiKey: String?
    var databaseId: String?  // Notion用
    var projectId: String?   // Todoist用
    var channelId: String?   // Slack用
    
    init(destination: Destination) {
        self.destination = destination
        self.isEnabled = !destination.requiresAPIKey
        self.apiKey = nil
        self.databaseId = nil
        self.projectId = nil
        self.channelId = nil
    }
}


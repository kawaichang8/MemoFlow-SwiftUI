//
//  Tag.swift
//  MemoFlow
//
//  タグモデル（AI自動提案対応）
//

import Foundation
import SwiftUI

/// タグの状態
enum TagState: String, Codable {
    case suggested  // AI提案中
    case adopted    // 採用済み
    case dismissed  // 却下済み
}

/// タグモデル
struct Tag: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var state: TagState
    var usageCount: Int      // 採用回数（優先度計算用）
    var lastUsedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        state: TagState = .suggested,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
    }
    
    /// 採用率スコア（高いほど優先表示）
    var priorityScore: Double {
        Double(usageCount) + (lastUsedAt != nil ? 1.0 : 0.0)
    }
}

// MARK: - タグ設定
enum TagAutoMode: String, Codable, CaseIterable {
    case autoAdopt = "auto"      // 自動採用
    case suggestOnly = "suggest" // 提案のみ（デフォルト）
    case off = "off"             // オフ
    
    var displayName: String {
        switch self {
        case .autoAdopt:
            return "自動採用"
        case .suggestOnly:
            return "提案のみ"
        case .off:
            return "オフ"
        }
    }
    
    var description: String {
        switch self {
        case .autoAdopt:
            return "AIが提案したタグを自動的に採用"
        case .suggestOnly:
            return "タップで採用・削除（デフォルト）"
        case .off:
            return "タグ提案を無効化"
        }
    }
}

// MARK: - プリセットタグ
extension Tag {
    static let presets: [Tag] = [
        Tag(name: "メモ"),
        Tag(name: "アイデア"),
        Tag(name: "タスク"),
        Tag(name: "買い物"),
        Tag(name: "調査"),
        Tag(name: "ミーティング"),
        Tag(name: "あとで"),
        Tag(name: "重要"),
        Tag(name: "プロジェクト"),
        Tag(name: "読書"),
        Tag(name: "学習"),
        Tag(name: "グルメ"),
        Tag(name: "レシピ"),
        Tag(name: "健康"),
        Tag(name: "お金"),
        Tag(name: "旅行"),
        Tag(name: "連絡"),
        Tag(name: "予定"),
    ]
}


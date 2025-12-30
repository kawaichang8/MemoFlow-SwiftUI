//
//  MemoHistoryItem.swift
//  MemoFlow
//
//  送信履歴用SwiftDataモデル
//

import Foundation
import SwiftData

/// 送信履歴アイテム（SwiftData永続化）
@Model
final class MemoHistoryItem {
    // MARK: - Properties
    
    /// 一意識別子
    @Attribute(.unique) var id: UUID
    
    /// メモ本文
    var content: String
    
    /// タグ（JSON文字列で保存）
    var tagsJSON: String
    
    /// 送信先
    var destinationRaw: String
    
    /// 作成日時
    var createdAt: Date
    
    /// 送信日時
    var sentAt: Date
    
    // MARK: - Computed Properties
    
    /// 送信先（Destination型）
    var destination: Destination {
        get {
            Destination(rawValue: destinationRaw) ?? .notionInbox
        }
        set {
            destinationRaw = newValue.rawValue
        }
    }
    
    /// タグ配列
    var tags: [Tag] {
        get {
            guard let data = tagsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([Tag].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                tagsJSON = json
            } else {
                tagsJSON = "[]"
            }
        }
    }
    
    /// 先頭30文字
    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 30 {
            return trimmed
        }
        return String(trimmed.prefix(30)) + "..."
    }
    
    /// 日時フォーマット済み
    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(sentAt) {
            formatter.dateFormat = "HH:mm"
            return "今日 " + formatter.string(from: sentAt)
        } else if calendar.isDateInYesterday(sentAt) {
            formatter.dateFormat = "HH:mm"
            return "昨日 " + formatter.string(from: sentAt)
        } else {
            formatter.dateFormat = "M/d HH:mm"
            return formatter.string(from: sentAt)
        }
    }
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        content: String,
        tags: [Tag] = [],
        destination: Destination,
        createdAt: Date = Date(),
        sentAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.destinationRaw = destination.rawValue
        self.createdAt = createdAt
        self.sentAt = sentAt
        
        // タグをJSONにエンコード
        if let data = try? JSONEncoder().encode(tags),
           let json = String(data: data, encoding: .utf8) {
            self.tagsJSON = json
        } else {
            self.tagsJSON = "[]"
        }
    }
    
    /// Memoから変換
    convenience init(from memo: Memo) {
        self.init(
            id: memo.id,
            content: memo.content,
            tags: memo.tags,
            destination: memo.destination,
            createdAt: memo.createdAt,
            sentAt: Date()
        )
    }
    
    /// Memoに変換
    func toMemo() -> Memo {
        Memo(
            id: id,
            content: content,
            tags: tags,
            destination: destination,
            status: .sent,
            createdAt: createdAt,
            sentAt: sentAt
        )
    }
}


//
//  Memo.swift
//  MemoFlow
//
//  GTDキャプチャ用メモモデル
//

import Foundation

/// メモの状態を表す列挙型
enum MemoStatus: String, Codable {
    case draft      // 下書き
    case sending    // 送信中
    case sent       // 送信完了
    case failed     // 送信失敗
}

/// キャプチャされたメモ
struct Memo: Identifiable, Codable {
    let id: UUID
    var content: String
    var tags: [Tag]
    var destination: Destination
    var status: MemoStatus
    let createdAt: Date
    var sentAt: Date?
    
    init(
        id: UUID = UUID(),
        content: String = "",
        tags: [Tag] = [],
        destination: Destination = .notionInbox,
        status: MemoStatus = .draft,
        createdAt: Date = Date(),
        sentAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.tags = tags
        self.destination = destination
        self.status = status
        self.createdAt = createdAt
        self.sentAt = sentAt
    }
    
    /// メモが空かどうか
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Equatable
extension Memo: Equatable {
    static func == (lhs: Memo, rhs: Memo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Memo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


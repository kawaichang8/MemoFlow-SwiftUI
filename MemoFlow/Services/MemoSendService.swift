//
//  MemoSendService.swift
//  MemoFlow
//
//  メモ送信統合サービス
//

import Foundation

/// 送信結果
enum SendResult {
    case success
    case failure(Error)
}

/// メモ送信サービス
actor MemoSendService {
    // MARK: - Singleton
    static let shared = MemoSendService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// メモを指定先に送信
    func send(_ memo: Memo) async -> SendResult {
        do {
            switch memo.destination {
            case .notionInbox:
                try await NotionService.shared.addMemo(memo)
                
            case .todoist:
                try await TodoistService.shared.addMemo(memo)
                
            case .slack:
                try await SlackService.shared.addMemo(memo)
                
            case .reflect:
                // Reflect API（将来実装）
                try await sendToReflect(memo)
                
            case .taskTemplate:
                // ローカルタスクテンプレート保存
                try await saveAsTaskTemplate(memo)
                
            case .noteTemplate:
                // ローカルノートテンプレート保存
                try await saveAsNoteTemplate(memo)
            }
            
            return .success
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func sendToReflect(_ memo: Memo) async throws {
        // Reflect APIは将来実装
        // 現在はローカル保存にフォールバック
        try await saveLocally(memo, type: "reflect")
    }
    
    private func saveAsTaskTemplate(_ memo: Memo) async throws {
        try await saveLocally(memo, type: "task")
    }
    
    private func saveAsNoteTemplate(_ memo: Memo) async throws {
        try await saveLocally(memo, type: "note")
    }
    
    private func saveLocally(_ memo: Memo, type: String) async throws {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "MemoFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "ドキュメントフォルダが見つかりません"])
        }
        
        let memosURL = documentsURL.appendingPathComponent("memos")
        
        // フォルダ作成
        if !fileManager.fileExists(atPath: memosURL.path) {
            try fileManager.createDirectory(at: memosURL, withIntermediateDirectories: true)
        }
        
        // メモを保存
        let fileName = "\(type)_\(memo.id.uuidString).json"
        let fileURL = memosURL.appendingPathComponent(fileName)
        
        let data = try JSONEncoder().encode(memo)
        try data.write(to: fileURL)
    }
}

// MARK: - 送信履歴管理
extension MemoSendService {
    /// 送信履歴を保存
    func saveToHistory(_ memo: Memo) async {
        var history = loadHistory()
        
        var sentMemo = memo
        sentMemo.status = .sent
        sentMemo.sentAt = Date()
        
        history.insert(sentMemo, at: 0)
        
        // 最大100件保持
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        saveHistory(history)
    }
    
    /// 履歴を読み込み
    func loadHistory() -> [Memo] {
        guard let data = UserDefaults.standard.data(forKey: "memoHistory"),
              let history = try? JSONDecoder().decode([Memo].self, from: data) else {
            return []
        }
        return history
    }
    
    private func saveHistory(_ history: [Memo]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "memoHistory")
        }
    }
}


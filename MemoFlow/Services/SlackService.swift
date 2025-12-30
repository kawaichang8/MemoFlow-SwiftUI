//
//  SlackService.swift
//  MemoFlow
//
//  Slack API連携サービス
//

import Foundation

/// Slack APIエラー
enum SlackError: LocalizedError {
    case notConfigured
    case invalidResponse
    case invalidChannel
    case unauthorized
    case channelNotFound
    case rateLimited
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "送信失敗: Slackが設定されていません。設定画面でBot TokenとチャンネルIDを入力してください。"
        case .invalidResponse:
            return "送信失敗: Slackからの応答を解析できませんでした。"
        case .invalidChannel:
            return "送信失敗: チャンネルIDが無効です。正しいIDを入力してください。"
        case .unauthorized:
            return "送信失敗: Bot Tokenが無効か、チャンネルへのアクセス権限がありません。Botをチャンネルに招待してください。"
        case .channelNotFound:
            return "送信失敗: チャンネルが見つかりません。IDを確認するか、Botがチャンネルに参加しているか確認してください。"
        case .rateLimited:
            return "送信失敗: APIレート制限に達しました。しばらく待ってから再試行してください。"
        case .apiError(let message):
            return "送信失敗: \(message)"
        case .networkError(let error):
            return "送信失敗: ネットワークエラー - \(error.localizedDescription)"
        }
    }
}

/// Slack APIサービス
final class SlackService: @unchecked Sendable {
    // MARK: - Singleton
    static let shared = SlackService()
    
    private let baseURL = "https://slack.com/api"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// メモをSlackチャンネルに送信
    func addMemo(_ memo: Memo) async throws {
        // 設定を取得
        let botToken = await MainActor.run { AppSettings.shared.slackBotToken }
        let channelId = await MainActor.run { AppSettings.shared.slackChannelId }
        let isConfigured = await MainActor.run { AppSettings.shared.isSlackConfigured }
        
        guard isConfigured else {
            throw SlackError.notConfigured
        }
        
        print("[SlackService] 送信開始: channelId=\(channelId)")
        
        let url = URL(string: "\(baseURL)/chat.postMessage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let body = createMessageBody(memo: memo, channelId: channelId)
        
        // デバッグ: リクエストボディを出力
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[SlackService] リクエストボディ:\n\(jsonString)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SlackError.invalidResponse
            }
            
            print("[SlackService] レスポンスステータス: \(httpResponse.statusCode)")
            
            // レスポンスを解析
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw SlackError.invalidResponse
            }
            
            // デバッグ: レスポンスを出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("[SlackService] レスポンス:\n\(responseString)")
            }
            
            // Slack APIは200でもエラーの場合がある
            guard let ok = json["ok"] as? Bool, ok else {
                let error = json["error"] as? String ?? "unknown_error"
                throw parseSlackError(error: error)
            }
            
            print("[SlackService] 送信成功!")
            
        } catch let error as SlackError {
            throw error
        } catch {
            throw SlackError.networkError(error)
        }
    }
    
    /// 接続テスト
    func testConnection() async throws -> Bool {
        let botToken = await MainActor.run { AppSettings.shared.slackBotToken }
        let channelId = await MainActor.run { AppSettings.shared.slackChannelId }
        let isConfigured = await MainActor.run { AppSettings.shared.isSlackConfigured }
        
        guard isConfigured else {
            throw SlackError.notConfigured
        }
        
        // チャンネル情報を取得してテスト
        let url = URL(string: "\(baseURL)/conversations.info?channel=\(channelId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ok = json["ok"] as? Bool else {
            throw SlackError.invalidResponse
        }
        
        if !ok {
            let error = json["error"] as? String ?? "unknown_error"
            throw parseSlackError(error: error)
        }
        
        print("[SlackService] 接続テスト成功")
        return true
    }
    
    // MARK: - Private Methods
    
    /// メッセージ作成用のリクエストボディを生成
    private func createMessageBody(memo: Memo, channelId: String) -> [String: Any] {
        // タグがある場合はテキストに追加
        let adoptedTags = memo.tags.filter { $0.state == .adopted }
        var text = memo.content
        
        if !adoptedTags.isEmpty {
            let tagText = adoptedTags.map { "#\($0.name)" }.joined(separator: " ")
            text = "\(memo.content)\n\n\(tagText)"
        }
        
        // Block Kit を使ってリッチなメッセージを作成
        var blocks: [[String: Any]] = [
            [
                "type": "section",
                "text": [
                    "type": "mrkdwn",
                    "text": memo.content
                ]
            ]
        ]
        
        // タグがある場合はコンテキストブロックを追加
        if !adoptedTags.isEmpty {
            let tagElements: [[String: Any]] = adoptedTags.map { tag in
                [
                    "type": "mrkdwn",
                    "text": "`#\(tag.name)`"
                ]
            }
            blocks.append([
                "type": "context",
                "elements": tagElements
            ])
        }
        
        // タイムスタンプを追加
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        let timestamp = formatter.string(from: Date())
        
        blocks.append([
            "type": "context",
            "elements": [
                [
                    "type": "mrkdwn",
                    "text": "📝 MemoFlow • \(timestamp)"
                ]
            ]
        ])
        
        return [
            "channel": channelId,
            "text": text,  // フォールバック用テキスト
            "blocks": blocks
        ]
    }
    
    /// Slack APIエラーを解析
    private func parseSlackError(error: String) -> SlackError {
        switch error {
        case "not_authed", "invalid_auth", "account_inactive", "token_revoked", "token_expired":
            return .unauthorized
        case "channel_not_found":
            return .channelNotFound
        case "invalid_channel":
            return .invalidChannel
        case "rate_limited", "ratelimited":
            return .rateLimited
        default:
            return .apiError(error)
        }
    }
}


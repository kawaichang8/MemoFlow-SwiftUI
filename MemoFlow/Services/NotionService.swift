//
//  NotionService.swift
//  MemoFlow
//
//  Notion API連携サービス
//

import Foundation

/// Notion APIエラー
enum NotionError: LocalizedError {
    case notConfigured
    case invalidResponse
    case invalidDatabaseId
    case unauthorized
    case databaseNotFound
    case noTitleProperty
    case propertyError(String)
    case apiError(String, code: String?)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "送信失敗: Notion APIが設定されていません。設定画面でAPIキーとデータベースIDを入力してください。"
        case .invalidResponse:
            return "送信失敗: Notionからの応答を解析できませんでした。"
        case .invalidDatabaseId:
            return "送信失敗: データベースIDが無効です。正しいIDを入力してください。"
        case .unauthorized:
            return "送信失敗: APIキーが無効か、データベースへのアクセス権限がありません。インテグレーションをデータベースに接続してください。"
        case .databaseNotFound:
            return "送信失敗: データベースが見つかりません。IDを確認するか、インテグレーションの接続を確認してください。"
        case .noTitleProperty:
            return "送信失敗: データベースにタイトルプロパティが見つかりません。"
        case .propertyError(let property):
            return "送信失敗: プロパティエラー - \(property)"
        case .apiError(let message, let code):
            if let code = code {
                return "送信失敗 [\(code)]: \(message)"
            }
            return "送信失敗: \(message)"
        case .networkError(let error):
            return "送信失敗: ネットワークエラー - \(error.localizedDescription)"
        }
    }
}

/// データベースプロパティ情報
struct DatabaseProperties {
    let titlePropertyName: String
    let multiSelectPropertyName: String?  // タグ用（存在しない場合はnil）
}

/// Notion APIサービス
final class NotionService: @unchecked Sendable {
    // MARK: - Singleton
    static let shared = NotionService()
    
    private let baseURL = "https://api.notion.com/v1"
    private let notionVersion = "2022-06-28"
    
    // キャッシュ: データベースのプロパティ情報
    private var databasePropertiesCache: [String: DatabaseProperties] = [:]
    private let cacheLock = NSLock()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// メモをNotionデータベースに追加
    func addMemo(_ memo: Memo) async throws {
        // 設定を取得
        let apiKey = await MainActor.run { AppSettings.shared.notionAPIKey }
        let databaseId = await MainActor.run { AppSettings.shared.notionDatabaseId }
        let isConfigured = await MainActor.run { AppSettings.shared.isNotionConfigured }
        
        guard isConfigured else {
            throw NotionError.notConfigured
        }
        
        print("[NotionService] 送信開始: databaseId=\(databaseId.prefix(8))...")
        
        // データベースプロパティを取得（毎回最新を取得）
        let dbProperties = try await fetchDatabaseProperties(databaseId: databaseId, apiKey: apiKey, forceRefresh: true)
        
        print("[NotionService] タイトルプロパティ名: \(dbProperties.titlePropertyName)")
        print("[NotionService] タグプロパティ名: \(dbProperties.multiSelectPropertyName ?? "なし")")
        
        let url = URL(string: "\(baseURL)/pages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = createPageBody(memo: memo, databaseId: databaseId, dbProperties: dbProperties)
        
        // デバッグ: リクエストボディを出力
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[NotionService] リクエストボディ:\n\(jsonString)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NotionError.invalidResponse
            }
            
            print("[NotionService] レスポンスステータス: \(httpResponse.statusCode)")
            
            // エラーレスポンスの詳細解析
            if httpResponse.statusCode != 200 {
                // レスポンスボディを出力
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[NotionService] エラーレスポンス:\n\(responseString)")
                }
                
                // キャッシュをクリア
                clearCacheForDatabase(databaseId)
                throw parseNotionError(data: data, statusCode: httpResponse.statusCode)
            }
            
            print("[NotionService] 送信成功!")
            
        } catch let error as NotionError {
            throw error
        } catch {
            throw NotionError.networkError(error)
        }
    }
    
    /// データベース接続テスト
    func testConnection() async throws -> Bool {
        let apiKey = await MainActor.run { AppSettings.shared.notionAPIKey }
        let databaseId = await MainActor.run { AppSettings.shared.notionDatabaseId }
        let isConfigured = await MainActor.run { AppSettings.shared.isNotionConfigured }
        
        guard isConfigured else {
            throw NotionError.notConfigured
        }
        
        // キャッシュをクリアして最新を取得
        clearCacheForDatabase(databaseId)
        let props = try await fetchDatabaseProperties(databaseId: databaseId, apiKey: apiKey, forceRefresh: true)
        
        print("[NotionService] 接続テスト成功: タイトル=\(props.titlePropertyName)")
        
        return true
    }
    
    /// キャッシュをクリア
    func clearCache() {
        cacheLock.lock()
        databasePropertiesCache.removeAll()
        cacheLock.unlock()
    }
    
    private func clearCacheForDatabase(_ databaseId: String) {
        cacheLock.lock()
        databasePropertiesCache.removeValue(forKey: databaseId)
        cacheLock.unlock()
    }
    
    // MARK: - Private Methods
    
    /// データベースからプロパティ情報を取得
    private func fetchDatabaseProperties(databaseId: String, apiKey: String, forceRefresh: Bool = false) async throws -> DatabaseProperties {
        // キャッシュをチェック（強制リフレッシュでなければ）
        if !forceRefresh {
            cacheLock.lock()
            let cached = databasePropertiesCache[databaseId]
            cacheLock.unlock()
            
            if let cached = cached {
                return cached
            }
        }
        
        print("[NotionService] データベース情報を取得中...")
        
        // データベース情報を取得
        let url = URL(string: "\(baseURL)/databases/\(databaseId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotionError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("[NotionService] データベース取得エラー:\n\(responseString)")
            }
            throw parseNotionError(data: data, statusCode: httpResponse.statusCode)
        }
        
        // レスポンスを解析
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any] else {
            throw NotionError.invalidResponse
        }
        
        print("[NotionService] データベースのプロパティ一覧:")
        
        var titlePropertyName: String?
        var multiSelectPropertyName: String?
        
        // プロパティを解析
        for (propertyName, propertyValue) in properties {
            guard let propertyDict = propertyValue as? [String: Any],
                  let type = propertyDict["type"] as? String else {
                continue
            }
            
            print("  - \(propertyName): \(type)")
            
            switch type {
            case "title":
                titlePropertyName = propertyName
                print("    → タイトルプロパティとして使用")
            case "multi_select":
                if multiSelectPropertyName == nil {
                    multiSelectPropertyName = propertyName
                    print("    → タグプロパティとして使用")
                }
            default:
                break
            }
        }
        
        guard let title = titlePropertyName else {
            print("[NotionService] エラー: タイトルプロパティが見つかりません")
            throw NotionError.noTitleProperty
        }
        
        let dbProperties = DatabaseProperties(
            titlePropertyName: title,
            multiSelectPropertyName: multiSelectPropertyName
        )
        
        // キャッシュに保存
        cacheLock.lock()
        databasePropertiesCache[databaseId] = dbProperties
        cacheLock.unlock()
        
        return dbProperties
    }
    
    /// ページ作成用のリクエストボディを生成
    private func createPageBody(memo: Memo, databaseId: String, dbProperties: DatabaseProperties) -> [String: Any] {
        // タイトルテキスト（最初の100文字）
        let titleText = String(memo.content.prefix(100))
        
        // プロパティ: 動的に取得したタイトルプロパティ名を使用
        var properties: [String: Any] = [
            dbProperties.titlePropertyName: [
                "title": [
                    [
                        "type": "text",
                        "text": [
                            "content": titleText
                        ]
                    ]
                ]
            ]
        ]
        
        // タグを追加（採用済みのみ、かつmulti_selectプロパティが存在する場合のみ）
        let adoptedTags = memo.tags.filter { $0.state == .adopted }
        if !adoptedTags.isEmpty, let multiSelectName = dbProperties.multiSelectPropertyName {
            properties[multiSelectName] = [
                "multi_select": adoptedTags.map { ["name": $0.name] }
            ]
        }
        
        // ページ本文（全文）
        var children: [[String: Any]] = []
        
        // メモ内容を段落ブロックとして追加
        // 長いテキストは2000文字ごとに分割（Notion APIの制限）
        let chunks = splitText(memo.content, maxLength: 2000)
        for chunk in chunks {
            children.append([
                "object": "block",
                "type": "paragraph",
                "paragraph": [
                    "rich_text": [
                        [
                            "type": "text",
                            "text": [
                                "content": chunk
                            ]
                        ]
                    ]
                ]
            ])
        }
        
        return [
            "parent": [
                "database_id": databaseId
            ],
            "properties": properties,
            "children": children
        ]
    }
    
    /// テキストを指定文字数で分割
    private func splitText(_ text: String, maxLength: Int) -> [String] {
        guard text.count > maxLength else {
            return [text]
        }
        
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let endIndex = text.index(startIndex, offsetBy: maxLength, limitedBy: text.endIndex) ?? text.endIndex
            chunks.append(String(text[startIndex..<endIndex]))
            startIndex = endIndex
        }
        
        return chunks
    }
    
    /// Notion APIエラーレスポンスを解析
    private func parseNotionError(data: Data, statusCode: Int) -> NotionError {
        // JSONレスポンスを解析
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .apiError("ステータスコード: \(statusCode)", code: nil)
        }
        
        let message = json["message"] as? String ?? "不明なエラー"
        let code = json["code"] as? String
        
        print("[NotionService] APIエラー: code=\(code ?? "nil"), message=\(message)")
        
        // ステータスコードとエラーコードに基づいて適切なエラーを返す
        switch statusCode {
        case 400:
            // バリデーションエラー
            if message.lowercased().contains("property") {
                return .propertyError(message)
            }
            if message.lowercased().contains("database_id") {
                return .invalidDatabaseId
            }
            return .apiError(message, code: code)
            
        case 401:
            return .unauthorized
            
        case 403:
            return .unauthorized
            
        case 404:
            if code == "object_not_found" {
                return .databaseNotFound
            }
            return .apiError(message, code: code)
            
        default:
            return .apiError(message, code: code)
        }
    }
}

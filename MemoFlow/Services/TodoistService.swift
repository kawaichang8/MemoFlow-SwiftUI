//
//  TodoistService.swift
//  MemoFlow
//
//  Todoist API連携サービス
//

import Foundation

/// Todoist APIエラー
enum TodoistError: LocalizedError {
    case notConfigured
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Todoist APIが設定されていません"
        case .invalidResponse:
            return "無効なレスポンス"
        case .apiError(let message):
            return "Todoist API エラー: \(message)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}

/// Todoist APIサービス
actor TodoistService {
    // MARK: - Singleton
    static let shared = TodoistService()
    
    private let baseURL = "https://api.todoist.com/rest/v2"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// メモをTodoistタスクとして追加
    func addMemo(_ memo: Memo) async throws {
        let settings = AppSettings.shared
        
        guard settings.isTodoistConfigured else {
            throw TodoistError.notConfigured
        }
        
        let url = URL(string: "\(baseURL)/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.todoistAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "content": memo.content
        ]
        
        // プロジェクトIDが設定されていれば追加
        if !settings.todoistProjectId.isEmpty {
            body["project_id"] = settings.todoistProjectId
        }
        
        // タグをラベルとして追加（採用済みのみ）
        let adoptedTags = memo.tags.filter { $0.state == .adopted }
        if !adoptedTags.isEmpty {
            body["labels"] = adoptedTags.map { $0.name }
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TodoistError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["error"] as? String {
                    throw TodoistError.apiError(message)
                }
                throw TodoistError.apiError("Status code: \(httpResponse.statusCode)")
            }
        } catch let error as TodoistError {
            throw error
        } catch {
            throw TodoistError.networkError(error)
        }
    }
    
    /// 接続テスト
    func testConnection() async throws -> Bool {
        let settings = AppSettings.shared
        
        guard settings.isTodoistConfigured else {
            throw TodoistError.notConfigured
        }
        
        let url = URL(string: "\(baseURL)/projects")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(settings.todoistAPIKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TodoistError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    /// プロジェクト一覧を取得
    func fetchProjects() async throws -> [[String: Any]] {
        let settings = AppSettings.shared
        
        guard settings.isTodoistConfigured else {
            throw TodoistError.notConfigured
        }
        
        let url = URL(string: "\(baseURL)/projects")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(settings.todoistAPIKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TodoistError.invalidResponse
        }
        
        guard let projects = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw TodoistError.invalidResponse
        }
        
        return projects
    }
}


//
//  ReflectService.swift
//  MemoFlow
//
//  Reflect API連携サービス
//  https://reflect.app/
//

import Foundation

/// Reflect APIエラー
enum ReflectError: LocalizedError {
    case notConfigured
    case invalidGraphId
    case unauthorized
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Reflectが設定されていません。設定画面でAPIキーとGraph IDを入力してください。"
        case .invalidGraphId:
            return "Graph IDが無効です。"
        case .unauthorized:
            return "Reflect APIキーが無効です。"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "Reflectからの応答が無効です。"
        case .apiError(let message):
            return "Reflect APIエラー: \(message)"
        }
    }
}

/// Reflect API連携サービス
final class ReflectService {
    // MARK: - Singleton
    static let shared = ReflectService()
    
    // MARK: - Properties
    private let baseURL = "https://reflect.app/api"
    
    private var settings: AppSettings {
        AppSettings.shared
    }
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Public Methods
    
    /// メモをReflectに追加（Daily Noteに追記）
    func addMemo(_ memo: Memo) async throws {
        guard settings.isReflectConfigured else {
            throw ReflectError.notConfigured
        }
        
        let apiKey = settings.reflectAPIKey
        let graphId = settings.reflectGraphId
        
        guard !graphId.isEmpty else {
            throw ReflectError.invalidGraphId
        }
        
        // メモ内容を構築
        var content = memo.content
        
        // タグを追加
        if !memo.tags.isEmpty {
            let tagString = memo.tags.map { "#\($0.name)" }.joined(separator: " ")
            content += "\n\n\(tagString)"
        }
        
        // タイムスタンプを追加
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: Date())
        content = "[\(timeString)] \(content)"
        
        // API リクエスト作成
        let url = URL(string: "\(baseURL)/graphs/\(graphId)/daily-notes")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // リクエストボディ
        let body: [String: Any] = [
            "text": content,
            "transform_type": "list-append"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReflectError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                print("✅ [Reflect] メモ追加成功")
                return
                
            case 401:
                throw ReflectError.unauthorized
                
            case 404:
                throw ReflectError.invalidGraphId
                
            default:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    throw ReflectError.apiError(message)
                }
                throw ReflectError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as ReflectError {
            throw error
        } catch {
            throw ReflectError.networkError(error)
        }
    }
    
    /// 接続テスト
    func testConnection() async throws -> Bool {
        guard settings.isReflectConfigured else {
            throw ReflectError.notConfigured
        }
        
        let apiKey = settings.reflectAPIKey
        let graphId = settings.reflectGraphId
        
        guard !graphId.isEmpty else {
            throw ReflectError.invalidGraphId
        }
        
        // Graph情報を取得してテスト
        let url = URL(string: "\(baseURL)/graphs/\(graphId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReflectError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                print("✅ [Reflect] 接続テスト成功")
                return true
                
            case 401:
                throw ReflectError.unauthorized
                
            case 404:
                throw ReflectError.invalidGraphId
                
            default:
                throw ReflectError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as ReflectError {
            throw error
        } catch {
            throw ReflectError.networkError(error)
        }
    }
}


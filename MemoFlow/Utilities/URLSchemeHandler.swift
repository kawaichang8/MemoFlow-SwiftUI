//
//  URLSchemeHandler.swift
//  MemoFlow
//
//  URLスキームとShare Extensionからのデータ処理
//

import Foundation
import SwiftUI

/// URLスキームハンドラー
@Observable
@MainActor
final class URLSchemeHandler {
    // MARK: - Singleton
    static let shared = URLSchemeHandler()
    
    // MARK: - Properties
    var pendingText: String?
    var pendingDestination: Destination?
    
    private init() {}
    
    // MARK: - URL Handling
    
    /// URLスキームを処理
    /// memoflow://capture?text=xxx&destination=notion_inbox
    func handle(_ url: URL) {
        guard url.scheme == "memoflow" else { return }
        
        switch url.host {
        case "capture":
            handleCaptureURL(url)
        default:
            break
        }
    }
    
    private func handleCaptureURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        
        // テキストパラメータ
        if let textParam = components.queryItems?.first(where: { $0.name == "text" })?.value {
            pendingText = textParam.removingPercentEncoding
        }
        
        // 送信先パラメータ
        if let destParam = components.queryItems?.first(where: { $0.name == "destination" })?.value,
           let destination = Destination(rawValue: destParam) {
            pendingDestination = destination
        }
    }
    
    // MARK: - Shared Content
    
    /// Share Extensionからの共有コンテンツをチェック
    func checkSharedContent() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.memoflow.shared") else { return }
        
        if let sharedContent = userDefaults.string(forKey: "sharedContent"),
           let sharedDate = userDefaults.object(forKey: "sharedContentDate") as? Date {
            // 5分以内の共有コンテンツのみ処理
            if Date().timeIntervalSince(sharedDate) < 300 {
                pendingText = sharedContent
                
                // 処理後にクリア
                userDefaults.removeObject(forKey: "sharedContent")
                userDefaults.removeObject(forKey: "sharedContentDate")
            }
        }
    }
    
    /// 保留中のコンテンツをクリア
    func clearPending() {
        pendingText = nil
        pendingDestination = nil
    }
}

// MARK: - App Delegate Adapter
/// SceneDelegateでURLを処理するためのアダプター
struct URLSchemeHandlerModifier: ViewModifier {
    let handler = URLSchemeHandler.shared
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handler.handle(url)
            }
            .onAppear {
                handler.checkSharedContent()
            }
    }
}

extension View {
    func handleURLScheme() -> some View {
        modifier(URLSchemeHandlerModifier())
    }
}


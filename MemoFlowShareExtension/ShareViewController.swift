//
//  ShareViewController.swift
//  MemoFlowShareExtension
//
//  Share Sheet から MemoFlow にコンテンツを送信
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    override func isContentValid() -> Bool {
        // コンテンツが有効かチェック
        return true
    }
    
    override func didSelectPost() {
        // 共有されたコンテンツを取得
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }
        
        Task {
            var sharedContent = contentText ?? ""
            
            for attachment in attachments {
                // テキストの処理
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                        if !sharedContent.isEmpty {
                            sharedContent += "\n"
                        }
                        sharedContent += text
                    }
                }
                
                // URLの処理
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                        if !sharedContent.isEmpty {
                            sharedContent += "\n"
                        }
                        sharedContent += url.absoluteString
                    }
                }
            }
            
            // App Groupsを使用してメインアプリとデータ共有
            if let userDefaults = UserDefaults(suiteName: "group.com.memoflow.shared") {
                userDefaults.set(sharedContent, forKey: "sharedContent")
                userDefaults.set(Date(), forKey: "sharedContentDate")
            }
            
            // メインアプリを開く
            await openMainApp(with: sharedContent)
            
            completeRequest()
        }
    }
    
    override func configurationItems() -> [Any]! {
        // 設定項目（送信先選択など）
        let destinationItem = SLComposeSheetConfigurationItem()
        destinationItem?.title = "送信先"
        destinationItem?.value = "Notion Inbox"
        destinationItem?.tapHandler = {
            // 送信先選択画面を表示（将来実装）
        }
        
        return [destinationItem].compactMap { $0 }
    }
    
    private func openMainApp(with content: String) async {
        // URLスキームでメインアプリを開く
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "memoflow://capture?text=\(encodedContent)") {
            await MainActor.run {
                // Share Extensionからは直接アプリを開けないので、
                // App Groupsでデータを共有し、次回アプリ起動時に処理
            }
        }
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}


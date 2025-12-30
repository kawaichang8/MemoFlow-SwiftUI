//
//  EmailService.swift
//  MemoFlow
//
//  Email to Self サービス
//  MessageUI/URLスキームを使用したメール送信
//

import Foundation
import UIKit
import MessageUI

/// Emailエラー
enum EmailError: LocalizedError {
    case notConfigured
    case invalidEmailAddress
    case mailNotAvailable
    case sendFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "メールアドレスが設定されていません。設定画面でメールアドレスを入力してください。"
        case .invalidEmailAddress:
            return "無効なメールアドレスです。"
        case .mailNotAvailable:
            return "このデバイスでメール送信ができません。"
        case .sendFailed:
            return "メール送信に失敗しました。"
        case .cancelled:
            return "メール送信がキャンセルされました。"
        }
    }
}

/// Email送信サービス
@MainActor
final class EmailService: NSObject {
    // MARK: - Singleton
    static let shared = EmailService()
    
    // MARK: - Properties
    private var settings: AppSettings {
        AppSettings.shared
    }
    
    private var continuation: CheckedContinuation<Void, Error>?
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// メモをメールで送信
    func addMemo(_ memo: Memo) async throws {
        guard settings.isEmailConfigured else {
            throw EmailError.notConfigured
        }
        
        let emailAddress = settings.emailToSelfAddress
        
        guard isValidEmail(emailAddress) else {
            throw EmailError.invalidEmailAddress
        }
        
        // メール本文を構築
        var body = memo.content
        
        // タグを追加
        if !memo.tags.isEmpty {
            let tagString = memo.tags.map { "#\($0.name)" }.joined(separator: " ")
            body += "\n\n---\n\(tagString)"
        }
        
        // 送信元情報
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let timeString = formatter.string(from: Date())
        body += "\n\nSent from MemoFlow at \(timeString)"
        
        // 件名を生成（最初の30文字）
        let subject = generateSubject(from: memo.content)
        
        // URLスキームでメール送信（バックグラウンド送信不可の場合）
        // MessageUI を使ったインライン送信を試みる
        if MFMailComposeViewController.canSendMail() {
            try await sendWithMailCompose(to: emailAddress, subject: subject, body: body)
        } else {
            // URLスキームにフォールバック
            try await sendWithURLScheme(to: emailAddress, subject: subject, body: body)
        }
    }
    
    /// メールが送信可能か確認
    func canSendEmail() -> Bool {
        return MFMailComposeViewController.canSendMail() || UIApplication.shared.canOpenURL(URL(string: "mailto:")!)
    }
    
    // MARK: - Private Methods
    
    private func generateSubject(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        
        if firstLine.count <= 50 {
            return "[MemoFlow] \(firstLine)"
        }
        return "[MemoFlow] \(String(firstLine.prefix(50)))..."
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    /// MessageUIを使用した送信
    private func sendWithMailCompose(to email: String, subject: String, body: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setToRecipients([email])
            mailVC.setSubject(subject)
            mailVC.setMessageBody(body, isHTML: false)
            
            // トップのViewControllerを取得して表示
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                topVC.present(mailVC, animated: true)
            } else {
                continuation.resume(throwing: EmailError.mailNotAvailable)
                self.continuation = nil
            }
        }
    }
    
    /// URLスキームを使用した送信
    private func sendWithURLScheme(to email: String, subject: String, body: String) async throws {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        
        guard let url = components.url else {
            throw EmailError.invalidEmailAddress
        }
        
        if await UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            print("✅ [Email] メールアプリを開きました")
        } else {
            throw EmailError.mailNotAvailable
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension EmailService: MFMailComposeViewControllerDelegate {
    nonisolated func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            
            switch result {
            case .cancelled:
                continuation?.resume(throwing: EmailError.cancelled)
            case .saved:
                // 下書き保存も成功扱い
                print("✅ [Email] 下書き保存")
                continuation?.resume()
            case .sent:
                print("✅ [Email] メール送信成功")
                continuation?.resume()
            case .failed:
                continuation?.resume(throwing: error ?? EmailError.sendFailed)
            @unknown default:
                continuation?.resume(throwing: EmailError.sendFailed)
            }
            
            continuation = nil
        }
    }
}


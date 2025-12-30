//
//  HapticManager.swift
//  MemoFlow
//
//  ハプティックフィードバック管理
//

import UIKit

/// ハプティックフィードバック管理
final class HapticManager {
    // MARK: - Singleton
    static let shared = HapticManager()
    
    private let settings = AppSettings.shared
    
    // ジェネレーター
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // ジェネレーターを準備
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Public Methods
    
    /// 軽いタップ（タグ選択など）
    func lightTap() {
        guard settings.hapticEnabled else { return }
        lightGenerator.impactOccurred()
    }
    
    /// 中程度のタップ（ボタンタップなど）
    func mediumTap() {
        guard settings.hapticEnabled else { return }
        mediumGenerator.impactOccurred()
    }
    
    /// 重いタップ（送信完了など）
    func heavyTap() {
        guard settings.hapticEnabled else { return }
        heavyGenerator.impactOccurred()
    }
    
    /// 選択フィードバック（ピッカー変更など）
    func selection() {
        guard settings.hapticEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// 成功通知
    func success() {
        guard settings.hapticEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// 警告通知
    func warning() {
        guard settings.hapticEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// エラー通知
    func error() {
        guard settings.hapticEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// ジェネレーターを準備（パフォーマンス最適化）
    func prepare() {
        guard settings.hapticEnabled else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
}


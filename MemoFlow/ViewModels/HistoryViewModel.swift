//
//  HistoryViewModel.swift
//  MemoFlow
//
//  履歴画面のViewModel
//

import Foundation
import SwiftUI

/// 履歴ViewModel
@Observable
@MainActor
final class HistoryViewModel {
    // MARK: - Properties
    
    /// 履歴アイテム一覧
    var historyItems: [MemoHistoryItem] = []
    
    /// 選択中のアイテム（詳細表示用）
    var selectedItem: MemoHistoryItem?
    
    /// 再編集モード
    var isEditMode: Bool = false
    
    /// 再編集用テキスト
    var editingContent: String = ""
    
    /// ローディング状態
    var isLoading: Bool = false
    
    /// 削除確認アラート
    var showDeleteConfirmation: Bool = false
    var itemToDelete: MemoHistoryItem?
    
    /// 全削除確認アラート
    var showClearAllConfirmation: Bool = false
    
    /// 再送信状態
    var isSending: Bool = false
    var sendResult: SendResult?
    
    /// 履歴件数
    var historyCount: Int {
        historyItems.count
    }
    
    /// 履歴が空か
    var isEmpty: Bool {
        historyItems.isEmpty
    }
    
    // MARK: - Services
    private let historyService = HistoryService.shared
    private let haptic = HapticManager.shared
    
    // MARK: - Init
    init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// 履歴を読み込み
    func loadHistory() {
        isLoading = true
        historyItems = historyService.fetchHistory(limit: 20)
        isLoading = false
    }
    
    /// 履歴を更新
    func refreshHistory() {
        loadHistory()
    }
    
    /// アイテムを選択（詳細表示）
    func selectItem(_ item: MemoHistoryItem) {
        selectedItem = item
        editingContent = item.content
        isEditMode = false
        haptic.lightTap()
    }
    
    /// 詳細表示を閉じる
    func closeDetail() {
        selectedItem = nil
        isEditMode = false
        editingContent = ""
    }
    
    /// 編集モードに切り替え
    func startEditing() {
        guard let item = selectedItem else { return }
        editingContent = item.content
        isEditMode = true
        haptic.lightTap()
    }
    
    /// 編集をキャンセル
    func cancelEditing() {
        guard let item = selectedItem else { return }
        editingContent = item.content
        isEditMode = false
    }
    
    /// 再送信
    func resend() async {
        guard let item = selectedItem else { return }
        
        isSending = true
        haptic.mediumTap()
        
        // 編集内容を反映したメモを作成
        var memo = item.toMemo()
        memo.content = editingContent
        
        // 送信
        sendResult = await MemoSendService.shared.send(memo)
        
        switch sendResult {
        case .success:
            haptic.success()
            
            // 履歴を更新（新しい送信として保存）
            historyService.saveToHistory(memo)
            loadHistory()
            
            // 詳細を閉じる
            closeDetail()
            
        case .failure:
            haptic.error()
            
        case nil:
            break
        }
        
        isSending = false
    }
    
    /// 削除確認を表示
    func confirmDelete(_ item: MemoHistoryItem) {
        itemToDelete = item
        showDeleteConfirmation = true
    }
    
    /// アイテムを削除
    func deleteItem() {
        guard let item = itemToDelete else { return }
        
        historyService.deleteItem(item)
        
        // リストから削除
        historyItems.removeAll { $0.id == item.id }
        
        // 詳細表示中なら閉じる
        if selectedItem?.id == item.id {
            closeDetail()
        }
        
        itemToDelete = nil
        haptic.lightTap()
    }
    
    /// 全履歴削除確認
    func confirmClearAll() {
        showClearAllConfirmation = true
    }
    
    /// 全履歴を削除
    func clearAllHistory() {
        historyService.clearAllHistory()
        historyItems = []
        closeDetail()
        haptic.mediumTap()
    }
    
    /// メモを新規キャプチャ画面にコピー
    func copyToCapture() -> Memo? {
        guard let item = selectedItem else { return nil }
        
        var memo = item.toMemo()
        memo.content = editingContent
        
        haptic.lightTap()
        closeDetail()
        
        return memo
    }
}


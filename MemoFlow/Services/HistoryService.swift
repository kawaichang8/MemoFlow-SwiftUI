//
//  HistoryService.swift
//  MemoFlow
//
//  履歴管理サービス（SwiftData）
//

import Foundation
import SwiftData

/// 履歴管理サービス
@MainActor
final class HistoryService {
    // MARK: - Singleton
    static let shared = HistoryService()
    
    // MARK: - Properties
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    /// 最大保持件数
    private let maxHistoryCount = 100
    
    // MARK: - Init
    private init() {
        setupContainer()
    }
    
    private func setupContainer() {
        do {
            let schema = Schema([MemoHistoryItem.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            modelContext = modelContainer?.mainContext
            
            print("📦 [History] SwiftData初期化完了")
        } catch {
            print("❌ [History] SwiftData初期化エラー: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// ModelContainerを取得（Appで使用）
    func getModelContainer() -> ModelContainer? {
        return modelContainer
    }
    
    /// メモを履歴に保存
    func saveToHistory(_ memo: Memo) {
        guard let context = modelContext else {
            print("❌ [History] ModelContextが未設定")
            return
        }
        
        // 既存のアイテムがあれば削除（同一ID）
        let existingId = memo.id
        let descriptor = FetchDescriptor<MemoHistoryItem>(
            predicate: #Predicate { $0.id == existingId }
        )
        
        if let existingItems = try? context.fetch(descriptor) {
            for item in existingItems {
                context.delete(item)
            }
        }
        
        // 新規アイテム追加
        let historyItem = MemoHistoryItem(from: memo)
        context.insert(historyItem)
        
        // 保存
        do {
            try context.save()
            print("✅ [History] 履歴保存成功: \(memo.content.prefix(20))...")
            
            // 古いアイテムを削除
            cleanupOldItems()
        } catch {
            print("❌ [History] 履歴保存エラー: \(error)")
        }
    }
    
    /// 履歴を取得（最新順、最大20件）
    func fetchHistory(limit: Int = 20) -> [MemoHistoryItem] {
        guard let context = modelContext else {
            print("❌ [History] ModelContextが未設定")
            return []
        }
        
        var descriptor = FetchDescriptor<MemoHistoryItem>(
            sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            let items = try context.fetch(descriptor)
            print("📋 [History] 履歴取得: \(items.count)件")
            return items
        } catch {
            print("❌ [History] 履歴取得エラー: \(error)")
            return []
        }
    }
    
    /// 全履歴を取得
    func fetchAllHistory() -> [MemoHistoryItem] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<MemoHistoryItem>(
            sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ [History] 全履歴取得エラー: \(error)")
            return []
        }
    }
    
    /// 履歴アイテムを削除
    func deleteItem(_ item: MemoHistoryItem) {
        guard let context = modelContext else { return }
        
        context.delete(item)
        
        do {
            try context.save()
            print("🗑️ [History] 履歴削除成功")
        } catch {
            print("❌ [History] 履歴削除エラー: \(error)")
        }
    }
    
    /// IDで削除
    func deleteItem(id: UUID) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<MemoHistoryItem>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            if let items = try? context.fetch(descriptor) {
                for item in items {
                    context.delete(item)
                }
                try context.save()
                print("🗑️ [History] 履歴削除成功 (ID: \(id))")
            }
        } catch {
            print("❌ [History] 履歴削除エラー: \(error)")
        }
    }
    
    /// 全履歴を削除
    func clearAllHistory() {
        guard let context = modelContext else { return }
        
        do {
            try context.delete(model: MemoHistoryItem.self)
            try context.save()
            print("🗑️ [History] 全履歴削除成功")
        } catch {
            print("❌ [History] 全履歴削除エラー: \(error)")
        }
    }
    
    /// 履歴件数を取得
    func getHistoryCount() -> Int {
        guard let context = modelContext else { return 0 }
        
        let descriptor = FetchDescriptor<MemoHistoryItem>()
        
        do {
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    // MARK: - Private Methods
    
    /// 古いアイテムを削除（最大件数を超えた場合）
    private func cleanupOldItems() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<MemoHistoryItem>(
            sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
        )
        
        do {
            let allItems = try context.fetch(descriptor)
            
            if allItems.count > maxHistoryCount {
                let itemsToDelete = allItems.suffix(from: maxHistoryCount)
                for item in itemsToDelete {
                    context.delete(item)
                }
                try context.save()
                print("🧹 [History] 古い履歴を削除: \(itemsToDelete.count)件")
            }
        } catch {
            print("❌ [History] クリーンアップエラー: \(error)")
        }
    }
}


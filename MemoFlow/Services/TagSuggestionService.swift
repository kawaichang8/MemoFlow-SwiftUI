//
//  TagSuggestionService.swift
//  MemoFlow
//
//  AI タグ提案サービス（ローカルキーワードベース）
//

import Foundation
import NaturalLanguage

/// タグ提案サービス
@Observable
@MainActor
final class TagSuggestionService {
    // MARK: - Properties
    var suggestedTags: [Tag] = []
    
    private let settings = AppSettings.shared
    private var debounceTask: Task<Void, Never>?
    private var lastProcessedText: String = ""
    
    // MARK: - キーワードマッピング
    private let keywordTagMap: [String: String] = [
        // タスク系
        "やる": "タスク",
        "する": "タスク",
        "完了": "タスク",
        "終わらせる": "タスク",
        "TODO": "タスク",
        "todo": "タスク",
        "タスク": "タスク",
        
        // アイデア系
        "アイデア": "アイデア",
        "思いついた": "アイデア",
        "ひらめいた": "アイデア",
        "案": "アイデア",
        
        // 買い物系
        "買う": "買い物",
        "購入": "買い物",
        "注文": "買い物",
        "Amazon": "買い物",
        "買い物": "買い物",
        
        // 調査系
        "調べる": "調査",
        "検索": "調査",
        "調査": "調査",
        "リサーチ": "調査",
        
        // ミーティング系
        "会議": "ミーティング",
        "ミーティング": "ミーティング",
        "MTG": "ミーティング",
        "打ち合わせ": "ミーティング",
        
        // 優先度系
        "重要": "重要",
        "緊急": "重要",
        "大事": "重要",
        "ASAP": "重要",
        
        // 後回し系
        "あとで": "あとで",
        "後で": "あとで",
        "いつか": "あとで",
        "そのうち": "あとで",
        
        // プロジェクト系
        "プロジェクト": "プロジェクト",
        "PJ": "プロジェクト",
        
        // 読書系
        "読む": "読書",
        "本": "読書",
        "読書": "読書",
        "記事": "読書",
        
        // 学習系
        "学ぶ": "学習",
        "勉強": "学習",
        "学習": "学習",
        "習得": "学習",
    ]
    
    // MARK: - Public Methods
    
    /// テキストからタグを提案
    func suggestTags(for text: String) {
        // 空のテキストは即座にクリア
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestedTags = []
            lastProcessedText = ""
            return
        }
        
        // デバウンス処理
        debounceTask?.cancel()
        debounceTask = Task {
            // 短いデバウンス（200ms）
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            guard !Task.isCancelled else { return }
            
            await performSuggestion(for: text)
            lastProcessedText = text
        }
    }
    
    /// 現在のテキストで再提案（強制）
    func refreshSuggestions() {
        if !lastProcessedText.isEmpty {
            Task {
                await performSuggestion(for: lastProcessedText)
            }
        }
    }
    
    /// 提案をクリア
    func clearSuggestions() {
        suggestedTags = []
        lastProcessedText = ""
        debounceTask?.cancel()
    }
    
    // MARK: - Private Methods
    
    private func performSuggestion(for text: String) async {
        guard settings.tagAutoMode != .off else {
            suggestedTags = []
            return
        }
        
        var foundTags: Set<String> = []
        
        // キーワードマッチング
        for (keyword, tagName) in keywordTagMap {
            if text.localizedCaseInsensitiveContains(keyword) {
                foundTags.insert(tagName)
            }
        }
        
        // NaturalLanguageでエンティティ抽出
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if let tag = tag {
                let word = String(text[range])
                
                // 名詞で長い単語はタグ候補
                if tag == .noun && word.count >= 2 {
                    // 既存のプリセットタグとマッチするか確認
                    for presetTag in Tag.presets {
                        if word.localizedCaseInsensitiveContains(presetTag.name) ||
                           presetTag.name.localizedCaseInsensitiveContains(word) {
                            foundTags.insert(presetTag.name)
                        }
                    }
                }
            }
            return true
        }
        
        // 保存済みタグとマッチング（採用率でソート）
        let savedTags = settings.savedTags.sorted { $0.priorityScore > $1.priorityScore }
        
        var resultTags: [Tag] = []
        
        for tagName in foundTags {
            if let existingTag = savedTags.first(where: { $0.name == tagName }) {
                var tag = existingTag
                tag.state = settings.tagAutoMode == .autoAdopt ? .adopted : .suggested
                resultTags.append(tag)
            } else {
                resultTags.append(Tag(
                    name: tagName,
                    state: settings.tagAutoMode == .autoAdopt ? .adopted : .suggested
                ))
            }
        }
        
        // 優先度でソート（最大5つ）
        suggestedTags = Array(resultTags.sorted { $0.priorityScore > $1.priorityScore }.prefix(5))
    }
    
    /// タグを採用してスコアを更新
    func adoptTag(_ tag: Tag) {
        var savedTags = settings.savedTags
        
        if let index = savedTags.firstIndex(where: { $0.name == tag.name }) {
            savedTags[index].usageCount += 1
            savedTags[index].lastUsedAt = Date()
        } else {
            var newTag = tag
            newTag.usageCount = 1
            newTag.lastUsedAt = Date()
            savedTags.append(newTag)
        }
        
        settings.savedTags = savedTags
    }
}

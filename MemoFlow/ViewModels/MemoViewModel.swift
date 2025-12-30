//
//  MemoViewModel.swift
//  MemoFlow
//
//  メインキャプチャ画面のViewModel
//

import Foundation
import SwiftUI
import Combine

/// 送信状態
enum SendingState: Equatable {
    case idle
    case sending
    case success
    case failure(Error)
    
    // Errorは Equatable ではないため、手動実装
    static func == (lhs: SendingState, rhs: SendingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.sending, .sending):
            return true
        case (.success, .success):
            return true
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

/// メモViewModel
@Observable
@MainActor
final class MemoViewModel {
    // MARK: - Properties
    
    /// 現在のメモ
    var memo: Memo = Memo()
    
    /// 送信状態
    var sendingState: SendingState = .idle
    
    /// 提案中のタグ（直接管理）
    var suggestedTags: [Tag] = []
    
    /// 削除されたタグ（一時的に提案から除外）
    private var dismissedTagNames: Set<String> = []
    
    /// 選択中の送信先
    var selectedDestination: Destination {
        get { memo.destination }
        set { memo.destination = newValue }
    }
    
    /// 採用済みタグ
    var adoptedTags: [Tag] {
        memo.tags.filter { $0.state == .adopted }
    }
    
    /// テキストが空か
    var isEmpty: Bool {
        memo.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 送信可能か
    var canSend: Bool {
        !isEmpty && sendingState != .sending
    }
    
    // MARK: - Services
    private let speechService = SpeechService()
    private let haptic = HapticManager.shared
    private let settings = AppSettings.shared
    
    // タグ提案用
    private var debounceTask: Task<Void, Never>?
    
    // MARK: - キーワードマッピング（より広範囲）
    private let keywordTagMap: [String: String] = [
        // タスク系
        "やる": "タスク",
        "する": "タスク",
        "完了": "タスク",
        "終わらせる": "タスク",
        "TODO": "タスク",
        "todo": "タスク",
        "タスク": "タスク",
        "締切": "タスク",
        "期限": "タスク",
        "提出": "タスク",
        "作成": "タスク",
        "準備": "タスク",
        "対応": "タスク",
        "確認": "タスク",
        "連絡": "タスク",
        "返信": "タスク",
        "送る": "タスク",
        "作る": "タスク",
        
        // アイデア系
        "アイデア": "アイデア",
        "思いついた": "アイデア",
        "ひらめいた": "アイデア",
        "案": "アイデア",
        "企画": "アイデア",
        "提案": "アイデア",
        "考え": "アイデア",
        "発想": "アイデア",
        "インスピレーション": "アイデア",
        "思いつき": "アイデア",
        
        // 買い物系
        "買う": "買い物",
        "購入": "買い物",
        "注文": "買い物",
        "Amazon": "買い物",
        "買い物": "買い物",
        "ショッピング": "買い物",
        "欲しい": "買い物",
        "必要": "買い物",
        "補充": "買い物",
        "在庫": "買い物",
        "切れ": "買い物",
        "買い足": "買い物",
        
        // 食べ物・料理系 → 買い物 or レシピ
        "料理": "レシピ",
        "レシピ": "レシピ",
        "作り方": "レシピ",
        "食べ": "グルメ",
        "ランチ": "グルメ",
        "ディナー": "グルメ",
        "レストラン": "グルメ",
        "お店": "グルメ",
        "店": "グルメ",
        "予約": "グルメ",
        
        // 調査系
        "調べる": "調査",
        "検索": "調査",
        "調査": "調査",
        "リサーチ": "調査",
        "探す": "調査",
        "検討": "調査",
        "比較": "調査",
        "確かめ": "調査",
        "チェック": "調査",
        "ググ": "調査",
        "見つけ": "調査",
        
        // ミーティング系
        "会議": "ミーティング",
        "ミーティング": "ミーティング",
        "MTG": "ミーティング",
        "打ち合わせ": "ミーティング",
        "面談": "ミーティング",
        "商談": "ミーティング",
        "相談": "ミーティング",
        "ミート": "ミーティング",
        "Zoom": "ミーティング",
        "Teams": "ミーティング",
        "資料": "ミーティング",
        
        // 優先度系
        "重要": "重要",
        "緊急": "重要",
        "大事": "重要",
        "ASAP": "重要",
        "急ぎ": "重要",
        "至急": "重要",
        "優先": "重要",
        "必須": "重要",
        "絶対": "重要",
        
        // 後回し系
        "あとで": "あとで",
        "後で": "あとで",
        "いつか": "あとで",
        "そのうち": "あとで",
        "余裕": "あとで",
        "時間ある時": "あとで",
        "暇な時": "あとで",
        
        // プロジェクト系
        "プロジェクト": "プロジェクト",
        "PJ": "プロジェクト",
        "案件": "プロジェクト",
        
        // 読書系
        "読む": "読書",
        "本": "読書",
        "読書": "読書",
        "記事": "読書",
        "ブログ": "読書",
        "ニュース": "読書",
        "論文": "読書",
        
        // 学習系
        "学ぶ": "学習",
        "勉強": "学習",
        "学習": "学習",
        "習得": "学習",
        "練習": "学習",
        "トレーニング": "学習",
        "スキル": "学習",
        "理解": "学習",
        
        // 健康系
        "運動": "健康",
        "ジム": "健康",
        "筋トレ": "健康",
        "ランニング": "健康",
        "散歩": "健康",
        "病院": "健康",
        "薬": "健康",
        "健康": "健康",
        
        // お金系
        "支払": "お金",
        "振込": "お金",
        "入金": "お金",
        "経費": "お金",
        "請求": "お金",
        "精算": "お金",
        "予算": "お金",
        
        // 旅行系
        "旅行": "旅行",
        "出張": "旅行",
        "ホテル": "旅行",
        "飛行機": "旅行",
        "新幹線": "旅行",
        "チケット": "旅行",
    ]
    
    /// 音声認識中か
    var isListening: Bool {
        speechService.isListening
    }
    
    /// 音声レベル
    var audioLevel: Float {
        speechService.audioLevel
    }
    
    // MARK: - Init
    init() {
        memo.destination = settings.defaultDestination
    }
    
    // MARK: - Text Input
    
    /// テキスト変更時に呼び出し
    func onTextChange(_ text: String) {
        memo.content = text
        
        // テキストが変わったら削除タグをクリア
        dismissedTagNames.removeAll()
        
        // タグ提案を更新
        suggestTags(for: text)
    }
    
    // MARK: - Tag Suggestion
    
    private func suggestTags(for text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空のテキストは即座にクリア
        guard !trimmedText.isEmpty else {
            suggestedTags = []
            print("🏷️ [Tag] テキスト空 - タグクリア")
            return
        }
        
        // タグ提案がオフなら何もしない
        guard settings.tagAutoMode != .off else {
            suggestedTags = []
            print("🏷️ [Tag] タグ提案オフ")
            return
        }
        
        print("🏷️ [Tag] 提案開始: \"\(trimmedText)\" (mode: \(settings.tagAutoMode))")
        
        // デバウンスなしで即座に実行
        performSuggestion(for: trimmedText)
    }
    
    private func performSuggestion(for text: String) {
        var foundTags: Set<String> = []
        var matchScores: [String: Int] = [:] // タグごとのマッチスコア
        
        // 1. キーワードマッチング（高スコア）
        for (keyword, tagName) in keywordTagMap {
            if text.localizedCaseInsensitiveContains(keyword) {
                foundTags.insert(tagName)
                matchScores[tagName, default: 0] += 10
            }
        }
        
        // 2. プリセットタグとのマッチング（高スコア）
        for presetTag in Tag.presets {
            if text.localizedCaseInsensitiveContains(presetTag.name) {
                foundTags.insert(presetTag.name)
                matchScores[presetTag.name, default: 0] += 10
            }
        }
        
        // 3. 文脈に応じたデフォルトタグ（長さで判断）
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let textLength = trimmedText.count
        
        // 短すぎるテキストではデフォルトタグを出さない（キーワードマッチのみ）
        // 5文字以上でよく使うタグを1つだけ追加
        if textLength >= 5 && foundTags.isEmpty {
            if let topTag = settings.savedTags
                .sorted(by: { $0.priorityScore > $1.priorityScore })
                .first {
                foundTags.insert(topTag.name)
                matchScores[topTag.name, default: 0] += 2
            }
        }
        
        // 10文字以上で追加のデフォルトタグ
        if textLength >= 10 && foundTags.count < 2 {
            foundTags.insert("メモ")
            matchScores["メモ", default: 0] += 1
        }
        
        // 4. 疑問文・調査パターン
        if trimmedText.contains("?") || trimmedText.contains("？") ||
           trimmedText.hasSuffix("とは") || trimmedText.hasSuffix("って") ||
           trimmedText.contains("調べ") || trimmedText.contains("検索") {
            foundTags.insert("調査")
            matchScores["調査", default: 0] += 8
        }
        
        // 5. 食べ物・グルメパターン
        let foodKeywords = ["食べ", "飲み", "レストラン", "カフェ", "ランチ", "ディナー", 
                          "お店", "店", "チキン", "肉", "魚", "野菜", "料理", "ラーメン",
                          "寿司", "カレー", "パスタ", "ピザ", "焼肉", "居酒屋", "バー",
                          "スイーツ", "ケーキ", "コーヒー", "お茶", "ご飯", "弁当"]
        for keyword in foodKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                foundTags.insert("グルメ")
                matchScores["グルメ", default: 0] += 8
                break
            }
        }
        
        // 6. やることパターン
        let todoKeywords = ["やる", "する", "しなきゃ", "しないと", "忘れず", "覚え",
                          "必要", "用意", "準備", "確認", "連絡", "電話", "メール"]
        for keyword in todoKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                foundTags.insert("タスク")
                matchScores["タスク", default: 0] += 8
                break
            }
        }
        
        // 7. 買い物パターン
        let buyKeywords = ["買", "欲しい", "ほしい", "注文", "購入", "Amazon", "楽天", "通販"]
        for keyword in buyKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                foundTags.insert("買い物")
                matchScores["買い物", default: 0] += 8
                break
            }
        }
        
        // 8. アイデア・思考パターン
        let ideaKeywords = ["思った", "ひらめ", "アイデア", "考え", "かも", "だったら", "もし"]
        for keyword in ideaKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                foundTags.insert("アイデア")
                matchScores["アイデア", default: 0] += 7
                break
            }
        }
        
        // 9. テキストが長め（20文字以上）で他にマッチがなければ「メモ」
        if textLength >= 20 && foundTags.isEmpty {
            foundTags.insert("メモ")
            matchScores["メモ", default: 0] += 3
        }
        
        // 結果を生成
        var resultTags: [Tag] = []
        let savedTags = settings.savedTags.sorted { $0.priorityScore > $1.priorityScore }
        
        for tagName in foundTags {
            // 既に採用済みのタグは除外
            if memo.tags.contains(where: { $0.name == tagName }) {
                continue
            }
            
            // 削除されたタグは除外
            if dismissedTagNames.contains(tagName) {
                continue
            }
            
            if let existingTag = savedTags.first(where: { $0.name == tagName }) {
                var tag = existingTag
                tag.state = settings.tagAutoMode == .autoAdopt ? .adopted : .suggested
                resultTags.append(tag)
            } else if Tag.presets.contains(where: { $0.name == tagName }) {
                // プリセットにあるタグ
                resultTags.append(Tag(
                    name: tagName,
                    state: settings.tagAutoMode == .autoAdopt ? .adopted : .suggested
                ))
            } else {
                // 新規タグ（デフォルトタグも含む）
                resultTags.append(Tag(
                    name: tagName,
                    state: settings.tagAutoMode == .autoAdopt ? .adopted : .suggested
                ))
            }
        }
        
        // マッチスコア + 使用頻度でソート（最大5つ）
        let sortedTags = Array(resultTags.sorted { 
            let score1 = matchScores[$0.name, default: 0] + Int($0.priorityScore)
            let score2 = matchScores[$1.name, default: 0] + Int($1.priorityScore)
            return score1 > score2
        }.prefix(5))
        
        // 自動採用モードの場合、直接memo.tagsに追加
        if settings.tagAutoMode == .autoAdopt {
            for tag in sortedTags {
                // まだ採用されていないタグのみ追加
                if !memo.tags.contains(where: { $0.name == tag.name }) {
                    var adoptedTag = tag
                    adoptedTag.state = .adopted
                    memo.tags.append(adoptedTag)
                    updateTagUsage(adoptedTag)
                }
            }
            suggestedTags = [] // 提案欄は空に
            print("🏷️ [Tag] 自動採用: \(sortedTags.map { $0.name })")
        } else {
            // 提案のみモード
            suggestedTags = sortedTags
            print("🏷️ [Tag] 提案: \(suggestedTags.map { $0.name })")
        }
    }
    
    // MARK: - Tag Management
    
    /// タグを採用
    func adoptTag(_ tag: Tag) {
        var newTag = tag
        newTag.state = .adopted
        
        if !memo.tags.contains(where: { $0.name == tag.name }) {
            memo.tags.append(newTag)
            
            // 使用回数を更新
            updateTagUsage(newTag)
            
            // 削除リストからも除去
            dismissedTagNames.remove(tag.name)
            
            // 提案リストから削除
            suggestedTags.removeAll { $0.name == tag.name }
            
            haptic.lightTap()
        }
    }
    
    private func updateTagUsage(_ tag: Tag) {
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
    
    /// タグを削除
    func removeTag(_ tag: Tag) {
        memo.tags.removeAll { $0.name == tag.name }
        
        // 削除されたタグを一時的に記録
        dismissedTagNames.insert(tag.name)
        
        haptic.lightTap()
    }
    
    /// タグをトグル
    func toggleTag(_ tag: Tag) {
        if memo.tags.contains(where: { $0.name == tag.name }) {
            removeTag(tag)
        } else {
            adoptTag(tag)
        }
    }
    
    // MARK: - Send
    
    /// メモを送信
    func send() async {
        guard canSend else { return }
        
        sendingState = .sending
        haptic.mediumTap()
        
        let result = await MemoSendService.shared.send(memo)
        
        switch result {
        case .success:
            // 履歴に保存
            await MemoSendService.shared.saveToHistory(memo)
            
            sendingState = .success
            haptic.success()
            
            // 少し待ってからリセット
            try? await Task.sleep(nanoseconds: 800_000_000)
            reset()
            
        case .failure(let error):
            sendingState = .failure(error)
            haptic.error()
        }
    }
    
    /// メモをリセット
    func reset() {
        memo = Memo(destination: settings.defaultDestination)
        sendingState = .idle
        dismissedTagNames.removeAll()
        suggestedTags = []
        debounceTask?.cancel()
    }
    
    /// エラーをクリア
    func clearError() {
        if case .failure = sendingState {
            sendingState = .idle
        }
    }
    
    // MARK: - Voice Input
    
    /// 音声認識権限をリクエスト
    func requestSpeechAuthorization() async -> Bool {
        await speechService.requestAuthorization()
    }
    
    /// 音声入力を開始
    func startVoiceInput() async throws {
        haptic.mediumTap()
        speechService.reset()
        try await speechService.startListening()
    }
    
    /// 音声入力を停止
    func stopVoiceInput() {
        speechService.stopListening()
        haptic.lightTap()
        
        // 音声認識結果をテキストに追加
        if !speechService.transcribedText.isEmpty {
            if !memo.content.isEmpty && !memo.content.hasSuffix(" ") && !memo.content.hasSuffix("\n") {
                memo.content += " "
            }
            memo.content += speechService.transcribedText
            onTextChange(memo.content)
        }
    }
    
    /// 音声入力をトグル
    func toggleVoiceInput() async {
        if isListening {
            stopVoiceInput()
        } else {
            do {
                try await startVoiceInput()
            } catch {
                print("Voice input error: \(error)")
            }
        }
    }
}

// MARK: - Preview Helper
extension MemoViewModel {
    static var preview: MemoViewModel {
        let vm = MemoViewModel()
        vm.memo.content = "これはプレビュー用のサンプルメモです"
        vm.memo.tags = [
            Tag(name: "アイデア", state: .adopted),
            Tag(name: "タスク", state: .adopted)
        ]
        vm.suggestedTags = [
            Tag(name: "重要", state: .suggested),
            Tag(name: "あとで", state: .suggested)
        ]
        return vm
    }
}

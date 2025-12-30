//
//  TemplateDetectionService.swift
//  MemoFlow
//
//  AI自動テンプレート判別サービス
//  ローカルNaturalLanguageフレームワーク優先
//

import Foundation
import NaturalLanguage

/// テンプレート判別サービス
@Observable
@MainActor
final class TemplateDetectionService {
    // MARK: - Singleton
    static let shared = TemplateDetectionService()
    
    // MARK: - Properties
    
    /// 現在の提案
    var currentSuggestion: TemplateSuggestion = .empty
    
    /// 判別中フラグ
    var isDetecting: Bool = false
    
    private var debounceTask: Task<Void, Never>?
    private var lastProcessedText: String = ""
    
    // MARK: - キーワード定義
    
    // タスク系キーワード（スコア: 高）
    private let taskKeywordsHigh: Set<String> = [
        "TODO", "todo", "タスク", "やること", "やるべき",
        "締切", "期限", "デッドライン", "〆切",
        "完了", "終わらせる", "片付ける",
        "提出", "納品", "提出日",
        "担当", "アサイン", "割り当て",
        "進捗", "ステータス",
    ]
    
    // タスク系キーワード（スコア: 中）
    private let taskKeywordsMedium: Set<String> = [
        "やる", "する", "しなきゃ", "しないと", "しなければ",
        "必要", "要確認", "対応", "対応する",
        "連絡", "電話", "メール", "返信",
        "送る", "作る", "準備", "用意",
        "確認", "チェック", "レビュー",
        "買う", "購入", "注文",
        "予約", "申込", "申請",
        "修正", "直す", "更新",
    ]
    
    // 行動動詞（タスクの指標）
    private let actionVerbs: Set<String> = [
        "する", "やる", "行く", "送る", "作る", "書く", "読む",
        "調べる", "確認する", "連絡する", "電話する", "メールする",
        "買う", "購入する", "注文する", "予約する",
        "完了する", "終わらせる", "片付ける", "準備する",
        "提出する", "納品する", "発送する",
        "修正する", "直す", "更新する", "変更する",
        "報告する", "相談する", "依頼する",
    ]
    
    // ノート系キーワード（スコア: 高）
    private let noteKeywordsHigh: Set<String> = [
        "メモ", "ノート", "記録", "日記",
        "アイデア", "思いつき", "ひらめき", "発想",
        "考察", "分析", "まとめ", "サマリー",
        "感想", "レビュー", "振り返り",
        "概念", "コンセプト", "構想",
    ]
    
    // ノート系キーワード（スコア: 中）
    private let noteKeywordsMedium: Set<String> = [
        "思った", "考えた", "感じた", "気づいた",
        "かもしれない", "だと思う", "ではないか",
        "について", "に関して", "の件",
        "調査", "リサーチ", "研究",
        "メモっておく", "書き留め",
        "参考", "引用", "出典",
        "学んだ", "学び", "気づき",
        "整理", "整頓", "分類",
    ]
    
    // 日時表現（タスクの指標）
    private let dateTimeExpressions: [String] = [
        "今日", "明日", "明後日", "来週", "今週",
        "月曜", "火曜", "水曜", "木曜", "金曜", "土曜", "日曜",
        "午前", "午後", "朝", "昼", "夕方", "夜",
        "〜まで", "までに", "時まで", "日まで",
        "◯日", "◯時", "◯分",
    ]
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Public Methods
    
    /// テキストからテンプレートタイプを判別
    func detectTemplate(for text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空のテキストはリセット
        guard !trimmedText.isEmpty else {
            currentSuggestion = .empty
            lastProcessedText = ""
            return
        }
        
        // 設定チェック
        guard AppSettings.shared.templateSuggestionMode != .off else {
            currentSuggestion = .empty
            return
        }
        
        // 短すぎるテキストは判別しない
        guard trimmedText.count >= 5 else {
            currentSuggestion = .empty
            return
        }
        
        // デバウンス処理
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            guard !Task.isCancelled else { return }
            
            isDetecting = true
            let suggestion = await performDetection(for: trimmedText)
            isDetecting = false
            
            currentSuggestion = suggestion
            lastProcessedText = trimmedText
            
            print("🎯 [Template] 判別結果: \(suggestion.type.displayName) (信頼度: \(Int(suggestion.confidence * 100))%)")
        }
    }
    
    /// 提案をクリア
    func clearSuggestion() {
        currentSuggestion = .empty
        lastProcessedText = ""
        debounceTask?.cancel()
    }
    
    /// 提案を採用
    func acceptSuggestion() -> Destination? {
        guard currentSuggestion.isConfident else { return nil }
        return currentSuggestion.suggestedDestination
    }
    
    // MARK: - Private Methods
    
    private func performDetection(for text: String) async -> TemplateSuggestion {
        var taskScore: Float = 0
        var noteScore: Float = 0
        
        // 1. キーワードスコアリング（高優先度）
        for keyword in taskKeywordsHigh {
            if text.localizedCaseInsensitiveContains(keyword) {
                taskScore += 2.5
            }
        }
        
        for keyword in noteKeywordsHigh {
            if text.localizedCaseInsensitiveContains(keyword) {
                noteScore += 2.5
            }
        }
        
        // 2. キーワードスコアリング（中優先度）
        for keyword in taskKeywordsMedium {
            if text.localizedCaseInsensitiveContains(keyword) {
                taskScore += 1.5
            }
        }
        
        for keyword in noteKeywordsMedium {
            if text.localizedCaseInsensitiveContains(keyword) {
                noteScore += 1.5
            }
        }
        
        // 3. 行動動詞チェック
        for verb in actionVerbs {
            if text.localizedCaseInsensitiveContains(verb) {
                taskScore += 1.0
            }
        }
        
        // 4. 日時表現チェック（タスクの強い指標）
        for dateExpr in dateTimeExpressions {
            if text.localizedCaseInsensitiveContains(dateExpr) {
                taskScore += 1.5
            }
        }
        
        // 5. 文の構造分析（NaturalLanguage）
        let structureScores = analyzeStructure(text)
        taskScore += structureScores.taskScore
        noteScore += structureScores.noteScore
        
        // 6. 疑問文チェック（ノート寄り）
        if text.contains("?") || text.contains("？") ||
           text.hasSuffix("か") || text.hasSuffix("だろう") ||
           text.hasSuffix("かな") || text.hasSuffix("かも") {
            noteScore += 1.0
        }
        
        // 7. 感嘆文チェック（ノート寄り）
        if text.contains("!") || text.contains("！") ||
           text.hasSuffix("だ！") || text.hasSuffix("ね！") {
            noteScore += 0.5
        }
        
        // 8. 長さによる調整
        let length = text.count
        if length > 100 {
            noteScore += 0.5 // 長文はノート寄り
        }
        if length < 30 {
            taskScore += 0.3 // 短文はタスク寄り
        }
        
        // 9. 信頼度計算
        let totalScore = taskScore + noteScore
        guard totalScore > 0 else {
            return .empty
        }
        
        let taskConfidence = taskScore / totalScore
        let noteConfidence = noteScore / totalScore
        
        // 10. 結果決定
        let minimumScore: Float = 2.0 // 最低スコアしきい値
        
        if taskScore >= noteScore && taskScore >= minimumScore {
            let confidence = min(taskConfidence * (taskScore / 5.0), 1.0)
            return TemplateSuggestion(
                type: .task,
                confidence: confidence,
                suggestedDestination: .todoist
            )
        } else if noteScore > taskScore && noteScore >= minimumScore {
            let confidence = min(noteConfidence * (noteScore / 5.0), 1.0)
            return TemplateSuggestion(
                type: .note,
                confidence: confidence,
                suggestedDestination: .notionInbox
            )
        } else {
            return .empty
        }
    }
    
    /// 文構造分析（NaturalLanguage）
    private func analyzeStructure(_ text: String) -> (taskScore: Float, noteScore: Float) {
        var taskScore: Float = 0
        var noteScore: Float = 0
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var verbCount = 0
        var nounCount = 0
        var adjectiveCount = 0
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, _ in
            if let tag = tag {
                switch tag {
                case .verb:
                    verbCount += 1
                case .noun:
                    nounCount += 1
                case .adjective:
                    adjectiveCount += 1
                default:
                    break
                }
            }
            return true
        }
        
        // 動詞が多い → タスク寄り
        if verbCount >= 2 {
            taskScore += Float(verbCount) * 0.3
        }
        
        // 形容詞が多い → ノート寄り
        if adjectiveCount >= 2 {
            noteScore += Float(adjectiveCount) * 0.3
        }
        
        // 名詞のみで構成 → ノート寄り
        if nounCount > 0 && verbCount == 0 {
            noteScore += 0.5
        }
        
        return (taskScore, noteScore)
    }
}


//
//  TagSuggestionService.swift
//  MemoFlow
//
//  AI タグ提案サービス
//  Apple Intelligence（ローカルNLP）優先、オフライン対応
//

import Foundation
import NaturalLanguage

/// タグ提案サービス（Apple Intelligence強化版）
@Observable
@MainActor
final class TagSuggestionService {
    // MARK: - Singleton
    static let shared = TagSuggestionService()
    
    // MARK: - Properties
    var suggestedTags: [Tag] = []
    
    /// ローカルAI処理中フラグ
    var isProcessingLocally: Bool = false
    
    /// 最後の処理がローカルAIだったか
    var wasProcessedLocally: Bool = false
    
    private let settings = AppSettings.shared
    private var debounceTask: Task<Void, Never>?
    private var lastProcessedText: String = ""
    
    // MARK: - NLP Components
    private let sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
    private let lexicalTagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    private let languageRecognizer = NLLanguageRecognizer()
    
    // iOS 18+ で利用可能な高度なNLP
    private var embeddingModel: NLEmbedding?
    
    // MARK: - Keyword Categories
    
    /// タスク系キーワード（行動を伴う）
    private let taskKeywords: [String: Float] = [
        // 高スコア
        "TODO": 3.0, "todo": 3.0, "タスク": 3.0, "やること": 3.0,
        "締切": 2.5, "期限": 2.5, "〆切": 2.5, "デッドライン": 2.5,
        "完了": 2.0, "終わらせる": 2.0, "片付ける": 2.0,
        // 中スコア
        "やる": 1.5, "する": 1.0, "しなきゃ": 2.0, "しないと": 2.0,
        "対応": 1.5, "確認": 1.5, "チェック": 1.5,
        "連絡": 1.5, "電話": 1.5, "メール": 1.5, "返信": 1.5,
        "送る": 1.5, "作る": 1.5, "準備": 1.5, "用意": 1.5,
        "買う": 1.5, "購入": 1.5, "注文": 1.5,
        "予約": 1.5, "申込": 1.5, "申請": 1.5,
        "修正": 1.5, "直す": 1.5, "更新": 1.5,
    ]
    
    /// アイデア系キーワード
    private let ideaKeywords: [String: Float] = [
        "アイデア": 3.0, "思いつき": 2.5, "ひらめき": 2.5, "発想": 2.5,
        "思いついた": 2.5, "ひらめいた": 2.5,
        "かもしれない": 1.5, "だと思う": 1.5, "ではないか": 1.5,
        "案": 2.0, "企画": 2.0, "提案": 2.0, "構想": 2.0,
        "もし": 1.0, "だったら": 1.0,
    ]
    
    /// 調査・学習系キーワード
    private let researchKeywords: [String: Float] = [
        "調べる": 2.5, "検索": 2.0, "調査": 2.5, "リサーチ": 2.5,
        "探す": 2.0, "検討": 2.0, "比較": 2.0,
        "学ぶ": 2.0, "勉強": 2.0, "学習": 2.5, "習得": 2.0,
        "理解": 1.5, "読む": 1.5, "本": 1.5, "記事": 1.5,
    ]
    
    /// 買い物系キーワード
    private let shoppingKeywords: [String: Float] = [
        "買う": 2.5, "購入": 2.5, "注文": 2.5,
        "買い物": 3.0, "ショッピング": 2.5,
        "Amazon": 2.0, "楽天": 2.0, "通販": 2.0,
        "欲しい": 2.0, "必要": 1.5, "補充": 2.0, "在庫": 2.0,
    ]
    
    /// ミーティング系キーワード
    private let meetingKeywords: [String: Float] = [
        "会議": 3.0, "ミーティング": 3.0, "MTG": 3.0,
        "打ち合わせ": 2.5, "面談": 2.5, "商談": 2.5,
        "Zoom": 2.0, "Teams": 2.0, "資料": 1.5,
    ]
    
    /// 優先度系キーワード
    private let priorityKeywords: [String: Float] = [
        "重要": 3.0, "緊急": 3.0, "大事": 2.5, "優先": 2.5,
        "ASAP": 3.0, "至急": 3.0, "急ぎ": 2.5,
        "必須": 2.5, "絶対": 2.0,
    ]
    
    /// 後回し系キーワード
    private let laterKeywords: [String: Float] = [
        "あとで": 2.5, "後で": 2.5, "いつか": 2.0, "そのうち": 2.0,
        "余裕": 1.5, "時間ある時": 2.0, "暇な時": 2.0,
    ]
    
    /// 日時パターン（タスク指標）
    private let dateTimePatterns: [String] = [
        "今日", "明日", "明後日", "来週", "今週",
        "月曜", "火曜", "水曜", "木曜", "金曜", "土曜", "日曜",
        "午前", "午後", "朝", "昼", "夕方", "夜",
        "時まで", "日まで", "までに",
    ]
    
    // MARK: - Init
    private init() {
        setupNLPComponents()
    }
    
    private func setupNLPComponents() {
        // 日本語埋め込みモデルをロード（利用可能な場合）
        if let embedding = NLEmbedding.wordEmbedding(for: .japanese) {
            embeddingModel = embedding
            print("🧠 [AI] 日本語埋め込みモデルをロード")
        } else {
            print("⚠️ [AI] 埋め込みモデルは利用不可")
        }
    }
    
    // MARK: - Public Methods
    
    /// テキストからタグを提案
    func suggestTags(for text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空のテキストは即座にクリア
        guard !trimmedText.isEmpty else {
            suggestedTags = []
            lastProcessedText = ""
            wasProcessedLocally = false
            return
        }
        
        // デバウンス処理
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
            
            guard !Task.isCancelled else { return }
            
            isProcessingLocally = true
            await performLocalAISuggestion(for: trimmedText)
            isProcessingLocally = false
            
            lastProcessedText = trimmedText
        }
    }
    
    /// 現在のテキストで再提案（強制）
    func refreshSuggestions() {
        if !lastProcessedText.isEmpty {
            Task {
                isProcessingLocally = true
                await performLocalAISuggestion(for: lastProcessedText)
                isProcessingLocally = false
            }
        }
    }
    
    /// 提案をクリア
    func clearSuggestions() {
        suggestedTags = []
        lastProcessedText = ""
        debounceTask?.cancel()
        wasProcessedLocally = false
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
    
    // MARK: - Local AI Processing
    
    private func performLocalAISuggestion(for text: String) async {
        guard settings.tagAutoMode != .off else {
            suggestedTags = []
            return
        }
        
        // ローカルAI優先設定をチェック
        let useLocalAI = settings.localAIEnabled
        
        var tagScores: [String: Float] = [:]
        
        // 1. キーワードベースのスコアリング（常に実行）
        addKeywordScores(for: text, to: &tagScores)
        
        // 2. 日時パターンマッチング（タスク指標）
        addDateTimeScores(for: text, to: &tagScores)
        
        // 3. Apple Intelligence NLP処理（ローカル優先時）
        if useLocalAI {
            // 3a. 品詞解析と固有表現抽出
            await addLexicalAnalysisScores(for: text, to: &tagScores)
            
            // 3b. 感情分析
            addSentimentScores(for: text, to: &tagScores)
            
            // 3c. 単語埋め込みによる類似性分析
            if embeddingModel != nil {
                await addEmbeddingScores(for: text, to: &tagScores)
            }
            
            // 3d. 文構造分析
            addStructureScores(for: text, to: &tagScores)
            
            wasProcessedLocally = true
            print("🧠 [AI] ローカルAI処理完了")
        } else {
            wasProcessedLocally = false
            print("🌐 [AI] キーワードベース処理")
        }
        
        // 4. 疑問文・感嘆文の検出
        addPunctuationScores(for: text, to: &tagScores)
        
        // 5. テキスト長による調整
        addLengthAdjustments(for: text, to: &tagScores)
        
        // 6. 結果を生成
        suggestedTags = generateTags(from: tagScores)
        
        print("🏷️ [AI] 提案タグ: \(suggestedTags.map { "\($0.name)(\(tagScores[$0.name] ?? 0))" })")
    }
    
    // MARK: - Scoring Methods
    
    private func addKeywordScores(for text: String, to scores: inout [String: Float]) {
        // タスク系
        for (keyword, score) in taskKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["タスク", default: 0] += score
            }
        }
        
        // アイデア系
        for (keyword, score) in ideaKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["アイデア", default: 0] += score
            }
        }
        
        // 調査・学習系
        for (keyword, score) in researchKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["調査", default: 0] += score
                scores["学習", default: 0] += score * 0.5
            }
        }
        
        // 買い物系
        for (keyword, score) in shoppingKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["買い物", default: 0] += score
            }
        }
        
        // ミーティング系
        for (keyword, score) in meetingKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["ミーティング", default: 0] += score
            }
        }
        
        // 優先度系
        for (keyword, score) in priorityKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["重要", default: 0] += score
            }
        }
        
        // 後回し系
        for (keyword, score) in laterKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                scores["あとで", default: 0] += score
            }
        }
    }
    
    private func addDateTimeScores(for text: String, to scores: inout [String: Float]) {
        for pattern in dateTimePatterns {
            if text.contains(pattern) {
                scores["タスク", default: 0] += 1.5
            }
        }
    }
    
    private func addLexicalAnalysisScores(for text: String, to scores: inout [String: Float]) async {
        lexicalTagger.string = text
        
        var verbCount = 0
        var nounCount = 0
        var adjectiveCount = 0
        var personNames: [String] = []
        var organizationNames: [String] = []
        var placeNames: [String] = []
        
        // 品詞解析
        lexicalTagger.enumerateTags(
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
        
        // 固有表現抽出
        lexicalTagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, range in
            if let tag = tag {
                let word = String(text[range])
                switch tag {
                case .personalName:
                    personNames.append(word)
                case .organizationName:
                    organizationNames.append(word)
                case .placeName:
                    placeNames.append(word)
                default:
                    break
                }
            }
            return true
        }
        
        // 動詞が多い → タスク
        if verbCount >= 2 {
            scores["タスク", default: 0] += Float(verbCount) * 0.5
        }
        
        // 形容詞が多い → アイデア/メモ
        if adjectiveCount >= 2 {
            scores["アイデア", default: 0] += Float(adjectiveCount) * 0.3
            scores["メモ", default: 0] += Float(adjectiveCount) * 0.2
        }
        
        // 人名が含まれる → ミーティング/タスク
        if !personNames.isEmpty {
            scores["ミーティング", default: 0] += Float(personNames.count) * 0.8
            scores["タスク", default: 0] += Float(personNames.count) * 0.5
        }
        
        // 組織名が含まれる → 仕事関連
        if !organizationNames.isEmpty {
            scores["プロジェクト", default: 0] += Float(organizationNames.count) * 0.8
            scores["ミーティング", default: 0] += Float(organizationNames.count) * 0.5
        }
        
        // 地名が含まれる → 旅行/グルメ
        if !placeNames.isEmpty {
            scores["旅行", default: 0] += Float(placeNames.count) * 0.8
            scores["グルメ", default: 0] += Float(placeNames.count) * 0.5
        }
    }
    
    private func addSentimentScores(for text: String, to scores: inout [String: Float]) {
        sentimentTagger.string = text
        
        var totalSentiment: Double = 0
        var count = 0
        
        sentimentTagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .paragraph,
            scheme: .sentimentScore,
            options: []
        ) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalSentiment += score
                count += 1
            }
            return true
        }
        
        if count > 0 {
            let avgSentiment = totalSentiment / Double(count)
            
            // ポジティブ → アイデア
            if avgSentiment > 0.3 {
                scores["アイデア", default: 0] += Float(avgSentiment) * 1.5
            }
            
            // ネガティブ → 重要（問題解決が必要）
            if avgSentiment < -0.3 {
                scores["重要", default: 0] += Float(abs(avgSentiment)) * 1.0
            }
        }
    }
    
    private func addEmbeddingScores(for text: String, to scores: inout [String: Float]) async {
        guard let embedding = embeddingModel else { return }
        
        // カテゴリの代表的な単語との類似度を計算
        let categoryWords: [String: [String]] = [
            "タスク": ["仕事", "締切", "完了", "対応"],
            "アイデア": ["発想", "思考", "創造", "提案"],
            "買い物": ["購入", "商品", "注文", "店"],
            "学習": ["勉強", "理解", "知識", "習得"],
            "健康": ["運動", "体調", "病院", "薬"],
            "お金": ["支払", "予算", "経費", "請求"],
        ]
        
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count >= 2 }
        
        for (category, categoryKeywords) in categoryWords {
            var maxSimilarity: Float = 0
            
            for word in words {
                guard let wordVector = embedding.vector(for: word) else { continue }
                
                for categoryWord in categoryKeywords {
                    guard let categoryVector = embedding.vector(for: categoryWord) else { continue }
                    
                    let similarity = cosineSimilarity(wordVector, categoryVector)
                    maxSimilarity = max(maxSimilarity, Float(similarity))
                }
            }
            
            if maxSimilarity > 0.5 {
                scores[category, default: 0] += maxSimilarity * 2.0
            }
        }
    }
    
    private func addStructureScores(for text: String, to scores: inout [String: Float]) {
        // 箇条書き形式 → タスク
        if text.contains("・") || text.contains("- ") || text.contains("• ") {
            scores["タスク", default: 0] += 1.5
        }
        
        // 数字リスト → タスク
        let numberPattern = #"^\s*\d+[\.\)]\s*"#
        if text.range(of: numberPattern, options: .regularExpression) != nil {
            scores["タスク", default: 0] += 1.5
        }
        
        // 引用形式 → メモ/調査
        if text.contains("「") || text.contains("」") || text.contains("\"") {
            scores["メモ", default: 0] += 1.0
            scores["調査", default: 0] += 0.5
        }
    }
    
    private func addPunctuationScores(for text: String, to scores: inout [String: Float]) {
        // 疑問文 → 調査
        if text.contains("?") || text.contains("？") ||
           text.hasSuffix("か") || text.hasSuffix("だろう") ||
           text.hasSuffix("かな") || text.hasSuffix("かも") {
            scores["調査", default: 0] += 1.5
        }
        
        // 感嘆文 → アイデア
        if text.contains("!") || text.contains("！") {
            scores["アイデア", default: 0] += 0.8
        }
    }
    
    private func addLengthAdjustments(for text: String, to scores: inout [String: Float]) {
        let length = text.count
        
        // 短い（30文字未満）→ タスク寄り
        if length < 30 {
            scores["タスク", default: 0] += 0.5
        }
        
        // 長い（100文字以上）→ メモ/アイデア寄り
        if length >= 100 {
            scores["メモ", default: 0] += 1.0
            scores["アイデア", default: 0] += 0.5
        }
        
        // 非常に短い（10文字未満）は最低スコア要求を緩和しない
        if length < 10 {
            // スコアが低いものを除去
            for (key, value) in scores where value < 2.0 {
                scores[key] = 0
            }
        }
    }
    
    // MARK: - Result Generation
    
    private func generateTags(from scores: [String: Float]) -> [Tag] {
        // 最低スコア以上のタグのみ
        let minimumScore: Float = 1.5
        
        let filteredScores = scores.filter { $0.value >= minimumScore }
        
        guard !filteredScores.isEmpty else {
            // 何も見つからなければ、テキストが長い場合のみ「メモ」
            if lastProcessedText.count >= 15 {
                return [Tag(name: "メモ", state: settings.tagAutoMode == .autoAdopt ? .adopted : .suggested)]
            }
            return []
        }
        
        // スコア順にソートして上位5つ
        let sortedTags = filteredScores
            .sorted { $0.value > $1.value }
            .prefix(5)
        
        let savedTags = settings.savedTags
        var resultTags: [Tag] = []
        
        for (tagName, _) in sortedTags {
            // 既存のタグがあれば使用頻度を考慮
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
        
        return resultTags
    }
    
    // MARK: - Helper Methods
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
}

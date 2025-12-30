//
//  HelpView.swift
//  MemoFlow
//
//  連携ガイド & トラブルシューティング画面
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // クイックスタート
                Section {
                    NavigationLink {
                        QuickStartGuideView()
                    } label: {
                        HelpRow(
                            icon: "rocket.fill",
                            iconColor: .blue,
                            title: "クイックスタート",
                            subtitle: "3分でわかるMemoFlowの使い方"
                        )
                    }
                }
                
                // 連携ガイド
                Section {
                    NavigationLink {
                        NotionGuideView()
                    } label: {
                        HelpRow(
                            icon: "doc.text.fill",
                            iconColor: .primary,
                            title: "Notion連携",
                            subtitle: "APIキーの取得とデータベース設定"
                        )
                    }
                    
                    NavigationLink {
                        TodoistGuideView()
                    } label: {
                        HelpRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .red,
                            title: "Todoist連携",
                            subtitle: "APIトークンの取得方法"
                        )
                    }
                    
                    NavigationLink {
                        SlackGuideView()
                    } label: {
                        HelpRow(
                            icon: "number.square.fill",
                            iconColor: Color(red: 0.32, green: 0.71, blue: 0.67),
                            title: "Slack連携",
                            subtitle: "Botの作成とチャンネル設定"
                        )
                    }
                    
                    NavigationLink {
                        ReflectGuideView()
                    } label: {
                        HelpRow(
                            icon: "brain.head.profile",
                            iconColor: .purple,
                            title: "Reflect連携",
                            subtitle: "APIキーとGraph IDの取得"
                        )
                    }
                } header: {
                    Text("連携ガイド")
                }
                
                // トラブルシューティング
                Section {
                    NavigationLink {
                        TroubleshootingView()
                    } label: {
                        HelpRow(
                            icon: "wrench.and.screwdriver.fill",
                            iconColor: .orange,
                            title: "トラブルシューティング",
                            subtitle: "よくあるエラーと解決法"
                        )
                    }
                    
                    NavigationLink {
                        FAQView()
                    } label: {
                        HelpRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .green,
                            title: "よくある質問",
                            subtitle: "FAQ"
                        )
                    }
                } header: {
                    Text("サポート")
                }
                
                // お問い合わせ
                Section {
                    Link(destination: URL(string: "mailto:support@memoflow.app")!) {
                        HelpRow(
                            icon: "envelope.fill",
                            iconColor: .blue,
                            title: "お問い合わせ",
                            subtitle: "support@memoflow.app"
                        )
                    }
                } footer: {
                    Text("ご不明な点がございましたらお気軽にお問い合わせください。")
                }
            }
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Help Row
struct HelpRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Start Guide
struct QuickStartGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    Text("🚀 3分クイックスタート")
                        .font(.title.bold())
                    Text("MemoFlowで思考をすばやくキャプチャする方法を学びましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
                
                // ステップ
                GuideStep(
                    number: 1,
                    title: "アプリを開く",
                    description: "起動すると、すぐにテキスト入力画面が表示されます。キーボードも自動で表示されるので、思いついたことをすぐに書き始められます。",
                    tip: "ウィジェットをホーム画面に追加すると、さらに速くキャプチャできます！"
                )
                
                GuideStep(
                    number: 2,
                    title: "メモを書く",
                    description: "思いついたことを何でも入力してください。タスク、アイデア、メモ、何でもOK。AIがタグを自動で提案してくれます。",
                    tip: "マイクボタンで音声入力も使えます。"
                )
                
                GuideStep(
                    number: 3,
                    title: "送信先を選ぶ",
                    description: "右上のドロップダウンから送信先を選択。Notion、Todoist、Slack、Reflectなど、お好みのサービスに送れます。",
                    tip: "事前に設定画面で各サービスのAPIキーを入力してください。"
                )
                
                GuideStep(
                    number: 4,
                    title: "送信！",
                    description: "下部の送信ボタンをタップ（または上にスワイプ）で送信完了。✓が表示されれば成功です！",
                    tip: "毎日メモを送信してストリークを伸ばそう！"
                )
                
                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 Pro Tips")
                        .font(.headline)
                    
                    TipItem(text: "上にスワイプで設定画面、下にスワイプで履歴を表示")
                    TipItem(text: "タグをタップして採用/削除を切り替え")
                    TipItem(text: "AIがメモの種類（タスク/ノート）を自動判別")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .padding()
        }
        .navigationTitle("クイックスタート")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notion Guide
struct NotionGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title)
                        Text("Notion連携ガイド")
                            .font(.title.bold())
                    }
                    Text("NotionとMemoFlowを連携して、メモを自動でNotionデータベースに送信しましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // ステップ1: インテグレーション作成
                GuideSection(title: "Step 1: インテグレーションを作成") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "ブラウザで notion.so/my-integrations にアクセス")
                        NumberedStep(number: 2, text: "「+ 新しいインテグレーション」をクリック")
                        NumberedStep(number: 3, text: "名前を入力（例: MemoFlow）")
                        NumberedStep(number: 4, text: "関連ワークスペースを選択")
                        NumberedStep(number: 5, text: "「送信」で作成完了")
                        
                        // スクショプレースホルダー
                        ScreenshotPlaceholder(description: "インテグレーション作成画面")
                        
                        InfoBox(
                            icon: "key.fill",
                            color: .orange,
                            text: "「Internal Integration Token」をコピーして、MemoFlowの設定画面に貼り付けてください。（secret_で始まる文字列）"
                        )
                    }
                }
                
                // ステップ2: データベース作成
                GuideSection(title: "Step 2: データベースを準備") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "Notionでメモを保存したいページを開く")
                        NumberedStep(number: 2, text: "「/database」と入力して「データベース - フルページ」を選択")
                        NumberedStep(number: 3, text: "以下のプロパティを追加:")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PropertyItem(name: "タイトル", type: "タイトル", required: true)
                            PropertyItem(name: "Content", type: "テキスト", required: false)
                            PropertyItem(name: "Tags", type: "マルチセレクト", required: false)
                            PropertyItem(name: "Created", type: "日付", required: false)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        
                        ScreenshotPlaceholder(description: "データベースのプロパティ設定")
                    }
                }
                
                // ステップ3: 連携許可
                GuideSection(title: "Step 3: インテグレーションに許可を与える") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "作成したデータベースページを開く")
                        NumberedStep(number: 2, text: "右上の「•••」メニューをクリック")
                        NumberedStep(number: 3, text: "「+ コネクトを追加」を選択")
                        NumberedStep(number: 4, text: "Step 1で作成したインテグレーションを選択")
                        
                        InfoBox(
                            icon: "exclamationmark.triangle.fill",
                            color: .yellow,
                            text: "この手順を忘れると「権限がありません」エラーが発生します！"
                        )
                        
                        ScreenshotPlaceholder(description: "コネクト追加メニュー")
                    }
                }
                
                // ステップ4: データベースID取得
                GuideSection(title: "Step 4: データベースIDを取得") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "データベースページをブラウザで開く")
                        NumberedStep(number: 2, text: "URLをコピー")
                        
                        Text("URLの形式:")
                            .font(.subheadline.bold())
                        
                        Text("notion.so/workspace/**xxxxxxxx**?v=...")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(4)
                        
                        InfoBox(
                            icon: "doc.on.clipboard",
                            color: .blue,
                            text: "太字部分（32文字の英数字）がデータベースIDです。MemoFlowの設定画面に貼り付けてください。"
                        )
                    }
                }
                
                // 完了
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("設定完了！")
                        .font(.headline)
                    
                    Text("MemoFlowの設定画面で「接続テスト」を実行して、正常に連携できているか確認してください。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }
            .padding()
        }
        .navigationTitle("Notion連携")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Todoist Guide
struct TodoistGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        Text("Todoist連携ガイド")
                            .font(.title.bold())
                    }
                    Text("TodoistとMemoFlowを連携して、タスクをすばやく追加しましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // ステップ1
                GuideSection(title: "Step 1: APIトークンを取得") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "Todoistにログイン")
                        NumberedStep(number: 2, text: "右上のプロフィールアイコン → 「設定」")
                        NumberedStep(number: 3, text: "「連携機能」タブを選択")
                        NumberedStep(number: 4, text: "「開発者」セクションの「APIトークン」をコピー")
                        
                        ScreenshotPlaceholder(description: "Todoist設定画面")
                        
                        InfoBox(
                            icon: "key.fill",
                            color: .red,
                            text: "APIトークンは40文字程度の英数字です。これをMemoFlowの設定画面に貼り付けてください。"
                        )
                    }
                }
                
                // ステップ2
                GuideSection(title: "Step 2: プロジェクトID（オプション）") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("特定のプロジェクトにタスクを追加したい場合:")
                            .font(.subheadline)
                        
                        NumberedStep(number: 1, text: "Todoistでプロジェクトを開く")
                        NumberedStep(number: 2, text: "URLの数字部分がプロジェクトID")
                        
                        Text("例: todoist.com/app/project/**1234567890**")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(4)
                        
                        InfoBox(
                            icon: "info.circle.fill",
                            color: .blue,
                            text: "プロジェクトIDを空にすると、デフォルトの「インボックス」に追加されます。"
                        )
                    }
                }
                
                // 完了
                CompletionBanner()
            }
            .padding()
        }
        .navigationTitle("Todoist連携")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Slack Guide
struct SlackGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number.square.fill")
                            .font(.title)
                            .foregroundStyle(Color(red: 0.32, green: 0.71, blue: 0.67))
                        Text("Slack連携ガイド")
                            .font(.title.bold())
                    }
                    Text("SlackとMemoFlowを連携して、メモをチャンネルに投稿しましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // ステップ1
                GuideSection(title: "Step 1: Slack Appを作成") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "api.slack.com/apps にアクセス")
                        NumberedStep(number: 2, text: "「Create New App」→「From scratch」")
                        NumberedStep(number: 3, text: "App名（例: MemoFlow）とワークスペースを選択")
                        NumberedStep(number: 4, text: "「Create App」をクリック")
                        
                        ScreenshotPlaceholder(description: "Slack App作成画面")
                    }
                }
                
                // ステップ2
                GuideSection(title: "Step 2: Bot権限を設定") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "左メニューの「OAuth & Permissions」")
                        NumberedStep(number: 2, text: "「Bot Token Scopes」で以下を追加:")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ScopeItem(scope: "chat:write", description: "メッセージ送信")
                            ScopeItem(scope: "channels:read", description: "チャンネル情報取得")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        
                        NumberedStep(number: 3, text: "ページ上部の「Install to Workspace」")
                        NumberedStep(number: 4, text: "「Bot User OAuth Token」をコピー")
                        
                        InfoBox(
                            icon: "key.fill",
                            color: .green,
                            text: "xoxb-で始まるトークンをMemoFlowに貼り付けてください。"
                        )
                    }
                }
                
                // ステップ3
                GuideSection(title: "Step 3: チャンネルIDを取得") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "Slackで送信先チャンネルを右クリック")
                        NumberedStep(number: 2, text: "「リンクをコピー」")
                        NumberedStep(number: 3, text: "URLの最後の部分がチャンネルID")
                        
                        Text("例: slack.com/.../**C01234567**")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(4)
                        
                        InfoBox(
                            icon: "exclamationmark.triangle.fill",
                            color: .yellow,
                            text: "Botをチャンネルに招待することを忘れずに！チャンネルで /invite @MemoFlow を実行してください。"
                        )
                    }
                }
                
                CompletionBanner()
            }
            .padding()
        }
        .navigationTitle("Slack連携")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reflect Guide
struct ReflectGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title)
                            .foregroundStyle(.purple)
                        Text("Reflect連携ガイド")
                            .font(.title.bold())
                    }
                    Text("ReflectのDaily Noteにメモを自動追記しましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // ステップ1
                GuideSection(title: "Step 1: APIキーを取得") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "Reflectを開く")
                        NumberedStep(number: 2, text: "Settings → API")
                        NumberedStep(number: 3, text: "「Generate API Key」でキーを生成")
                        NumberedStep(number: 4, text: "表示されたキーをコピー")
                        
                        InfoBox(
                            icon: "key.fill",
                            color: .purple,
                            text: "APIキーは一度しか表示されません。必ずコピーして安全な場所に保存してください。"
                        )
                    }
                }
                
                // ステップ2
                GuideSection(title: "Step 2: Graph IDを取得") {
                    VStack(alignment: .leading, spacing: 12) {
                        NumberedStep(number: 1, text: "Reflectをブラウザで開く")
                        NumberedStep(number: 2, text: "URLを確認")
                        
                        Text("URL形式: reflect.app/g/**xxxxxxxx**/...")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(4)
                        
                        InfoBox(
                            icon: "doc.on.clipboard",
                            color: .purple,
                            text: "/g/の後ろの文字列がGraph IDです。"
                        )
                    }
                }
                
                CompletionBanner()
            }
            .padding()
        }
        .navigationTitle("Reflect連携")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Troubleshooting View
struct TroubleshootingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text("トラブルシューティング")
                            .font(.title.bold())
                    }
                    Text("よくあるエラーと解決方法をまとめました。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // エラー一覧
                TroubleshootItem(
                    error: "「権限がありません」/ Unauthorized",
                    causes: [
                        "APIキーが間違っている",
                        "APIキーの有効期限が切れている",
                        "（Notion）インテグレーションがデータベースに接続されていない"
                    ],
                    solutions: [
                        "APIキーを再度コピー＆ペースト",
                        "新しいAPIキーを生成",
                        "Notionでデータベースの「コネクト」を確認"
                    ]
                )
                
                TroubleshootItem(
                    error: "「データベースが見つかりません」",
                    causes: [
                        "データベースIDが間違っている",
                        "データベースが削除された",
                        "インテグレーションに許可がない"
                    ],
                    solutions: [
                        "URLから正しいIDをコピー",
                        "データベースが存在するか確認",
                        "「コネクトを追加」でインテグレーションを許可"
                    ]
                )
                
                TroubleshootItem(
                    error: "「タイトルプロパティが見つかりません」",
                    causes: [
                        "データベースにタイトル列がない"
                    ],
                    solutions: [
                        "Notionデータベースに「タイトル」タイプのプロパティがあることを確認（名前は何でもOK）"
                    ]
                )
                
                TroubleshootItem(
                    error: "「ネットワークエラー」",
                    causes: [
                        "インターネット接続がない",
                        "サービス側の障害"
                    ],
                    solutions: [
                        "Wi-Fi/モバイル通信を確認",
                        "しばらく待ってから再試行",
                        "各サービスのステータスページを確認"
                    ]
                )
                
                TroubleshootItem(
                    error: "「チャンネルにアクセスできません」（Slack）",
                    causes: [
                        "Botがチャンネルに招待されていない",
                        "チャンネルIDが間違っている"
                    ],
                    solutions: [
                        "チャンネルで /invite @BotName を実行",
                        "チャンネルリンクから正しいIDを取得"
                    ]
                )
                
                // まだ解決しない場合
                VStack(alignment: .leading, spacing: 12) {
                    Text("😕 まだ解決しない場合")
                        .font(.headline)
                    
                    Text("以下の情報を添えてお問い合わせください:")
                        .font(.subheadline)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("• 使用している送信先（Notion/Todoist等）")
                        Text("• 表示されたエラーメッセージ")
                        Text("• 試した解決方法")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Link(destination: URL(string: "mailto:support@memoflow.app")!) {
                        Label("サポートに連絡", systemImage: "envelope.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .padding()
        }
        .navigationTitle("トラブルシューティング")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ View
struct FAQView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FAQItem(
                    question: "無料で使えますか？",
                    answer: "はい、MemoFlow本体は無料でお使いいただけます。ただし、連携先サービス（Notion、Todoist等）は各サービスの利用規約・料金体系に従います。"
                )
                
                FAQItem(
                    question: "オフラインで使えますか？",
                    answer: "メモの入力は可能ですが、送信にはインターネット接続が必要です。オフライン時は下書きとして保存され、接続が回復したら送信できます。"
                )
                
                FAQItem(
                    question: "APIキーは安全ですか？",
                    answer: "はい、APIキーはデバイス内のセキュアストレージに保存され、外部に送信されることはありません。"
                )
                
                FAQItem(
                    question: "複数のNotionデータベースを使えますか？",
                    answer: "現在は1つのデータベースのみ設定可能です。今後のアップデートで複数対応予定です。"
                )
                
                FAQItem(
                    question: "タグが自動提案されません",
                    answer: "設定画面で「AIタグ提案」が「オフ」になっていないか確認してください。また、短すぎるテキストでは提案されないことがあります。"
                )
                
                FAQItem(
                    question: "ストリークがリセットされました",
                    answer: "ストリークは毎日1回以上メモを送信すると継続します。1日でも送信しないとリセットされます。リマインダー通知をオンにすると忘れにくくなります。"
                )
                
                FAQItem(
                    question: "Widgetが更新されません",
                    answer: "Widgetは定期的に更新されますが、即時反映されないことがあります。アプリを開くと更新されます。"
                )
            }
            .padding()
        }
        .navigationTitle("よくある質問")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Components

struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    let tip: String?
    
    init(number: Int, title: String, description: String, tip: String? = nil) {
        self.number = number
        self.title = title
        self.description = description
        self.tip = tip
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 番号バッジ
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let tip = tip {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(tip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
            }
        }
    }
}

struct GuideSection: View {
    let title: String
    let content: () -> AnyView
    
    init(title: String, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
            
            content()
        }
    }
}

struct NumberedStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
                .frame(width: 20, alignment: .trailing)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PropertyItem: View {
    let name: String
    let type: String
    let required: Bool
    
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text(type)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
            if required {
                Text("必須")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }
}

struct ScopeItem: View {
    let scope: String
    let description: String
    
    var body: some View {
        HStack {
            Text(scope)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ScreenshotPlaceholder: View {
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(Color(.separator))
                )
        )
    }
}

struct InfoBox: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct TipItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct CompletionBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("設定完了！")
                .font(.headline)
            
            Text("MemoFlowの設定画面で「接続テスト」を実行して、正常に連携できているか確認してください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}

struct TroubleshootItem: View {
    let error: String
    let causes: [String]
    let solutions: [String]
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // 原因
                    VStack(alignment: .leading, spacing: 6) {
                        Text("原因")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        ForEach(causes, id: \.self) { cause in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text(cause)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // 解決方法
                    VStack(alignment: .leading, spacing: 6) {
                        Text("解決方法")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                        ForEach(solutions, id: \.self) { solution in
                            HStack(alignment: .top, spacing: 6) {
                                Text("✓")
                                    .foregroundStyle(.green)
                                Text(solution)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top) {
                    Text("Q.")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text(question)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                HStack(alignment: .top, spacing: 8) {
                    Text("A.")
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text(answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Onboarding View (初回起動ガイド)
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "note.text.badge.plus",
            iconColor: .blue,
            title: "MemoFlowへようこそ",
            description: "思いついたことを即キャプチャ。\nあなたの頭の中をスッキリさせましょう。",
            tip: nil
        ),
        OnboardingPage(
            icon: "paperplane.fill",
            iconColor: .green,
            title: "どこへでも送信",
            description: "Notion、Todoist、Slack、Reflect...\nお好みのサービスにメモを送れます。",
            tip: "右上のドロップダウンで送信先を選択"
        ),
        OnboardingPage(
            icon: "tag.fill",
            iconColor: .orange,
            title: "AIがタグを提案",
            description: "入力中にAIがタグを自動提案。\nタップで採用、整理も楽々。",
            tip: "設定で自動採用モードも選べます"
        ),
        OnboardingPage(
            icon: "flame.fill",
            iconColor: .red,
            title: "ストリークで継続",
            description: "毎日メモを送って連続記録を伸ばそう！\nゲーミフィケーションで習慣化。",
            tip: "リマインダー通知で忘れ防止"
        ),
        OnboardingPage(
            icon: "gearshape.fill",
            iconColor: .gray,
            title: "連携を設定しよう",
            description: "各サービスのAPIキーを設定すると\nすべての機能が使えるようになります。",
            tip: "上にスワイプで設定画面を開く"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // ページインジケーター
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)
            
            // コンテンツ
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // ボタン
            VStack(spacing: 12) {
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } label: {
                        Text("次へ")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                    }
                    
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("スキップ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("始める")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
    
    private func completeOnboarding() {
        HapticManager.shared.success()
        AppSettings.shared.hasCompletedOnboarding = true
        onComplete()
        dismiss()
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let tip: String?
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // アイコン
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(page.iconColor)
            }
            
            // テキスト
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Tips
            if let tip = page.tip {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews
#Preview("Help") {
    HelpView()
}

#Preview("Onboarding") {
    OnboardingView(onComplete: {})
}

#Preview("Quick Start") {
    NavigationStack {
        QuickStartGuideView()
    }
}

#Preview("Notion Guide") {
    NavigationStack {
        NotionGuideView()
    }
}

#Preview("Troubleshooting") {
    NavigationStack {
        TroubleshootingView()
    }
}


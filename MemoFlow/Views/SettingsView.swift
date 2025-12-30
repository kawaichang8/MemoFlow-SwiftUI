//
//  SettingsView.swift
//  MemoFlow
//
//  設定画面 - 最小限の設定UI
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack {
            List {
                // テーマ設定
                Section {
                    // テーマ選択
                    ThemePicker(selectedTheme: $viewModel.appTheme)
                    
                    // フォントサイズ
                    Picker("文字サイズ", selection: $viewModel.appFontSize) {
                        ForEach(AppFontSize.allCases) { size in
                            Text(size.displayName)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("テーマ & フォント")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🎨 テーマ: \(viewModel.appTheme.description)")
                        Text("📝 文字サイズ: \(viewModel.appFontSize.displayName)")
                    }
                }
                
                // 一般設定
                Section {
                    // デフォルト送信先
                    Picker("デフォルト送信先", selection: $viewModel.defaultDestination) {
                        ForEach(Destination.allCases) { destination in
                            Label(destination.displayName, systemImage: destination.iconName)
                                .tag(destination)
                        }
                    }
                    
                    // タグ自動モード
                    Picker("AIタグ提案", selection: $viewModel.tagAutoMode) {
                        ForEach(TagAutoMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    }
                    
                    // テンプレート判別モード
                    Picker("AIテンプレート判別", selection: $viewModel.templateSuggestionMode) {
                        ForEach(TemplateSuggestionMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    }
                } header: {
                    Text("一般")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        // タグ提案の説明
                        switch viewModel.tagAutoMode {
                        case .autoAdopt:
                            Text("🏷️ AIが認識したタグを自動で採用。不要なら×で削除。")
                        case .suggestOnly:
                            Text("🏷️ タグを提案表示。タップで採用。")
                        case .off:
                            Text("🏷️ タグ提案を表示しません。")
                        }
                        
                        // テンプレート判別の説明
                        switch viewModel.templateSuggestionMode {
                        case .off:
                            Text("📋 テンプレート判別を使用しません。")
                        case .suggestOnly:
                            Text("📋 入力内容から「タスク」か「ノート」かを判別し、バナーで送信先を提案。")
                        case .autoSwitch:
                            Text("📋 AIが自動で送信先を切り替えます。")
                        }
                    }
                }
                
                // フィードバック設定
                Section {
                    Toggle("触覚フィードバック", isOn: $viewModel.hapticEnabled)
                    Toggle("サウンド", isOn: $viewModel.soundEnabled)
                } header: {
                    Text("フィードバック")
                }
                
                // ストリーク設定
                Section {
                    Toggle(isOn: $viewModel.streakEnabled) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("ストリーク表示")
                        }
                    }
                    
                    if viewModel.streakEnabled {
                        Toggle(isOn: $viewModel.streakReminderEnabled) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(.blue)
                                Text("リマインダー通知")
                            }
                        }
                        
                        // 現在のストリーク情報
                        HStack {
                            Text("現在のストリーク")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: StreakManager.shared.streakIcon)
                                    .foregroundStyle(.orange)
                                Text("\(StreakManager.shared.currentStreak)日")
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        HStack {
                            Text("最長記録")
                            Spacer()
                            Text("\(StreakManager.shared.longestStreak)日")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("総メモ数")
                            Spacer()
                            Text("\(StreakManager.shared.totalMemos)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    HStack {
                        Text("ストリーク")
                        Spacer()
                        if StreakManager.shared.hasSentMemoToday {
                            Label("今日完了", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                } footer: {
                    Text("毎日メモを送信して連続記録を伸ばそう！リマインダーをオンにすると、夜8時に今日のメモを送るよう通知します。")
                }
                
                // ローカルAI設定
                Section {
                    Toggle(isOn: $viewModel.localAIEnabled) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(.purple)
                            Text("ローカルAI優先")
                        }
                    }
                } header: {
                    HStack {
                        Text("Apple Intelligence")
                        Spacer()
                        if viewModel.localAIEnabled {
                            Label("デバイス上", systemImage: "lock.shield.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        if viewModel.localAIEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                Text("タグ提案はデバイス上で処理されています")
                            }
                            .font(.caption)
                            
                            Text("🧠 高精度NLP（品詞解析・感情分析・固有表現抽出）でタグを提案。オフラインでも動作します。")
                        } else {
                            Text("💡 キーワードベースの軽量処理のみ。バッテリー消費を抑えます。")
                        }
                    }
                }
                
                // Notion設定
                Section {
                    SecureInputField(
                        title: "API キー",
                        text: $viewModel.notionAPIKey,
                        placeholder: "secret_..."
                    )
                    
                    TextField("データベース ID", text: $viewModel.notionDatabaseId)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    
                    if viewModel.isNotionConfigured {
                        ConnectionTestButton(
                            isLoading: viewModel.isTestingNotion,
                            result: viewModel.notionTestResult,
                            error: viewModel.notionTestError,
                            onTest: {
                                Task {
                                    await viewModel.testNotionConnection()
                                }
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("Notion")
                        Spacer()
                        if viewModel.isNotionConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Notion インテグレーションを作成し、データベースへのアクセスを許可してください。")
                }
                
                // Todoist設定
                Section {
                    SecureInputField(
                        title: "API トークン",
                        text: $viewModel.todoistAPIKey,
                        placeholder: "APIトークンを入力"
                    )
                    
                    TextField("プロジェクト ID（オプション）", text: $viewModel.todoistProjectId)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    
                    if viewModel.isTodoistConfigured {
                        ConnectionTestButton(
                            isLoading: viewModel.isTestingTodoist,
                            result: viewModel.todoistTestResult,
                            error: viewModel.todoistTestError,
                            onTest: {
                                Task {
                                    await viewModel.testTodoistConnection()
                                }
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("Todoist")
                        Spacer()
                        if viewModel.isTodoistConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Todoist の設定 > 連携 > 開発者 から API トークンを取得してください。")
                }
                
                // Slack設定
                Section {
                    SecureInputField(
                        title: "Bot Token",
                        text: $viewModel.slackBotToken,
                        placeholder: "xoxb-..."
                    )
                    
                    TextField("チャンネル ID", text: $viewModel.slackChannelId)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    
                    if viewModel.isSlackConfigured {
                        ConnectionTestButton(
                            isLoading: viewModel.isTestingSlack,
                            result: viewModel.slackTestResult,
                            error: viewModel.slackTestError,
                            onTest: {
                                Task {
                                    await viewModel.testSlackConnection()
                                }
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("Slack")
                        Spacer()
                        if viewModel.isSlackConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Slack App を作成し、Bot Token Scopes に chat:write と channels:read を追加してください。チャンネルID は右クリック > リンクをコピー から取得できます。")
                }
                
                // Reflect設定
                Section {
                    SecureInputField(
                        title: "API キー",
                        text: $viewModel.reflectAPIKey,
                        placeholder: "APIキーを入力"
                    )
                    
                    TextField("Graph ID", text: $viewModel.reflectGraphId)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    
                    if viewModel.isReflectConfigured {
                        ConnectionTestButton(
                            isLoading: viewModel.isTestingReflect,
                            result: viewModel.reflectTestResult,
                            error: viewModel.reflectTestError,
                            onTest: {
                                Task {
                                    await viewModel.testReflectConnection()
                                }
                            }
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.purple)
                        Text("Reflect")
                        Spacer()
                        if viewModel.isReflectConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("Reflect の Settings > API から API キーを取得。Graph ID は URL (reflect.app/g/xxxxx) の xxxxx 部分です。Daily Note に追記されます。")
                }
                
                // Email to Self設定
                Section {
                    TextField("メールアドレス", text: $viewModel.emailToSelfAddress)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundStyle(.blue)
                        Text("Email to Self")
                        Spacer()
                        if viewModel.isEmailConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("メモを自分宛てにメール送信します。デバイスのメールアプリが起動します。")
                        if !EmailService.shared.canSendEmail() {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("メール送信機能が利用できません")
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // ヘルプ & サポート
                Section {
                    Button {
                        showHelp = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(.blue)
                            Text("連携ガイド & ヘルプ")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("サポート")
                } footer: {
                    Text("各サービスの連携方法やトラブルシューティングを確認できます。")
                }
                
                // リセット
                Section {
                    Button(role: .destructive) {
                        viewModel.resetAllSettings()
                    } label: {
                        Text("すべての設定をリセット")
                    }
                }
                
                // バージョン情報
                Section {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("MemoFlow - GTD Capture Hub")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
        }
    }
}

// MARK: - Secure Input Field
struct SecureInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Connection Test Button
struct ConnectionTestButton: View {
    let isLoading: Bool
    let result: Bool?
    let error: String?
    let onTest: () -> Void
    
    var body: some View {
        Button(action: onTest) {
            HStack {
                Text("接続テスト")
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let result = result {
                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result ? .green : .red)
                }
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Theme Picker
struct ThemePicker: View {
    @Binding var selectedTheme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("テーマ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOption(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTheme = theme
                            }
                            HapticManager.shared.lightTap()
                        }
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Theme Option
struct ThemeOption: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // プレビューサークル
                ZStack {
                    Circle()
                        .fill(theme.previewColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? Color.blue : Color(.systemGray4),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                        .shadow(
                            color: theme == .dark ? .clear : .black.opacity(0.1),
                            radius: 4,
                            y: 2
                        )
                    
                    Image(systemName: theme.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme == .dark ? .white : .black.opacity(0.7))
                }
                
                // ラベル
                Text(theme.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Font Size Preview
struct FontSizePreview: View {
    let fontSize: AppFontSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プレビュー")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("あいうえお ABC 123")
                .font(.system(size: fontSize.mainTextSize))
                .lineSpacing(fontSize.lineSpacing)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}


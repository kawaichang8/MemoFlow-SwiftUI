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
    
    var body: some View {
        NavigationStack {
            List {
                // 外観設定
                Section {
                    Picker("外観", selection: $viewModel.appearanceMode) {
                        Text("システムに従う").tag(0)
                        Text("ライト").tag(1)
                        Text("ダーク").tag(2)
                    }
                } header: {
                    Text("外観")
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
                } header: {
                    Text("一般")
                } footer: {
                    switch viewModel.tagAutoMode {
                    case .autoAdopt:
                        Text("💡 AIが認識したタグを自動で採用。不要なら×で削除。")
                    case .suggestOnly:
                        Text("💡 タグを提案表示。タップで採用、もう一度タップで削除。")
                    case .off:
                        Text("💡 タグ提案を表示しません。")
                    }
                }
                
                // フィードバック設定
                Section {
                    Toggle("触覚フィードバック", isOn: $viewModel.hapticEnabled)
                    Toggle("サウンド", isOn: $viewModel.soundEnabled)
                } header: {
                    Text("フィードバック")
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
                } header: {
                    HStack {
                        Text("Reflect")
                        Spacer()
                        if viewModel.isReflectConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
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

// MARK: - Preview
#Preview {
    SettingsView()
}


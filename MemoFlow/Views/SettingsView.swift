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
    @State private var showPaywall = false
    @State private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // プレミアム管理
                Section {
                    if purchaseManager.isPremium {
                        // プレミアム会員
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(purchaseManager.subscriptionStatusText)
                                        .font(.subheadline.bold())
                                    PremiumBadge()
                                }
                                if let expDate = purchaseManager.formattedExpirationDate {
                                    Text(L10n.Premium.nextRenewal(expDate))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        
                        Button {
                            purchaseManager.openSubscriptionManagement()
                        } label: {
                            HStack {
                                Text(L10n.Premium.manageSubscription)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    } else {
                        // 無料会員
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .foregroundStyle(.orange)
                                        Text(L10n.Premium.upgradeButton)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    Text(L10n.Premium.unlockDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button {
                            Task {
                                try? await purchaseManager.restorePurchases()
                            }
                        } label: {
                            Text(L10n.Premium.restore)
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    HStack {
                        Text(L10n.Common.premium)
                        Spacer()
                        if purchaseManager.isPremium {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    if !purchaseManager.isPremium {
                        Text(L10n.Premium.trialInfo)
                    }
                }
                
                // 言語設定
                Section {
                    Picker(String(localized: "language.title"), selection: $viewModel.appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName)
                                .tag(lang)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                        Text(String(localized: "language.title"))
                    }
                } footer: {
                    Text(String(localized: "language.description"))
                }
                
                // テーマ設定
                Section {
                    // テーマ選択
                    ThemePicker(selectedTheme: $viewModel.appTheme, showPaywall: $showPaywall)
                    
                    // フォントサイズ
                    Picker(L10n.Settings.fontSize, selection: $viewModel.appFontSize) {
                        ForEach(AppFontSize.allCases) { size in
                            Text(size.localizedDisplayName)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(L10n.Settings.themeAndFont)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Settings.themeLabel(viewModel.appTheme.localizedDescription))
                        Text(L10n.Settings.fontSizeLabel(viewModel.appFontSize.localizedDisplayName))
                    }
                }
                
                // 一般設定
                Section {
                    // デフォルト送信先
                    Picker(L10n.Settings.defaultDestination, selection: $viewModel.defaultDestination) {
                        ForEach(Destination.allCases) { destination in
                            Label(destination.localizedDisplayName, systemImage: destination.iconName)
                                .tag(destination)
                        }
                    }
                    
                    // タグ自動モード
                    Picker(L10n.Settings.aiTagSuggestion, selection: $viewModel.tagAutoMode) {
                        ForEach(TagAutoMode.allCases, id: \.self) { mode in
                            Text(mode.localizedDisplayName)
                                .tag(mode)
                        }
                    }
                    
                    // テンプレート判別モード
                    Picker(L10n.Settings.aiTemplateDetection, selection: $viewModel.templateSuggestionMode) {
                        ForEach(TemplateSuggestionMode.allCases, id: \.self) { mode in
                            Text(mode.localizedDisplayName)
                                .tag(mode)
                        }
                    }
                } header: {
                    Text(L10n.Settings.general)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        // タグ提案の説明
                        switch viewModel.tagAutoMode {
                        case .autoAdopt:
                            Text(L10n.Settings.TagMode.Description.autoAdopt)
                        case .suggestOnly:
                            Text(L10n.Settings.TagMode.Description.suggestOnly)
                        case .off:
                            Text(L10n.Settings.TagMode.Description.off)
                        }
                        
                        // テンプレート判別の説明
                        switch viewModel.templateSuggestionMode {
                        case .off:
                            Text(L10n.Settings.TemplateMode.Description.off)
                        case .suggestOnly:
                            Text(L10n.Settings.TemplateMode.Description.suggestOnly)
                        case .autoSwitch:
                            Text(L10n.Settings.TemplateMode.Description.autoSwitch)
                        }
                    }
                }
                
                // フィードバック設定
                Section {
                    Toggle(L10n.Settings.hapticFeedback, isOn: $viewModel.hapticEnabled)
                    Toggle(L10n.Settings.sound, isOn: $viewModel.soundEnabled)
                } header: {
                    Text(L10n.Settings.feedback)
                }
                
                // ストリーク設定
                Section {
                    Toggle(isOn: $viewModel.streakEnabled) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text(L10n.Settings.streakDisplay)
                        }
                    }
                    
                    if viewModel.streakEnabled {
                        Toggle(isOn: $viewModel.streakReminderEnabled) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(.blue)
                                Text(L10n.Settings.streakReminder)
                            }
                        }
                        
                        // 現在のストリーク情報
                        HStack {
                            Text(L10n.Streak.current)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: StreakManager.shared.streakIcon)
                                    .foregroundStyle(.orange)
                                Text(L10n.Streak.days(StreakManager.shared.currentStreak))
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        HStack {
                            Text(L10n.Streak.longest)
                            Spacer()
                            Text(L10n.Streak.days(StreakManager.shared.longestStreak))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text(L10n.Streak.total)
                            Spacer()
                            Text("\(StreakManager.shared.totalMemos)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    HStack {
                        Text(L10n.Settings.streak)
                        Spacer()
                        if StreakManager.shared.hasSentMemoToday {
                            Label(L10n.Settings.todayComplete, systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                } footer: {
                    Text(L10n.Streak.encouragement)
                }
                
                // ローカルAI設定
                Section {
                    Toggle(isOn: $viewModel.localAIEnabled) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(.purple)
                            Text(L10n.Settings.localAIPriority)
                        }
                    }
                } header: {
                    HStack {
                        Text(L10n.Settings.appleIntelligence)
                        Spacer()
                        if viewModel.localAIEnabled {
                            Label(L10n.Settings.onDevice, systemImage: "lock.shield.fill")
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
                                Text(L10n.Settings.localAIPrivacy)
                            }
                            .font(.caption)
                            
                            Text(L10n.Settings.localAIEnabledDescription)
                        } else {
                            Text(L10n.Settings.localAIDisabledDescription)
                        }
                    }
                }
                
                // Notion設定
                Section {
                    SecureInputField(
                        title: L10n.Settings.apiKey,
                        text: $viewModel.notionAPIKey,
                        placeholder: L10n.Settings.Placeholder.secret
                    )
                    
                    TextField(L10n.Settings.databaseId, text: $viewModel.notionDatabaseId)
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
                        Text(L10n.Settings.notion)
                        Spacer()
                        if viewModel.isNotionConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text(L10n.Settings.IntegrationDescription.notion)
                }
                
                // Todoist設定
                Section {
                    SecureInputField(
                        title: L10n.Settings.apiToken,
                        text: $viewModel.todoistAPIKey,
                        placeholder: L10n.Settings.Placeholder.apiToken
                    )
                    
                    TextField(L10n.Settings.projectId, text: $viewModel.todoistProjectId)
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
                        Text(L10n.Settings.todoist)
                        Spacer()
                        if viewModel.isTodoistConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text(L10n.Settings.IntegrationDescription.todoist)
                }
                
                // Slack設定
                Section {
                    SecureInputField(
                        title: L10n.Settings.botToken,
                        text: $viewModel.slackBotToken,
                        placeholder: L10n.Settings.Placeholder.xoxb
                    )
                    
                    TextField(L10n.Settings.channelId, text: $viewModel.slackChannelId)
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
                        Text(L10n.Settings.slack)
                        Spacer()
                        if viewModel.isSlackConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text(L10n.Settings.IntegrationDescription.slack)
                }
                
                // Reflect設定
                Section {
                    SecureInputField(
                        title: L10n.Settings.apiKey,
                        text: $viewModel.reflectAPIKey,
                        placeholder: L10n.Settings.Placeholder.apiKey
                    )
                    
                    TextField(L10n.Settings.graphId, text: $viewModel.reflectGraphId)
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
                        Text(L10n.Settings.reflect)
                        Spacer()
                        if viewModel.isReflectConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text(L10n.Settings.IntegrationDescription.reflect)
                }
                
                // Email to Self設定
                Section {
                    TextField(L10n.Settings.emailAddress, text: $viewModel.emailToSelfAddress)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundStyle(.blue)
                        Text(L10n.Settings.emailToSelf)
                        Spacer()
                        if viewModel.isEmailConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Settings.IntegrationDescription.email)
                        if !EmailService.shared.canSendEmail() {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(L10n.Settings.IntegrationDescription.emailNotAvailable)
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
                            Text(L10n.Settings.helpAndGuide)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // サポートメール
                    Link(destination: URL(string: "mailto:support@33dept.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.green)
                            Text(L10n.Settings.contactSupport)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(L10n.Settings.support)
                } footer: {
                    Text(L10n.Settings.helpDescription)
                }
                
                // 法的情報
                Section {
                    // プライバシーポリシー
                    Link(destination: URL(string: "https://berry-ginger-17d.notion.site/MemoFlow-Privacy-Policy-2dd2b283eb4880c68d53c040ed5ab3d6")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.blue)
                            Text(L10n.Settings.privacyPolicy)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // 利用規約
                    Link(destination: URL(string: "https://berry-ginger-17d.notion.site/MemoFlow-Terms-Conditions-2dd2b283eb4880569e30e3f652d415b6")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.orange)
                            Text(L10n.Settings.termsOfUse)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // サブスクリプション管理（プレミアムユーザーまたは有効なサブスク保持者のみ表示）
                    if purchaseManager.isPremium, let managementURL = purchaseManager.managementURL {
                        Link(destination: managementURL) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundStyle(.purple)
                                Text(L10n.Settings.cancelSubscription)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(L10n.Settings.legal)
                }
                
                // リセット
                Section {
                    Button(role: .destructive) {
                        viewModel.resetAllSettings()
                    } label: {
                        Text(L10n.Settings.resetAll)
                    }
                }
                
                // バージョン情報
                Section {
                    HStack {
                        Text(L10n.Common.version)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    VStack(spacing: 8) {
                        Text(L10n.App.description)
                        Text(L10n.Settings.copyright)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
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
                Text(L10n.Settings.connectionTest)
                
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
    @Binding var showPaywall: Bool
    @State private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Settings.theme)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // 無料テーマ
            HStack(spacing: 12) {
                ForEach(AppTheme.freeThemes) { theme in
                    ThemeOption(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        isPremiumLocked: false,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTheme = theme
                            }
                            HapticManager.shared.lightTap()
                        }
                    )
                }
            }
            
            // プレミアムテーマ
            HStack(spacing: 12) {
                ForEach(AppTheme.premiumThemes) { theme in
                    ThemeOption(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        isPremiumLocked: !purchaseManager.isPremium,
                        onTap: {
                            if purchaseManager.isPremium {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTheme = theme
                                }
                                HapticManager.shared.lightTap()
                            } else {
                                showPaywall = true
                            }
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
    let isPremiumLocked: Bool
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
                    
                    // プレミアムロック
                    if isPremiumLocked {
                        Circle()
                            .fill(.black.opacity(0.4))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                    
                    Image(systemName: theme.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme == .dark ? .white : .black.opacity(0.7))
                }
                
                // ラベル
                Text(theme.localizedDisplayName)
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
            Text(L10n.Settings.preview)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(L10n.Settings.previewText)
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
#Preview("Japanese") {
    SettingsView()
        .previewJapanese()
}

#Preview("English") {
    SettingsView()
        .previewEnglish()
}


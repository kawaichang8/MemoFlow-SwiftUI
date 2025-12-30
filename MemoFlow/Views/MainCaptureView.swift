//
//  MainCaptureView.swift
//  MemoFlow
//
//  メインキャプチャ画面 - 究極ミニマル「流してスッキリ」GTDキャプチャ
//

import SwiftUI

struct MainCaptureView: View {
    // MARK: - Properties
    @State private var viewModel = MemoViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showSuccessOverlay = false
    @State private var showFailureOverlay = false
    @State private var textFadeOut = false
    @State private var showOnboarding = !AppSettings.shared.hasCompletedOnboarding
    @FocusState private var isTextFieldFocused: Bool
    
    private let urlHandler = URLSchemeHandler.shared
    private let historyService = HistoryService.shared
    private var themeManager: ThemeManager { ThemeManager.shared }
    
    // MARK: - Computed Properties
    private var isShowingFeedback: Bool {
        showSuccessOverlay || showFailureOverlay
    }
    
    private var contentOpacity: Double {
        if textFadeOut {
            return 0.0
        }
        if case .sending = viewModel.sendingState {
            return 0.15
        }
        return isShowingFeedback ? 0.0 : 1.0
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let keyboardSafeHeight = geometry.size.height
            
            ZStack {
                // 背景（テーマ対応）
                themeManager.backgroundColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        isTextFieldFocused = true
                    }
                
                // メインコンテンツ
                VStack(spacing: 0) {
                    // 上部バー: マイク + 送信先
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .opacity(viewModel.isListening ? 0.3 : contentOpacity)
                    
                    // テンプレート提案バナー
                    if viewModel.hasTemplateSuggestion && !viewModel.isTemplateSuggestionDismissed && !viewModel.isListening {
                        TemplateSuggestionBanner(
                            suggestion: viewModel.templateSuggestion,
                            onAccept: {
                                viewModel.acceptTemplateSuggestion()
                            },
                            onDismiss: {
                                viewModel.dismissTemplateSuggestion()
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .opacity(contentOpacity)
                    }
                    
                    // メインテキストエディタ
                    MemoEditorView(
                        text: Binding(
                            get: { viewModel.memo.content },
                            set: { viewModel.onTextChange($0) }
                        ),
                        isFocused: $isTextFieldFocused,
                        placeholder: "なんでも"
                    )
                    .frame(minHeight: keyboardSafeHeight * 0.65)
                    .padding(.horizontal, 8)
                    .opacity(contentOpacity)
                    .blur(radius: viewModel.isListening ? 3 : 0)
                    
                    // タグチップエリア
                    if !viewModel.isListening {
                        TagChipsView(
                            adoptedTags: viewModel.adoptedTags,
                            suggestedTags: viewModel.suggestedTags,
                            onToggle: { tag in
                                viewModel.toggleTag(tag)
                            },
                            onRemove: { viewModel.removeTag($0) },
                            showPrivacyNote: viewModel.isLocalAIEnabled && viewModel.wasProcessedByLocalAI
                        )
                        .padding(.horizontal, 8)
                        .opacity(contentOpacity)
                    }
                    
                    Spacer(minLength: 4)
                    
                    // 送信ボタン
                    if !isShowingFeedback && !viewModel.isListening {
                        SendButtonView(
                            state: viewModel.sendingState,
                            isEnabled: viewModel.canSend,
                            onSend: {
                                Task {
                                    // テキストフェードアウト開始
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        textFadeOut = true
                                    }
                                    await viewModel.send()
                                }
                            }
                        )
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 28)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                    }
                }
                
                // フルスクリーン波形オーバーレイ（音声入力中）
                if viewModel.isListening {
                    FullscreenWaveformOverlay(
                        audioLevel: viewModel.audioLevel,
                        transcribedText: viewModel.memo.content,
                        onStop: {
                            viewModel.stopVoiceInput()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // 成功オーバーレイ
                if showSuccessOverlay {
                    SuccessFeedbackView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // 失敗オーバーレイ
                if showFailureOverlay {
                    FailureFeedbackView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentOpacity)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isListening)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showSuccessOverlay)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showFailureOverlay)
            .animation(.easeOut(duration: 0.3), value: textFadeOut)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasTemplateSuggestion)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.isTemplateSuggestionDismissed)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            forceShowKeyboard()
            Task {
                _ = await viewModel.requestSpeechAuthorization()
            }
            urlHandler.checkSharedContent()
            applyPendingContent()
        }
        .onChange(of: viewModel.sendingState) { _, newState in
            handleSendingStateChange(newState)
        }
        .onChange(of: urlHandler.pendingText) { _, _ in
            applyPendingContent()
        }
        .handleURLScheme()
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
                // オンボーディング後にキーボードを表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView { memo in
                // 履歴から再利用
                viewModel.onTextChange(memo.content)
                viewModel.selectedDestination = memo.destination
                for tag in memo.tags {
                    viewModel.adoptTag(tag)
                }
                forceShowKeyboard()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 80)
                .onEnded { value in
                    // 上スワイプ → 設定
                    if value.translation.height < -80 && !isShowingFeedback && !viewModel.isListening {
                        HapticManager.shared.lightTap()
                        showSettings = true
                    }
                    // 下スワイプ → 履歴
                    if value.translation.height > 80 && !isShowingFeedback && !viewModel.isListening {
                        HapticManager.shared.lightTap()
                        showHistory = true
                    }
                }
        )
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            VoiceInputButton(
                isListening: viewModel.isListening,
                audioLevel: viewModel.audioLevel,
                onTap: {
                    Task {
                        await viewModel.toggleVoiceInput()
                    }
                }
            )
            
            Spacer()
            
            // ストリークバッジ
            if AppSettings.shared.streakEnabled {
                StreakBadgeView()
            }
            
            DestinationPickerView(
                selectedDestination: Binding(
                    get: { viewModel.selectedDestination },
                    set: { viewModel.selectedDestination = $0 }
                )
            )
        }
        .frame(height: 44)
    }
    
    // MARK: - Private Methods
    
    private func forceShowKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !isTextFieldFocused {
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleSendingStateChange(_ state: SendingState) {
        switch state {
        case .success:
            isTextFieldFocused = false
            
            // 成功フィードバック
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showSuccessOverlay = true
            }
            HapticManager.shared.success()
            
            // リセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showSuccessOverlay = false
                    textFadeOut = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    forceShowKeyboard()
                }
            }
            
        case .failure:
            textFadeOut = false
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                showFailureOverlay = true
            }
            HapticManager.shared.error()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFailureOverlay = false
                }
                viewModel.clearError()
            }
            
        default:
            break
        }
    }
    
    private func applyPendingContent() {
        if let pendingText = urlHandler.pendingText {
            viewModel.onTextChange(pendingText)
            urlHandler.clearPending()
        }
        
        if let pendingDestination = urlHandler.pendingDestination {
            viewModel.selectedDestination = pendingDestination
        }
    }
}

// MARK: - Fullscreen Waveform Overlay
struct FullscreenWaveformOverlay: View {
    let audioLevel: Float
    let transcribedText: String
    let onStop: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 背景
            Color.appBackground
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // リアルタイムテキスト
                if !transcribedText.isEmpty {
                    Text(transcribedText)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(5)
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Text("話してください...")
                        .font(.system(size: 20, weight: .light, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // フルスクリーン波形
                WaveformView(audioLevel: audioLevel)
                    .frame(height: 100)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // 停止ボタン
                Button(action: onStop) {
                    ZStack {
                        // パルスリング
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 3)
                            .frame(width: 90, height: 90)
                            .scaleEffect(pulseScale)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 72, height: 72)
                            .shadow(color: .red.opacity(0.4), radius: 12, y: 6)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    }
                }
                .buttonStyle(SendButtonStyle())
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

// MARK: - Voice Input Button
struct VoiceInputButton: View {
    let isListening: Bool
    let audioLevel: Float
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false
    
    private var buttonSize: CGFloat { 40 }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isListening {
                    Circle()
                        .stroke(Color.red.opacity(0.5), lineWidth: 2.5)
                        .frame(width: buttonSize + 10, height: buttonSize + 10)
                        .scaleEffect(1 + CGFloat(audioLevel) * 0.5)
                    
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                }
                
                if !isListening {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: buttonSize, height: buttonSize)
                }
                
                Image(systemName: isListening ? "waveform" : "mic.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isListening ? .red : .primary)
                    .symbolEffect(.variableColor, isActive: isListening)
            }
            .frame(width: buttonSize + 12, height: buttonSize + 12)
            .animation(.easeOut(duration: 0.06), value: audioLevel)
        }
        .buttonStyle(.plain)
        .onChange(of: isListening) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - Success Feedback View
struct SuccessFeedbackView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var iconScale: CGFloat = 0.0
    @State private var ringScale: CGFloat = 0.0
    @State private var ringOpacity: Double = 1.0
    @State private var checkmarkTrim: CGFloat = 0.0
    
    private var successColor: Color { .success }
    
    var body: some View {
        ZStack {
            // 外側のリング
            Circle()
                .stroke(successColor.opacity(0.5), lineWidth: 4)
                .frame(width: 140, height: 140)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            
            // 背景の円
            Circle()
                .fill(successColor.opacity(colorScheme == .dark ? 0.25 : 0.15))
                .frame(width: 110, height: 110)
                .scaleEffect(iconScale)
            
            // アニメーションチェックマーク
            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(successColor)
                .scaleEffect(iconScale)
        }
        .onAppear {
            // バウンスアニメーション
            withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 1.8
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.08)) {
                ringOpacity = 0.0
            }
        }
    }
}

// MARK: - Failure Feedback View
struct FailureFeedbackView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var iconScale: CGFloat = 0.0
    @State private var shakeOffset: CGFloat = 0
    
    private var errorColor: Color { .error }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(errorColor.opacity(colorScheme == .dark ? 0.25 : 0.15))
                .frame(width: 110, height: 110)
                .scaleEffect(iconScale)
            
            Image(systemName: "xmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(errorColor)
                .scaleEffect(iconScale)
                .offset(x: shakeOffset)
        }
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                iconScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.linear(duration: 0.04).repeatCount(7, autoreverses: true)) {
                    shakeOffset = 14
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    shakeOffset = 0
                }
            }
        }
    }
}

// MARK: - Template Suggestion Banner
struct TemplateSuggestionBanner: View {
    let suggestion: TemplateSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: suggestion.type.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(suggestion.type.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(suggestion.type.color.opacity(0.15))
                )
            
            // メッセージ
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.type.suggestionMessage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("\(suggestion.suggestedDestination.displayName) に送信")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 採用ボタン
            Button(action: onAccept) {
                Text("採用")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(suggestion.type.color)
                    )
            }
            .buttonStyle(.plain)
            
            // 閉じるボタン
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(suggestion.type.color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Preview
#Preview {
    MainCaptureView()
}

#Preview("Dark Mode") {
    MainCaptureView()
        .preferredColorScheme(.dark)
}

#Preview("Success") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        SuccessFeedbackView()
    }
}

// MARK: - Streak Badge View
struct StreakBadgeView: View {
    @State private var streakManager = StreakManager.shared
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: streakManager.streakIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(streakColor)
                
                Text(streakManager.streakDisplayText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(streakColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(streakColor.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(streakColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(streakManager.hasSentMemoToday ? 1.0 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: streakManager.currentStreak)
        .sheet(isPresented: $showDetail) {
            StreakDetailSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var streakColor: Color {
        switch streakManager.streakColorName {
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Streak Detail Sheet
struct StreakDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var streakManager = StreakManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // メインストリーク表示
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(streakColor.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 4) {
                            Image(systemName: streakManager.streakIcon)
                                .font(.system(size: 36))
                                .foregroundStyle(streakColor)
                            
                            Text("\(streakManager.currentStreak)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(streakColor)
                        }
                    }
                    
                    Text("日連続")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text(streakManager.motivationMessage)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                }
                .padding(.top, 20)
                
                // 統計
                HStack(spacing: 32) {
                    StatItem(title: "最長記録", value: "\(streakManager.longestStreak)日", icon: "trophy.fill", color: .yellow)
                    StatItem(title: "総メモ数", value: "\(streakManager.totalMemos)", icon: "note.text", color: .blue)
                }
                .padding(.horizontal)
                
                // 今日の状態
                HStack {
                    Image(systemName: streakManager.hasSentMemoToday ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(streakManager.hasSentMemoToday ? .green : .secondary)
                    Text(streakManager.hasSentMemoToday ? "今日のメモ完了！" : "今日はまだ送信していません")
                        .font(.subheadline)
                        .foregroundStyle(streakManager.hasSentMemoToday ? .primary : .secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("ストリーク")
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
    
    private var streakColor: Color {
        switch streakManager.streakColorName {
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview("Streak Badge") {
    HStack {
        StreakBadgeView()
    }
    .padding()
}

#Preview("Streak Detail") {
    StreakDetailSheet()
}

#Preview("Waveform Overlay") {
    FullscreenWaveformOverlay(
        audioLevel: 0.6,
        transcribedText: "こんにちは、これはテストです",
        onStop: {}
    )
}

#Preview("Template Banner - Task") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            TemplateSuggestionBanner(
                suggestion: TemplateSuggestion(
                    type: .task,
                    confidence: 0.85,
                    suggestedDestination: .todoist
                ),
                onAccept: {},
                onDismiss: {}
            )
            .padding()
            
            TemplateSuggestionBanner(
                suggestion: TemplateSuggestion(
                    type: .note,
                    confidence: 0.75,
                    suggestedDestination: .notionInbox
                ),
                onAccept: {},
                onDismiss: {}
            )
            .padding()
        }
    }
}

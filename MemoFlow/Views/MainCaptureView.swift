//
//  MainCaptureView.swift
//  MemoFlow
//
//  メインキャプチャ画面 - 究極ミニマルGTDキャプチャ
//

import SwiftUI

struct MainCaptureView: View {
    // MARK: - Properties
    @State private var viewModel = MemoViewModel()
    @State private var showSettings = false
    @State private var showSuccessOverlay = false
    @State private var showFailureOverlay = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let urlHandler = URLSchemeHandler.shared
    
    // MARK: - Computed Properties
    private var isShowingFeedback: Bool {
        showSuccessOverlay || showFailureOverlay
    }
    
    private var contentOpacity: Double {
        if case .sending = viewModel.sendingState {
            return 0.2
        }
        return isShowingFeedback ? 0.0 : 1.0
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let keyboardSafeHeight = geometry.size.height
            
            ZStack {
                // 背景（純白 / 純黒）
                Color.appBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        // 背景タップでキーボード表示
                        isTextFieldFocused = true
                    }
                
                // メインコンテンツ
                VStack(spacing: 0) {
                    // 上部バー: マイク + 送信先 + 設定
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .opacity(contentOpacity)
                    
                    // メインテキストエディタ（90%占有）
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
                    
                    // 波形アニメーション（音声入力中 - フル表示）
                    if viewModel.isListening {
                        WaveformView(audioLevel: viewModel.audioLevel)
                            .frame(height: 60)
                            .padding(.horizontal, 16)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // タグチップエリア（横スクロール + フェードイン）
                    TagChipsView(
                        adoptedTags: viewModel.adoptedTags,
                        suggestedTags: viewModel.suggestedTags,
                        onToggle: { viewModel.toggleTag($0) },
                        onRemove: { viewModel.removeTag($0) }
                    )
                    .padding(.horizontal, 8)
                    .opacity(contentOpacity)
                    
                    Spacer(minLength: 4)
                    
                    // 送信ボタン（大きな紙飛行機）
                    if !isShowingFeedback {
                        SendButtonView(
                            state: viewModel.sendingState,
                            isEnabled: viewModel.canSend,
                            onSend: {
                                Task {
                                    await viewModel.send()
                                }
                            }
                        )
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 28)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // 成功オーバーレイ
                if showSuccessOverlay {
                    SuccessFeedbackView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // 失敗オーバーレイ
                if showFailureOverlay {
                    FailureFeedbackView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: contentOpacity)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.isListening)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showSuccessOverlay)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showFailureOverlay)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // 起動時に即キーボード表示（強化）
            forceShowKeyboard()
            
            // 音声認識権限を事前リクエスト
            Task {
                _ = await viewModel.requestSpeechAuthorization()
            }
            
            // Share Extensionからの共有コンテンツをチェック
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .gesture(
            // 上スワイプで設定表示
            DragGesture(minimumDistance: 80)
                .onEnded { value in
                    if value.translation.height < -80 && !isShowingFeedback {
                        HapticManager.shared.lightTap()
                        showSettings = true
                    }
                }
        )
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // マイクボタン（左）
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
            
            // 送信先ピッカー（右）
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
        // 複数回試行してキーボード表示を確実に
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
            // キーボードを隠す
            isTextFieldFocused = false
            
            // 成功フィードバック表示
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                showSuccessOverlay = true
            }
            HapticManager.shared.success()
            
            // 0.9秒後にリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showSuccessOverlay = false
                }
                
                // リセット後にキーボード再表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    forceShowKeyboard()
                }
            }
            
        case .failure:
            // 失敗フィードバック表示
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showFailureOverlay = true
            }
            HapticManager.shared.error()
            
            // 1.2秒後に非表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.25)) {
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
                // 背景リング（音声入力中）
                if isListening {
                    // 音量レベルリング
                    Circle()
                        .stroke(Color.red.opacity(0.5), lineWidth: 2.5)
                        .frame(width: buttonSize + 10, height: buttonSize + 10)
                        .scaleEffect(1 + CGFloat(audioLevel) * 0.5)
                    
                    // パルスリング
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                }
                
                // 背景円（非録音時）
                if !isListening {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: buttonSize, height: buttonSize)
                }
                
                // マイクアイコン
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
    
    private var successColor: Color { .success }
    
    var body: some View {
        ZStack {
            // 外側のリング（拡大してフェード）
            Circle()
                .stroke(successColor.opacity(0.5), lineWidth: 3)
                .frame(width: 130, height: 130)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            
            // 背景の円
            Circle()
                .fill(successColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .frame(width: 100, height: 100)
                .scaleEffect(iconScale)
            
            // チェックマークアイコン
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(successColor)
                .scaleEffect(iconScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 1.7
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
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
            // 背景の円
            Circle()
                .fill(errorColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .frame(width: 100, height: 100)
                .scaleEffect(iconScale)
            
            // ×マークアイコン
            Image(systemName: "xmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(errorColor)
                .scaleEffect(iconScale)
                .offset(x: shakeOffset)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                iconScale = 1.0
            }
            
            // シェイクアニメーション
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.linear(duration: 0.05).repeatCount(6, autoreverses: true)) {
                    shakeOffset = 12
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeOffset = 0
                }
            }
        }
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

#Preview("Failure") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        FailureFeedbackView()
    }
}

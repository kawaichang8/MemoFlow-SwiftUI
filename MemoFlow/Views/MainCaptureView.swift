//
//  MainCaptureView.swift
//  MemoFlow
//
//  メインキャプチャ画面 - 極限ミニマルGTDキャプチャ
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
            return 0.3
        }
        return isShowingFeedback ? 0.0 : 1.0
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（純白 / 純黒）
                Color.appBackground
                    .ignoresSafeArea()
                
                // メインコンテンツ
                VStack(spacing: 0) {
                    // 上部バー: マイクボタン + 送信先ピッカー（コンパクト）
                    TopBarView(
                        viewModel: viewModel,
                        showSettings: $showSettings
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .opacity(contentOpacity)
                    
                    // メインテキストエディタ（90%占有、巨大フォント）
                    MemoEditorView(
                        text: Binding(
                            get: { viewModel.memo.content },
                            set: { viewModel.onTextChange($0) }
                        ),
                        isFocused: $isTextFieldFocused,
                        placeholder: "なんでも"
                    )
                    .frame(minHeight: geometry.size.height * 0.55)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .opacity(contentOpacity)
                    
                    // 波形アニメーション（音声入力中）
                    if viewModel.isListening {
                        WaveformView(audioLevel: viewModel.audioLevel)
                            .frame(height: 50)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    
                    // タグチップエリア（横スクロール）
                    TagChipsView(
                        adoptedTags: viewModel.adoptedTags,
                        suggestedTags: viewModel.suggestedTags,
                        onToggle: { viewModel.toggleTag($0) },
                        onRemove: { viewModel.removeTag($0) }
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .opacity(contentOpacity)
                    
                    Spacer(minLength: 8)
                    
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
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 24 : 32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // 成功オーバーレイ
                if showSuccessOverlay {
                    SuccessFeedbackView()
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                // 失敗オーバーレイ
                if showFailureOverlay {
                    FailureFeedbackView()
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: contentOpacity)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: viewModel.isListening)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showSuccessOverlay)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showFailureOverlay)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // 起動時に即キーボード表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
            }
            
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
    
    // MARK: - Private Methods
    
    private func handleSendingStateChange(_ state: SendingState) {
        switch state {
        case .success:
            // キーボードを隠す
            isTextFieldFocused = false
            
            // 成功フィードバック表示
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSuccessOverlay = true
            }
            HapticManager.shared.success()
            
            // 1秒後にリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showSuccessOverlay = false
                }
                
                // リセット後にキーボード再表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isTextFieldFocused = true
                }
            }
            
        case .failure:
            // 失敗フィードバック表示
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showFailureOverlay = true
            }
            HapticManager.shared.error()
            
            // 1.5秒後に非表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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
                .stroke(successColor.opacity(0.4), lineWidth: 3)
                .frame(width: 140, height: 140)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            
            // 背景の円
            Circle()
                .fill(successColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                .frame(width: 110, height: 110)
                .scaleEffect(iconScale)
            
            // チェックマークアイコン
            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(successColor)
                .scaleEffect(iconScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.7)) {
                ringScale = 1.6
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
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
                .fill(errorColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                .frame(width: 110, height: 110)
                .scaleEffect(iconScale)
            
            // ×マークアイコン
            Image(systemName: "xmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(errorColor)
                .scaleEffect(iconScale)
                .offset(x: shakeOffset)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            
            // シェイクアニメーション
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.linear(duration: 0.06).repeatCount(5, autoreverses: true)) {
                    shakeOffset = 10
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
        Color.appBackground
        SuccessFeedbackView()
    }
}

#Preview("Failure") {
    ZStack {
        Color.appBackground
        FailureFeedbackView()
    }
}

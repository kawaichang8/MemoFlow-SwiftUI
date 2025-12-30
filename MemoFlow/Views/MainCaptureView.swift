//
//  MainCaptureView.swift
//  MemoFlow
//
//  メインキャプチャ画面 - GTDの即時キャプチャハブ
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
            return 0.5
        }
        return isShowingFeedback ? 0.0 : 1.0
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（ライト: 白、ダーク: 黒）
                Color.appBackground
                    .ignoresSafeArea()
                
                // メインコンテンツ
                VStack(spacing: 0) {
                    // 上部バー: マイクボタン + 送信先ピッカー
                    TopBarView(
                        viewModel: viewModel,
                        showSettings: $showSettings
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(contentOpacity)
                    
                    // メインテキストエディタ（画面80%占有）
                    MemoEditorView(
                        text: Binding(
                            get: { viewModel.memo.content },
                            set: { viewModel.onTextChange($0) }
                        ),
                        isFocused: $isTextFieldFocused,
                        placeholder: "何でも書いて、すぐ送る"
                    )
                    .frame(height: geometry.size.height * 0.6)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .opacity(contentOpacity)
                    
                    // 波形アニメーション（音声入力中）
                    if viewModel.isListening {
                        WaveformView(audioLevel: viewModel.audioLevel)
                            .frame(height: 60)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                    
                    // タグチップエリア
                    TagChipsView(
                        adoptedTags: viewModel.adoptedTags,
                        suggestedTags: viewModel.suggestedTags,
                        onToggle: { viewModel.toggleTag($0) },
                        onRemove: { viewModel.removeTag($0) }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .opacity(contentOpacity)
                    
                    Spacer()
                    
                    // 送信ボタン
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
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
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
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: contentOpacity)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isListening)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showSuccessOverlay)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showFailureOverlay)
        }
        .onAppear {
            // 起動時に即キーボード表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height < -50 && !isShowingFeedback {
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showSuccessOverlay = true
            }
            HapticManager.shared.success()
            
            // 1秒後にリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showSuccessOverlay = false
                }
                
                // リセット後にキーボード再表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
    
    private var successColor: Color {
        Color.success
    }
    
    var body: some View {
        ZStack {
            // 外側のリング（拡大してフェード）
            Circle()
                .stroke(successColor.opacity(colorScheme == .dark ? 0.4 : 0.3), lineWidth: 4)
                .frame(width: 120, height: 120)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            
            // 背景の円
            Circle()
                .fill(successColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(iconScale)
            
            // チェックマークアイコン
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(successColor)
                .scaleEffect(iconScale)
        }
        .onAppear {
            // アイコンのスケールアニメーション
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            
            // リングの拡大アニメーション
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 1.5
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
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
    
    private var errorColor: Color {
        Color.error
    }
    
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .fill(errorColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(iconScale)
            
            // ×マークアイコン
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(errorColor)
                .scaleEffect(iconScale)
                .offset(x: shakeOffset)
        }
        .onAppear {
            // アイコンのスケールアニメーション
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            
            // シェイクアニメーション
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.linear(duration: 0.08).repeatCount(4, autoreverses: true)) {
                    shakeOffset = 8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
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

#Preview("Success State") {
    ZStack {
        Color(.systemBackground)
        SuccessFeedbackView()
    }
}

#Preview("Failure State") {
    ZStack {
        Color(.systemBackground)
        FailureFeedbackView()
    }
}

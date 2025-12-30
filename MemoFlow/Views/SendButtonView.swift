//
//  SendButtonView.swift
//  MemoFlow
//
//  送信ボタン - 極限ミニマルの紙飛行機アイコン
//

import SwiftUI

struct SendButtonView: View {
    let state: SendingState
    let isEnabled: Bool
    let onSend: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    
    // 大きなボタンサイズ
    private let buttonSize: CGFloat = 80
    private let swipeThreshold: CGFloat = 60
    
    var body: some View {
        ZStack {
            // パルスリング（送信可能時）
            if isEnabled && !isSending {
                Circle()
                    .stroke(buttonColor.opacity(0.15), lineWidth: 2)
                    .frame(width: buttonSize + 24, height: buttonSize + 24)
                    .scaleEffect(pulseScale)
                    .opacity(Double(2.0 - pulseScale))
            }
            
            // メインボタン
            Button(action: {
                guard isEnabled && !isSending else { return }
                HapticManager.shared.mediumTap()
                onSend()
            }) {
                ZStack {
                    // 背景円
                    Circle()
                        .fill(buttonBackgroundColor)
                        .shadow(
                            color: isEnabled && !isSending ? buttonColor.opacity(0.25) : .clear,
                            radius: 16,
                            y: 8
                        )
                    
                    // 紙飛行機アイコン
                    buttonIcon
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(buttonForegroundColor)
                        .rotationEffect(.degrees(isSending ? iconRotation : -45))
                        .offset(x: isSending ? 0 : 2, y: isSending ? 0 : -2)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(SendButtonStyle())
            .disabled(!isEnabled || isSending)
            .offset(y: dragOffset)
            .gesture(swipeGesture)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: dragOffset)
        }
        .frame(height: buttonSize + 28)
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: isSending) { _, newValue in
            if newValue {
                startLoadingAnimation()
            } else {
                iconRotation = 0
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSending: Bool {
        if case .sending = state { return true }
        return false
    }
    
    private var buttonColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var buttonBackgroundColor: Color {
        if isSending {
            return Color(.systemGray5)
        }
        return isEnabled ? buttonColor : Color(.systemGray5)
    }
    
    private var buttonForegroundColor: Color {
        if isSending {
            return Color(.systemGray3)
        }
        if !isEnabled {
            return Color(.systemGray3)
        }
        return colorScheme == .dark ? .black : .white
    }
    
    @ViewBuilder
    private var buttonIcon: some View {
        if isSending {
            Image(systemName: "arrow.triangle.2.circlepath")
                .symbolEffect(.rotate, options: .repeating, value: isSending)
        } else {
            Image(systemName: "paperplane.fill")
        }
    }
    
    // MARK: - Animations
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
            pulseScale = 1.6
        }
    }
    
    private func startLoadingAnimation() {
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            iconRotation = 360
        }
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard isEnabled && !isSending else { return }
                // 上方向のみ
                if value.translation.height < 0 {
                    dragOffset = value.translation.height * 0.4
                    
                    // スワイプ途中で触覚フィードバック
                    if value.translation.height < -swipeThreshold * 0.7 {
                        HapticManager.shared.lightTap()
                    }
                }
            }
            .onEnded { value in
                guard isEnabled && !isSending else { return }
                
                if value.translation.height < -swipeThreshold {
                    // スワイプで送信
                    HapticManager.shared.mediumTap()
                    onSend()
                }
                
                dragOffset = 0
            }
    }
}

// MARK: - Send Button Style
struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 50) {
        SendButtonView(
            state: .idle,
            isEnabled: true,
            onSend: {}
        )
        
        SendButtonView(
            state: .idle,
            isEnabled: false,
            onSend: {}
        )
        
        SendButtonView(
            state: .sending,
            isEnabled: true,
            onSend: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack(spacing: 50) {
        SendButtonView(
            state: .idle,
            isEnabled: true,
            onSend: {}
        )
        
        SendButtonView(
            state: .sending,
            isEnabled: true,
            onSend: {}
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
